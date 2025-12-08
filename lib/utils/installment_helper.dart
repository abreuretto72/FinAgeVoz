import 'package:uuid/uuid.dart';
import '../models/transaction_model.dart';

class InstallmentHelper {
  static const uuid = Uuid();

  /// Cria múltiplas transações parceladas
  /// 
  /// [description] - Descrição da compra
  /// [totalAmount] - Valor total da compra
  /// [installments] - Número de parcelas
  /// [firstInstallmentDate] - Data da primeira parcela
  /// [category] - Categoria da transação
  /// [subcategory] - Subcategoria (opcional)
  /// [isExpense] - Se é despesa (true) ou receita (false)
  /// [downPayment] - Valor da entrada/sinal (opcional)
  static List<Transaction> createInstallments({
    required String description,
    double? totalAmount,
    required int installments,
    required DateTime firstInstallmentDate,
    required String category,
    String? subcategory,
    bool isExpense = true,
    double downPayment = 0.0,
    DateTime? downPaymentDate,
    double? installmentValue,
  }) {
    if (installments < 2) {
      throw ArgumentError('Número de parcelas deve ser pelo menos 2');
    }

    if (totalAmount == null && installmentValue == null) {
      throw ArgumentError('Deve informar o valor total ou o valor da parcela');
    }

    final installmentId = uuid.v4();
    final transactions = <Transaction>[];
    
    // 1. Cria a transação de entrada (se houver)
    if (downPayment > 0) {
      transactions.add(Transaction(
        id: uuid.v4(),
        description: "$description (Entrada)",
        amount: downPayment,
        isExpense: isExpense,
        date: downPaymentDate ?? DateTime.now(),
        category: category,
        subcategory: subcategory,
        installmentId: installmentId,
        installmentNumber: 0, // 0 indica entrada
        totalInstallments: installments,
        isPaid: true,
        paymentDate: downPaymentDate,
      ));
    }

    // 2. Define o valor da parcela
    double finalInstallmentAmount;
    if (installmentValue != null) {
      finalInstallmentAmount = installmentValue;
    } else {
      final remainingAmount = totalAmount! - downPayment;
      finalInstallmentAmount = remainingAmount / installments;
    }

    // 3. Cria as parcelas
    for (int i = 0; i < installments; i++) {
      // Calcula a data de cada parcela (adiciona meses)
      final installmentDate = DateTime(
        firstInstallmentDate.year,
        firstInstallmentDate.month + i,
        firstInstallmentDate.day,
        firstInstallmentDate.hour,
        firstInstallmentDate.minute,
      );

      transactions.add(Transaction(
        id: uuid.v4(),
        description: description,
        amount: finalInstallmentAmount,
        isExpense: isExpense,
        date: installmentDate,
        category: category,
        subcategory: subcategory,
        installmentId: installmentId,
        installmentNumber: i + 1,
        totalInstallments: installments,
        isPaid: installmentDate.isBefore(DateTime.now()) || (installmentDate.year == DateTime.now().year && installmentDate.month == DateTime.now().month && installmentDate.day == DateTime.now().day),
        paymentDate: (installmentDate.isBefore(DateTime.now()) || (installmentDate.year == DateTime.now().year && installmentDate.month == DateTime.now().month && installmentDate.day == DateTime.now().day)) ? installmentDate : null,
      ));
    }

    return transactions;
  }

  /// Extrai informações de parcelamento de um texto de comando de voz
  /// 
  /// Retorna um Map com as informações extraídas ou null se não for parcelamento
  static Map<String, dynamic>? parseInstallmentCommand(String text) {
    final lowerText = text.toLowerCase();

    // Verifica se é um comando de parcelamento
    if (!lowerText.contains('parcela') && 
        !lowerText.contains('vezes') && 
        !lowerText.contains('vez')) {
      return null;
    }

    // Padrões para detectar número de parcelas
    final installmentPatterns = [
      RegExp(r'em\s+(\d+)\s+(?:vezes|vez|parcelas?)', caseSensitive: false),
      RegExp(r'(\d+)\s+(?:vezes|vez|parcelas?)', caseSensitive: false),
      RegExp(r'parcelado?\s+em\s+(\d+)', caseSensitive: false),
    ];

    int? installments;
    for (final pattern in installmentPatterns) {
      final match = pattern.firstMatch(lowerText);
      if (match != null) {
        installments = int.tryParse(match.group(1)!);
        break;
      }
    }

    if (installments == null || installments < 2) {
      return null;
    }

    // Extrai valor da entrada (se mencionado)
    double? downPayment;
    final downPaymentPatterns = [
      RegExp(r'(?:entrada|sinal)\s+(?:de\s+)?(?:R\$)?\s*(\d+(?:[.,]\d+)?)', caseSensitive: false),
      RegExp(r'dando\s+(\d+(?:[.,]\d+)?)\s+(?:de\s+)?(?:entrada|sinal)', caseSensitive: false),
    ];

    for (final pattern in downPaymentPatterns) {
      final match = pattern.firstMatch(lowerText);
      if (match != null) {
        final valueStr = match.group(1)!.replaceAll(',', '.');
        downPayment = double.tryParse(valueStr);
        break;
      }
    }

    // Extrai valor da parcela (se mencionado)
    double? installmentValue;
    final installmentValuePatterns = [
      RegExp(r'(?:parcelas?|vezes)\s+(?:de\s+)?(?:R\$)?\s*(\d+(?:[.,]\d+)?)', caseSensitive: false),
    ];

    for (final pattern in installmentValuePatterns) {
      final match = pattern.firstMatch(lowerText);
      if (match != null) {
        // Cuidado para não pegar o número de parcelas (ex: "10 vezes") como valor
        // O regex acima pega "vezes de X", mas "10 vezes" pode confundir se não tiver o "de"
        // Vamos ser mais estritos: "vezes de X" ou "parcelas de X"
        final valueStr = match.group(1)!.replaceAll(',', '.');
        installmentValue = double.tryParse(valueStr);
        break;
      }
    }

    // Extrai data da primeira parcela (se mencionada)
    DateTime? firstInstallmentDate;
    
    // Padrão: "primeira parcela dia X"
    final dayPattern = RegExp(r'primeira\s+parcela\s+dia\s+(\d+)', caseSensitive: false);
    final dayMatch = dayPattern.firstMatch(lowerText);
    if (dayMatch != null) {
      final day = int.tryParse(dayMatch.group(1)!);
      if (day != null && day >= 1 && day <= 31) {
        final now = DateTime.now();
        firstInstallmentDate = DateTime(now.year, now.month, day);
        
        // Se a data já passou este mês, usa o próximo mês
        if (firstInstallmentDate.isBefore(now)) {
          firstInstallmentDate = DateTime(now.year, now.month + 1, day);
        }
      }
    }

    // Padrão: "primeira parcela X de Y" (ex: "10 de dezembro")
    final monthDayPattern = RegExp(
      r'primeira\s+parcela\s+(\d+)\s+de\s+(janeiro|fevereiro|março|abril|maio|junho|julho|agosto|setembro|outubro|novembro|dezembro)',
      caseSensitive: false,
    );
    final monthDayMatch = monthDayPattern.firstMatch(lowerText);
    if (monthDayMatch != null) {
      final day = int.tryParse(monthDayMatch.group(1)!);
      final monthName = monthDayMatch.group(2)!.toLowerCase();
      
      final monthMap = {
        'janeiro': 1, 'fevereiro': 2, 'março': 3, 'abril': 4,
        'maio': 5, 'junho': 6, 'julho': 7, 'agosto': 8,
        'setembro': 9, 'outubro': 10, 'novembro': 11, 'dezembro': 12,
      };
      
      final month = monthMap[monthName];
      if (day != null && month != null) {
        final now = DateTime.now();
        var year = now.year;
        
        // Se o mês já passou este ano, usa o próximo ano
        if (month < now.month || (month == now.month && day < now.day)) {
          year++;
        }
        
        firstInstallmentDate = DateTime(year, month, day);
      }
    }

    return {
      'installments': installments,
      'firstInstallmentDate': firstInstallmentDate,
      'downPayment': downPayment,
      'installmentValue': installmentValue,
    };
  }
}
