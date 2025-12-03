import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../models/event_model.dart';
import '../services/database_service.dart';

class QueryService {
  final DatabaseService _dbService;

  QueryService(this._dbService);

  /// Answer simple questions locally without using AI (to save tokens and be faster)
  Future<String> answerSimpleQuestion(String question, String language) async {
    final lowerQuestion = question.toLowerCase();
    
    if (lowerQuestion.contains('gasolina') || lowerQuestion.contains('combustível')) {
       final transactions = _dbService.getTransactions();
       final now = DateTime.now();
       final startOfMonth = DateTime(now.year, now.month, 1);
       
       // Filter for gasoline transactions in the current month
       final total = transactions
           .where((t) => t.isExpense && 
                        !t.date.isBefore(startOfMonth) && 
                        (t.description.toLowerCase().contains('gasolina') || 
                         t.description.toLowerCase().contains('posto') ||
                         t.subcategory?.toLowerCase() == 'combustível' ||
                         t.subcategory?.toLowerCase() == 'gasolina'))
           .fold(0.0, (sum, t) => sum + t.amount);
           
       return "Você gastou ${total.toStringAsFixed(2)} reais com combustível este mês.";
    }
    
    return "Desculpe, não tenho essa informação no momento.";
  }

  /// Process a natural language query and return a spoken answer
  Future<String> answerFinancialQuestion(String question, String language) async {
    try {
      // Get relevant data
      final transactions = _dbService.getTransactions();
      final events = _dbService.getEvents();
      final now = DateTime.now();
      
      // Filter to recent data (last 12 months) to reduce token usage
      final twelveMonthsAgo = now.subtract(const Duration(days: 365));
      final recentTransactions = transactions
          .where((t) => t.date.isAfter(twelveMonthsAgo))
          .toList();
      
      // Prepare context data
      final transactionsSummary = _prepareTransactionsSummary(recentTransactions);
      final eventsSummary = _prepareEventsSummary(events);
      final currentDate = DateFormat('dd/MM/yyyy').format(now);
      
      return """
Baseado nos dados financeiros do usuário, responda a pergunta de forma concisa e natural.

Data atual: $currentDate

Resumo de Transações (últimos 12 meses):
$transactionsSummary

Eventos:
$eventsSummary

Pergunta do usuário: "$question"

Instruções:
- Responda em português brasileiro de forma natural e conversacional
- Seja conciso (máximo 2-3 frases)
- Use valores em reais (R\$) quando aplicável
- Ao listar transações, SEMPRE mencione a descrição (o que foi comprado) e o valor.
- Sempre forneça o valor total do grupo de transações solicitado (ex: total do mês, total de gasolina, etc).
- Para perguntas sobre 'total de parcelas' ou 'compras parceladas', use EXATAMENTE o valor de 'Total de despesas parceladas este mês'.
- Se houver receitas/reembolsos em uma categoria de despesa, mencione o valor líquido (Despesa - Receita).
- Se não houver dados suficientes, diga isso claramente
- Não invente informações
""";
    } catch (e) {
      print("Error preparing query context: $e");
      return "Desculpe, ocorreu um erro ao processar sua pergunta.";
    }
  }

  String _prepareTransactionsSummary(List<Transaction> transactions) {
    if (transactions.isEmpty) {
      return "Nenhuma transação registrada.";
    }

    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month, 1);
    final nextMonth = DateTime(now.year, now.month + 1, 1);
    final lastMonth = DateTime(now.year, now.month - 1, 1);
    
    // This month transactions (include reversals to balance out)
    final thisMonthTransactions = transactions
        .where((t) => !t.date.isBefore(thisMonth) && t.date.isBefore(nextMonth))
        .toList();
    
    // DEBUG: Log transactions for debugging summation (Alimentação issue)
    print("DEBUG: --- START TRANSACTION LOG ---");
    for (var t in thisMonthTransactions) {
      if (t.category == 'Alimentação') {
         print("DEBUG: [${t.category}] ${t.description}: ${t.amount} (Expense: ${t.isExpense}, Reversal: ${t.isReversal}, ID: ${t.id})");
      }
    }
    print("DEBUG: --- END TRANSACTION LOG ---");
    
    // Last month transactions
    final lastMonthTransactions = transactions
        .where((t) => 
            !t.date.isBefore(lastMonth) && 
            t.date.isBefore(thisMonth))
        .toList();
    
    // Calculate totals (Net)
    final totalExpensesGross = thisMonthTransactions
        .where((t) => t.isExpense && !t.isReversal)
        .fold(0.0, (sum, t) => sum + t.amount);
        
    final totalExpensesReversed = thisMonthTransactions
        .where((t) => t.isExpense && t.isReversal)
        .fold(0.0, (sum, t) => sum + t.amount);
        
    final thisMonthExpenses = totalExpensesGross - totalExpensesReversed;

    final totalIncomeGross = thisMonthTransactions
        .where((t) => !t.isExpense && !t.isReversal)
        .fold(0.0, (sum, t) => sum + t.amount);
        
    final totalIncomeReversed = thisMonthTransactions
        .where((t) => !t.isExpense && t.isReversal)
        .fold(0.0, (sum, t) => sum + t.amount);
        
    final thisMonthIncome = totalIncomeGross - totalIncomeReversed;
    
    final lastMonthExpenses = lastMonthTransactions
        .where((t) => t.isExpense && !t.isReversal)
        .fold(0.0, (sum, t) => sum + t.amount) - 
        lastMonthTransactions
        .where((t) => t.isExpense && t.isReversal)
        .fold(0.0, (sum, t) => sum + t.amount);
        
    final lastMonthIncome = lastMonthTransactions
        .where((t) => !t.isExpense && !t.isReversal)
        .fold(0.0, (sum, t) => sum + t.amount) - 
        lastMonthTransactions
        .where((t) => !t.isExpense && t.isReversal)
        .fold(0.0, (sum, t) => sum + t.amount);
    
    // Group by category
    final Map<String, double> expensesByCategory = {};
    final Map<String, double> incomeByCategory = {}; // For refunds/reversals
    final Map<String, Map<String, double>> expensesBySubcategory = {};
    
    for (var t in thisMonthTransactions) {
      if (t.isExpense) {
        if (t.isReversal) {
          // Reversal of Expense -> Treated as Refund (Income)
          incomeByCategory[t.category] = 
              (incomeByCategory[t.category] ?? 0) + t.amount;
        } else {
          // Normal Expense
          expensesByCategory[t.category] = 
              (expensesByCategory[t.category] ?? 0) + t.amount;
          
          if (t.subcategory != null) {
            expensesBySubcategory[t.category] ??= {};
            expensesBySubcategory[t.category]![t.subcategory!] = 
                (expensesBySubcategory[t.category]![t.subcategory!] ?? 0) + t.amount;
          }
        }
      } else {
        if (t.isReversal) {
          // Reversal of Income -> Treated as Expense (Money removed)
          expensesByCategory[t.category] = 
              (expensesByCategory[t.category] ?? 0) + t.amount;
        } else {
          // Normal Income
          incomeByCategory[t.category] = 
              (incomeByCategory[t.category] ?? 0) + t.amount;
        }
      }
    }
    
    // Build summary
    final buffer = StringBuffer();
    buffer.writeln("Este mês:");
    buffer.writeln("- Despesas Líquidas: R\$ ${thisMonthExpenses.toStringAsFixed(2)}");
    buffer.writeln("- Receitas Líquidas: R\$ ${thisMonthIncome.toStringAsFixed(2)}");
    buffer.writeln("- Saldo: R\$ ${(thisMonthIncome - thisMonthExpenses).toStringAsFixed(2)}");
    
    // Calculate total installments amount for this month
    final totalInstallmentsThisMonth = thisMonthTransactions
        .where((t) => t.isExpense && t.isInstallment)
        .fold(0.0, (sum, t) => sum + t.amount);
        
    buffer.writeln("- Total de despesas parceladas este mês: R\$ ${totalInstallmentsThisMonth.toStringAsFixed(2)} (Soma apenas das parcelas, não o valor total das compras)");
    
    if (expensesByCategory.isNotEmpty) {
      buffer.writeln("\nDespesas por categoria este mês:");
      final sortedCategories = expensesByCategory.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      for (var entry in sortedCategories.take(5)) {
        final category = entry.key;
        final expenseAmount = entry.value;
        final incomeAmount = incomeByCategory[category] ?? 0.0;
        
        if (incomeAmount > 0) {
          final netAmount = expenseAmount - incomeAmount;
          buffer.writeln("- $category: R\$ ${expenseAmount.toStringAsFixed(2)} (Reembolsos/Receitas: R\$ ${incomeAmount.toStringAsFixed(2)} -> Líquido: R\$ ${netAmount.toStringAsFixed(2)})");
        } else {
          buffer.writeln("- $category: R\$ ${expenseAmount.toStringAsFixed(2)}");
        }
        
        // Add subcategories if available
        if (expensesBySubcategory.containsKey(category)) {
          final subcats = expensesBySubcategory[category]!.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          for (var subcat in subcats.take(3)) {
            buffer.writeln("  • ${subcat.key}: R\$ ${subcat.value.toStringAsFixed(2)}");
          }
        }
      }
    }

    // Add detailed transaction list for context
    if (thisMonthTransactions.isNotEmpty) {
      buffer.writeln("\nLista de transações deste mês:");
      // Sort by date descending
      thisMonthTransactions.sort((a, b) => b.date.compareTo(a.date));
      
      for (var t in thisMonthTransactions) {
        final dateStr = DateFormat('dd/MM').format(t.date);
        final typeStr = t.isExpense ? "Despesa" : "Receita";
        final installmentStr = t.isInstallment ? " (${t.installmentText})" : "";
        buffer.writeln("- [$dateStr] ${t.description}: R\$ ${t.amount.toStringAsFixed(2)} ($typeStr, ${t.category})$installmentStr");
      }
    }
    
    buffer.writeln("\nMês passado:");
    buffer.writeln("- Despesas: R\$ ${lastMonthExpenses.toStringAsFixed(2)}");
    buffer.writeln("- Receitas: R\$ ${lastMonthIncome.toStringAsFixed(2)}");
    
    return buffer.toString();
  }

  String _prepareEventsSummary(List<Event> events) {
    if (events.isEmpty) {
      return "Nenhum evento agendado.";
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final nextWeek = today.add(const Duration(days: 7));
    
    // Filter upcoming events
    final upcomingEvents = events
        .where((e) => !e.isCancelled && e.date.isAfter(now))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    
    final todayEvents = upcomingEvents
        .where((e) => e.date.isAfter(today) && e.date.isBefore(tomorrow))
        .toList();
    
    final tomorrowEvents = upcomingEvents
        .where((e) => e.date.isAfter(tomorrow) && e.date.isBefore(tomorrow.add(const Duration(days: 1))))
        .toList();
    
    final thisWeekEvents = upcomingEvents
        .where((e) => e.date.isAfter(tomorrow) && e.date.isBefore(nextWeek))
        .toList();
    
    final buffer = StringBuffer();
    
    if (todayEvents.isNotEmpty) {
      buffer.writeln("Hoje:");
      for (var event in todayEvents.take(5)) {
        buffer.writeln("- ${event.title} às ${DateFormat('HH:mm').format(event.date)}");
      }
    }
    
    if (tomorrowEvents.isNotEmpty) {
      buffer.writeln("\nAmanhã:");
      for (var event in tomorrowEvents.take(5)) {
        buffer.writeln("- ${event.title} às ${DateFormat('HH:mm').format(event.date)}");
      }
    }
    
    if (thisWeekEvents.isNotEmpty) {
      buffer.writeln("\nEsta semana:");
      for (var event in thisWeekEvents.take(5)) {
        buffer.writeln("- ${event.title} em ${DateFormat('dd/MM').format(event.date)} às ${DateFormat('HH:mm').format(event.date)}");
      }
    }
    
    if (todayEvents.isEmpty && tomorrowEvents.isEmpty && thisWeekEvents.isEmpty) {
      if (upcomingEvents.isNotEmpty) {
        buffer.writeln("Próximos eventos:");
        for (var event in upcomingEvents.take(3)) {
          buffer.writeln("- ${event.title} em ${DateFormat('dd/MM/yyyy HH:mm').format(event.date)}");
        }
      } else {
        return "Nenhum evento próximo agendado.";
      }
    }
    
    return buffer.toString();
  }
}
