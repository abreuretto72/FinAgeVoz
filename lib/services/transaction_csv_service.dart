import 'dart:io';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction_model.dart';
import '../services/database_service.dart';

class TransactionCsvService {
  final DatabaseService _db = DatabaseService();

  // UTF-8 BOM (Byte Order Mark)
  static const String _utf8Bom = '\uFEFF';

  static const List<String> _headers = [
    'ID',
    'Tipo',
    'Data',
    'Valor',
    'Descricao',
    'Categoria',
    'Subcategoria',
    'Status',
    'Observacoes',
    'Anexos',
    'CriadoEm'
  ];

  /// Gera CSV com UTF-8 BOM para compatibilidade com Excel
  String generateCsv(List<Transaction> transactions) {
    List<List<dynamic>> rows = [];
    rows.add(_headers);

    for (var t in transactions) {
      rows.add([
        t.id,
        t.isExpense ? 'DESPESA' : 'RECEITA',
        DateFormat('yyyy-MM-dd').format(t.date), // ISO format
        t.amount.toString().replaceAll('.', ','), // Vírgula decimal para Excel BR
        t.description,
        t.category,
        t.subcategory ?? '',
        t.isPaid ? (t.isExpense ? 'PAGO' : 'RECEBIDA') : 'PENDENTE',
        '', // Observacoes (uso futuro)
        t.attachments?.join('|') ?? '',
        DateFormat('yyyy-MM-dd HH:mm:ss').format(t.date),
      ]);
    }

    final csvString = const ListToCsvConverter().convert(rows);
    // Adiciona BOM no início
    return _utf8Bom + csvString;
  }

  /// Importa CSV com detecção automática de BOM e parsing robusto
  Future<Map<String, dynamic>> importCsv(String csvContent) async {
    int imported = 0;
    int ignored = 0;
    List<String> errors = [];

    try {
      // Remove BOM se presente
      String cleanContent = csvContent;
      if (cleanContent.startsWith(_utf8Bom)) {
        cleanContent = cleanContent.substring(1);
      }

      List<List<dynamic>> rows = const CsvToListConverter().convert(cleanContent);
      if (rows.isEmpty) {
        return {
          'imported': 0,
          'ignored': 0,
          'errors': ['Arquivo CSV vazio']
        };
      }

      // Normaliza headers (case-insensitive, remove espaços)
      final headers = rows.first.map((e) => _normalizeHeader(e.toString())).toList();

      // Valida campos obrigatórios
      final requiredFields = ['tipo', 'data', 'valor', 'descricao', 'categoria'];
      final missingFields = requiredFields.where((field) => !headers.contains(field)).toList();

      if (missingFields.isNotEmpty) {
        return {
          'imported': 0,
          'ignored': 0,
          'errors': ['Campos obrigatórios ausentes: ${missingFields.join(", ")}']
        };
      }

      final allTransactions = _db.getTransactions();

      // Processa cada linha
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty || row.every((cell) => cell.toString().trim().isEmpty)) {
          continue; // Ignora linhas vazias
        }

        try {
          final Map<String, dynamic> map = {};
          for (int j = 0; j < row.length && j < headers.length; j++) {
            map[headers[j]] = row[j];
          }

          final result = await _processImportRow(map, allTransactions, i + 1);
          if (result['success']) {
            imported++;
          } else {
            ignored++;
            if (result['error'] != null) {
              errors.add('Linha ${i + 1}: ${result['error']}');
            }
          }
        } catch (e) {
          ignored++;
          errors.add('Linha ${i + 1}: Erro ao processar - $e');
        }
      }

      return {
        'imported': imported,
        'ignored': ignored,
        'errors': errors,
      };
    } catch (e) {
      return {
        'imported': 0,
        'ignored': 0,
        'errors': ['Erro ao processar arquivo: $e']
      };
    }
  }

  /// Normaliza header para comparação case-insensitive
  String _normalizeHeader(String header) {
    return header
        .trim()
        .toLowerCase()
        .replaceAll('ç', 'c')
        .replaceAll('ã', 'a')
        .replaceAll('õ', 'o')
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('â', 'a')
        .replaceAll('ê', 'e')
        .replaceAll('ô', 'o');
  }

  /// Processa uma linha do CSV com validação robusta
  Future<Map<String, dynamic>> _processImportRow(
    Map<String, dynamic> map,
    List<Transaction> existingTransactions,
    int lineNumber,
  ) async {
    try {
      // 1. TIPO (obrigatório)
      String tipoStr = map['tipo']?.toString().trim() ?? '';
      if (tipoStr.isEmpty) {
        return {'success': false, 'error': 'Tipo não informado'};
      }

      bool isExpense = tipoStr.toUpperCase().contains('DESPESA') ||
          tipoStr.toUpperCase().contains('EXPENSE') ||
          tipoStr.toUpperCase() == 'D';

      // 2. DATA (obrigatório) - Suporta múltiplos formatos
      String dateStr = map['data']?.toString().trim() ?? '';
      if (dateStr.isEmpty) {
        return {'success': false, 'error': 'Data não informada'};
      }

      DateTime? date = _parseFlexibleDate(dateStr);
      if (date == null) {
        return {'success': false, 'error': 'Data inválida: $dateStr'};
      }

      // 3. VALOR (obrigatório) - Aceita vírgula ou ponto
      String valorStr = map['valor']?.toString().trim() ?? '';
      if (valorStr.isEmpty) {
        return {'success': false, 'error': 'Valor não informado'};
      }

      double? amount = _parseFlexibleNumber(valorStr);
      if (amount == null || amount <= 0) {
        return {'success': false, 'error': 'Valor inválido: $valorStr'};
      }

      // 4. DESCRIÇÃO (obrigatório)
      String description = map['descricao']?.toString().trim() ?? '';
      if (description.isEmpty) {
        return {'success': false, 'error': 'Descrição não informada'};
      }

      // 5. CATEGORIA (obrigatório)
      String category = map['categoria']?.toString().trim() ?? '';
      if (category.isEmpty) {
        return {'success': false, 'error': 'Categoria não informada'};
      }

      // Verifica duplicata
      bool isDuplicate = existingTransactions.any((t) {
        if (t.isExpense != isExpense) return false;
        if ((t.amount - amount).abs() > 0.01) return false;
        if (t.date.year != date.year ||
            t.date.month != date.month ||
            t.date.day != date.day) return false;
        if (t.description.trim().toLowerCase() != description.toLowerCase()) {
          return false;
        }
        return true;
      });

      if (isDuplicate) {
        return {'success': false, 'error': 'Duplicada'};
      }

      // Campos opcionais
      String status = map['status']?.toString().toUpperCase() ?? '';
      bool isPaid = status.contains('PAGO') ||
          status.contains('RECEBIDA') ||
          status.contains('PAID') ||
          status.contains('RECEIVED');

      // Se status não especificado, usa regra de data
      if (status.isEmpty) {
        isPaid = date.isBefore(DateTime.now()) ||
            date.isAtSameMomentAs(DateTime.now());
      }

      // Cria transação
      final t = Transaction(
        id: const Uuid().v4(),
        description: description,
        amount: amount,
        date: date,
        isExpense: isExpense,
        category: category,
        subcategory: map['subcategoria']?.toString().trim(),
        isPaid: isPaid,
        attachments: _parseAttachments(map['anexos']?.toString()),
      );

      await _db.addTransaction(t);
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Parse de data flexível (suporta vários formatos)
  DateTime? _parseFlexibleDate(String dateStr) {
    // Remove espaços extras
    dateStr = dateStr.trim();

    // Tenta ISO format primeiro (YYYY-MM-DD)
    DateTime? date = DateTime.tryParse(dateStr);
    if (date != null) return date;

    // Tenta formatos brasileiros
    final formats = [
      'dd/MM/yyyy',
      'dd-MM-yyyy',
      'dd/MM/yy',
      'yyyy-MM-dd',
      'dd/MM/yyyy HH:mm:ss',
      'yyyy-MM-dd HH:mm:ss',
    ];

    for (var format in formats) {
      try {
        date = DateFormat(format).parse(dateStr);
        return date;
      } catch (e) {
        continue;
      }
    }

    return null;
  }

  /// Parse de número flexível (aceita vírgula ou ponto)
  double? _parseFlexibleNumber(String numberStr) {
    // Remove espaços
    numberStr = numberStr.trim();

    // Remove símbolos de moeda
    numberStr = numberStr.replaceAll(RegExp(r'[R$€£¥\s]'), '');

    // Se tem vírgula e ponto, assume formato BR (1.234,56)
    if (numberStr.contains(',') && numberStr.contains('.')) {
      numberStr = numberStr.replaceAll('.', '').replaceAll(',', '.');
    }
    // Se tem apenas vírgula, assume decimal BR
    else if (numberStr.contains(',')) {
      numberStr = numberStr.replaceAll(',', '.');
    }

    return double.tryParse(numberStr);
  }

  /// Parse de anexos
  List<String>? _parseAttachments(String? attachmentsStr) {
    if (attachmentsStr == null || attachmentsStr.trim().isEmpty) return null;
    return attachmentsStr
        .split('|')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  /// Salva e compartilha CSV com UTF-8 BOM
  Future<void> shareCsv(String csvContent, String filename) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$filename');

    // Escreve com encoding UTF-8 BOM
    await file.writeAsString(csvContent, encoding: utf8);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Exportação Financeira FinAgeVoz',
    );
  }
}
