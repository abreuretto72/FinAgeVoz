import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import '../models/agenda_models.dart';
import '../models/medicine_model.dart' as mm;
import '../services/agenda_repository.dart';
import 'database_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class AgendaCsvService {
  final AgendaRepository _repo = AgendaRepository();

  static const List<String> _headers = [
    'Tipo', 'ID', 'Titulo', 'Descricao', 'DataInicio', 'HorarioInicio', 
    'DataFim', 'HorarioFim', 'Status', 'Valor', 'Moeda', 'Recorrencia', 
    'Remedio_Nome', 'Remedio_Dose', 'Remedio_Freq', 'Aniversario_Pessoa', 
    'Aniversario_Parentesco', 'Aniversario_Notificar', 'Observacoes', 'CriadoEm'
  ];

  String generateCsv(List<AgendaItem> items) {
    List<List<dynamic>> rows = [];
    rows.add(_headers);

    for (var item in items) {
      rows.add([
        item.tipo.toString().split('.').last, // Tipo
        _getItemId(item),                     // ID
        item.titulo,                          // Titulo
        item.descricao ?? '',                 // Descricao
        item.dataInicio?.toIso8601String() ?? '', // DataInicio
        item.horarioInicio ?? '',             // HorarioInicio
        item.dataFim?.toIso8601String() ?? '',// DataFim
        item.horarioFim ?? '',                // HorarioFim
        item.status.toString().split('.').last, // Status
        item.pagamento?.valor ?? '',          // Valor
        item.pagamento?.moeda ?? '',          // Moeda
        item.recorrencia?.frequencia ?? '',   // Recorrencia
        item.remedio?.nome ?? '',             // Remedio_Nome
        item.remedio?.dosagem ?? '',          // Remedio_Dose
        item.remedio?.frequenciaTipo ?? '',   // Remedio_Freq
        item.aniversario?.nomePessoa ?? '',   // Aniversario_Pessoa
        item.aniversario?.parentesco ?? '',   // Aniversario_Parentesco
        item.aniversario?.notificarAntes ?? '', // Aniversario_Notificar
        '', // Observacoes (Future use)
        item.criadoEm.toIso8601String(),      // CriadoEm
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  String _getItemId(AgendaItem item) {
    if (item.isInBox) return item.key.toString();
    if (item.remedio?.id != null) return item.remedio!.id!;
    if (item.pagamento?.transactionId != null) return item.pagamento!.transactionId!;
    return '';
  }

  Future<Map<String, int>> importCsv(String csvContent) async {
    int imported = 0;
    int ignored = 0;
    
    // Parse
    List<List<dynamic>> rows = const CsvToListConverter().convert(csvContent);
    if (rows.isEmpty) return {'imported': 0, 'ignored': 0};

    // Determine header indices
    final headers = rows.first.map((e) => e.toString().trim()).toList();
    // Basic validation
    if (!headers.contains('Tipo') || !headers.contains('Titulo')) {
       throw Exception("Formato de CSV inválido (cabeçalhos 'Tipo' ou 'Titulo' ausentes).");
    }

    // Process rows (skip header)
    for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty) continue;

        try {
           final Map<String, dynamic> map = {};
           for (int j = 0; j < row.length; j++) {
               if (j < headers.length) {
                   map[headers[j]] = row[j];
               }
           }
           
           bool success = await _processImportRow(map);
           if (success) imported++; else ignored++;

        } catch (e) {
           print("Erro import linha $i: $e");
           ignored++;
        }
    }

    return {'imported': imported, 'ignored': ignored};
  }

  Future<bool> _processImportRow(Map<String, dynamic> map) async {
      String tipoStr = map['Tipo']?.toString() ?? '';
      String titulo = map['Titulo']?.toString() ?? '';
      String dataInicioStr = map['DataInicio']?.toString() ?? '';
      String horarioInicio = map['HorarioInicio']?.toString() ?? '';
      
      // Convert Type
      AgendaItemType type = AgendaItemType.values.firstWhere(
          (e) => e.toString().split('.').last == tipoStr, 
          orElse: () => AgendaItemType.NOTA
      );
      
      // Parse Dates
      DateTime? startDate;
      if (dataInicioStr.isNotEmpty) {
        startDate = DateTime.tryParse(dataInicioStr);
      }

      if (titulo.isEmpty) return false;

      // Duplication Check
      final duplicates = _repo.getAll().where((existing) {
         if (existing.tipo != type) return false;
         if (existing.titulo != titulo) return false;
         
         // Date check
         if (startDate != null && existing.dataInicio != null) {
            // Compare YMD
            if (startDate.year != existing.dataInicio!.year ||
                startDate.month != existing.dataInicio!.month ||
                startDate.day != existing.dataInicio!.day) return false;
         }
         
         // Time check if provided
         if (horarioInicio.isNotEmpty && existing.horarioInicio != horarioInicio) return false;

         return true;
      });

      if (duplicates.isNotEmpty) return false; // Ignored due to duplication

      
      final newItem = AgendaItem(
          tipo: type,
          titulo: titulo,
          descricao: map['Descricao']?.toString(),
          dataInicio: startDate,
          horarioInicio: horarioInicio.isEmpty ? null : horarioInicio,
          horarioFim: map['HorarioFim']?.toString().isEmpty == true ? null : map['HorarioFim']?.toString(),
          status: ItemStatus.values.firstWhere(
             (e) => e.toString().split('.').last == map['Status'], 
             orElse: () => ItemStatus.PENDENTE
          ),
      );

      // Populate specifics based on type
      if (type == AgendaItemType.PAGAMENTO) {
          double val = double.tryParse(map['Valor']?.toString() ?? '0') ?? 0.0;
          newItem.pagamento = PagamentoInfo(
             valor: val, 
             status: 'PENDENTE', 
             dataVencimento: startDate ?? DateTime.now(),
             moeda: map['Moeda']?.toString() ?? 'BRL'
          );
      } else if (type == AgendaItemType.ANIVERSARIO) {
          newItem.aniversario = AniversarioInfo(
             nomePessoa: map['Aniversario_Pessoa']?.toString() ?? titulo.replaceAll('Aniversário de ', ''),
             parentesco: map['Aniversario_Parentesco']?.toString(),
             notificarAntes: int.tryParse(map['Aniversario_Notificar']?.toString() ?? '1') ?? 1
          );
      } else if (type == AgendaItemType.REMEDIO) {
          newItem.remedio = RemedioInfo(
             nome: map['Remedio_Nome']?.toString() ?? titulo,
             dosagem: map['Remedio_Dose']?.toString() ?? '',
             frequenciaTipo: map['Remedio_Freq']?.toString() ?? 'HORAS',
             intervalo: 8, // Default if missing
             inicioTratamento: startDate ?? DateTime.now()
          );
      }
      
      await _repo.addItem(newItem);
      return true;
  }

  Future<void> shareCsv(String csvContent, String filename) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$filename');
    await file.writeAsString(csvContent);
    await Share.shareXFiles([XFile(file.path)], text: 'Exportação Agenda FinAgeVoz');
  }
}
