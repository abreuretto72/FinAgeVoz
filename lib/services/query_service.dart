import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../models/event_model.dart';
import '../services/database_service.dart';

class QueryService {
  final DatabaseService _dbService;
  // Service updated to enforce strict installment filtering
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
- Para perguntas sobre 'saldo atual', 'patrimônio' ou 'total comprometido', use 'Saldo Atual'.
- Para perguntas sobre 'fluxo de caixa', 'disponível hoje' ou 'realizado', use 'Saldo do Fluxo de Caixa'.
- Se o usuário pedir para listar as transações ou perguntar por que está errado, LEIA a lista 'Detalhamento COMPLETO do Saldo' e diga quais transações estão lá.
- Explique a diferença entre os saldos se necessário.
- Se houver receitas/reembolsos em uma categoria de despesa, mencione o valor líquido (Despesa - Receita).
- Se não houver dados suficientes, diga isso claramente
- Não use a palavra 'Portanto' ou conclusões óbvias.
- Seja direto e objetivo.
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
    final startOfThisMonth = DateTime(now.year, now.month, 1);
    
    // Filter out future transactions and fix installment dates issues
    final validTransactions = <Transaction>[];
    
    // Group by installmentId OR description+total to check for date duplicates
    final installmentGroups = <String, List<Transaction>>{};
    
    for (var t in transactions) {
      String? groupId;
      if (t.installmentId != null && t.installmentId!.isNotEmpty) {
        groupId = t.installmentId;
      } else if (t.totalInstallments != null && t.totalInstallments! > 1) {
        // Fallback: Group by description and total installments
        groupId = "${t.description}|${t.totalInstallments}|${t.amount}";
      }
      
      if (groupId != null) {
        installmentGroups.putIfAbsent(groupId, () => []).add(t);
      } else {
        // Not an installment or single transaction
        // We include future transactions here so Total Balance is correct
         validTransactions.add(t);
      }
    }
    
    // Process installment groups to remove technical duplicates (same month/day bugs)
    // But keep future installments for Total Balance
    final uniqueTransactions = <Transaction>[];
    
    installmentGroups.forEach((id, group) {
       group.sort((a, b) => (a.installmentNumber ?? 0).compareTo(b.installmentNumber ?? 0));
       final seenMonths = <String>{};
       for (var t in group) {
          final monthKey = "${t.date.year}-${t.date.month}";
          if (seenMonths.contains(monthKey)) continue; 
          seenMonths.add(monthKey);
          uniqueTransactions.add(t);
       }
    });
    
    // Add non-installments
    for (var t in transactions) {
       if ((t.totalInstallments ?? 0) <= 1 && (t.installmentId == null || t.installmentId!.isEmpty)) {
           // Check if not already added via groups (should not happen based on logic)
           if (!t.date.isAfter(now)) { // Keep logic for non-installments? Or allow future single transactions?
               // For Total Balance, we should include future single transactions too if they exist.
               // But usually single transactions are immediate.
               uniqueTransactions.add(t);
           }
       }
    }

    // Calculate Balances
    double totalBalance = 0; // Saldo Atual (Tudo)
    double cashFlowBalance = 0; // Fluxo de Caixa (Realizado)
    
    final validCashFlowTransactions = <Transaction>[];

    for (var t in uniqueTransactions) {
      totalBalance += t.amount;
      
      // Filter for Cash Flow (Realized)
      if (t.isRealized) {
         cashFlowBalance += t.amount;
         validCashFlowTransactions.add(t);
      }
    }
    
    // Recalculate monthly stats based on validCashFlowTransactions (Realized)
    final thisMonth = DateTime(now.year, now.month, 1);
    final nextMonth = DateTime(now.year, now.month + 1, 1);
    final lastMonth = DateTime(now.year, now.month - 1, 1);
    
    final thisMonthTransactions = validCashFlowTransactions
        .where((t) => !t.date.isBefore(thisMonth) && t.date.isBefore(nextMonth))
        .toList();

    final thisMonthIncome = thisMonthTransactions
        .where((t) => !t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);

    final thisMonthExpenses = thisMonthTransactions
        .where((t) => t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);
        
    // Last month transactions
    final lastMonthTransactions = transactions
        .where((t) => 
            !t.date.isBefore(lastMonth) && 
            t.date.isBefore(thisMonth))
        .toList();
        
    final lastMonthExpenses = lastMonthTransactions
        .where((t) => t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);
        
    final lastMonthIncome = lastMonthTransactions
        .where((t) => !t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);
    
    // Calculate Previous Balance (Realized)
    double previousBalance = 0;
    for (var t in validCashFlowTransactions) {
       if (t.date.isBefore(startOfThisMonth)) {
          previousBalance += t.amount;
       }
    }

    // Build summary
    final buffer = StringBuffer();
    buffer.writeln("Saldo Anterior (Final do mês passado): R\$ ${previousBalance.toStringAsFixed(2)}");
    
    buffer.writeln("Movimentações deste mês (Realizado até agora):");
    buffer.writeln("- Receitas Realizadas: R\$ ${thisMonthIncome.toStringAsFixed(2)}");
    buffer.writeln("- Despesas Realizadas: R\$ ${thisMonthExpenses.toStringAsFixed(2)}");
    buffer.writeln("- Resultado do Mês (Realizado): R\$ ${(thisMonthIncome + thisMonthExpenses).toStringAsFixed(2)}");
    
    buffer.writeln("\nSaldos:");
    buffer.writeln("Saldo Atual (Considera TUDO, inclusive parcelas futuras): R\$ ${totalBalance.toStringAsFixed(2)}");
    buffer.writeln("Saldo do Fluxo de Caixa (Realizado hoje - CORRIGIDO): R\$ ${cashFlowBalance.toStringAsFixed(2)}");
    
    // List installments included in balance for transparency
    buffer.writeln("\nDetalhamento COMPLETO do Saldo Realizado (Todas as transações somadas no Fluxo de Caixa):");
    // Sort by date
    validCashFlowTransactions.sort((a, b) => a.date.compareTo(b.date));
    for (var t in validCashFlowTransactions) {
       buffer.writeln("- ${DateFormat('dd/MM/yyyy').format(t.date)}: ${t.description} (R\$ ${t.amount.toStringAsFixed(2)}) [Installment: ${t.installmentNumber}/${t.totalInstallments}]");
    }
    
    // Group by category
    final Map<String, double> expensesByCategory = {};
    final Map<String, double> incomeByCategory = {}; 
    final Map<String, Map<String, double>> expensesBySubcategory = {};
    
    for (var t in thisMonthTransactions) {
      if (t.isExpense) {
        expensesByCategory[t.category] = 
            (expensesByCategory[t.category] ?? 0) + t.amount;
        
        if (t.subcategory != null) {
          expensesBySubcategory[t.category] ??= {};
          expensesBySubcategory[t.category]![t.subcategory!] = 
              (expensesBySubcategory[t.category]![t.subcategory!] ?? 0) + t.amount;
        }
      } else {
        incomeByCategory[t.category] = 
            (incomeByCategory[t.category] ?? 0) + t.amount;
      }
    }
    
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
        
        if (expensesBySubcategory.containsKey(category)) {
          final subcats = expensesBySubcategory[category]!.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          for (var subcat in subcats.take(3)) {
            buffer.writeln("  • ${subcat.key}: R\$ ${subcat.value.toStringAsFixed(2)}");
          }
        }
      }
    }

    if (thisMonthTransactions.isNotEmpty) {
      buffer.writeln("\nLista de transações deste mês:");
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
    
    // Add Installment Summary Section
    if (installmentGroups.isNotEmpty) {
       buffer.writeln("\nResumo de Parcelamentos Ativos:");
       installmentGroups.forEach((id, group) {
           group.sort((a, b) => (a.installmentNumber ?? 0).compareTo(b.installmentNumber ?? 0));
           
           double totalAmount = group.fold(0, (sum, t) => sum + t.amount);
           int totalInstallments = group.first.totalInstallments ?? group.length;
           
           // Calculate paid installments (excluding down payment)
           // Identify down payments by number 0 OR description 'entrada'
           var downPayments = group.where((t) => 
               (t.installmentNumber ?? 0) == 0 || 
               t.description.toLowerCase().contains('entrada')
           ).toList();
           
           int downPaymentCount = downPayments.length;
           
           // Filter out down payments from the group for installment counting
           var installmentTransactions = group.where((t) => !downPayments.contains(t)).toList();
           
           int paidInstallments = 0;
           Transaction? nextInstallment;
           
           for (var t in installmentTransactions) {
              if (t.date.isBefore(now)) {
                  paidInstallments++;
              } else if (nextInstallment == null) {
                  nextInstallment = t;
              }
           }
           
           int totalRealInstallments = installmentTransactions.length;
           // If totalInstallments from DB is reliable, use it, otherwise use count
           // But if DB says 5 and we have 4 real installments, maybe user meant 5 real?
           // Let's report what we have.
           
           int remainingCount = installmentTransactions.length - paidInstallments;
           double remainingAmount = installmentTransactions
               .where((t) => !t.date.isBefore(now))
               .fold(0.0, (sum, t) => sum + t.amount);
           
           buffer.writeln("- ${group.first.description}: Total da compra R\$ ${totalAmount.toStringAsFixed(2)}");
           buffer.writeln("  - Restam $remainingCount parcelas para pagar no valor total de R\$ ${remainingAmount.toStringAsFixed(2)}.");
           if (downPaymentCount > 0) {
              buffer.writeln("  - (Entrada já foi paga).");
           }
           if (nextInstallment != null) {
              buffer.writeln("  - Próxima parcela: ${DateFormat('dd/MM/yyyy').format(nextInstallment.date)} (R\$ ${nextInstallment.amount.toStringAsFixed(2)})");
           }
       });
    }
    
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
      buffer.writeln("Nenhum evento próximo.");
    }
    
    return buffer.toString();
  }
}
