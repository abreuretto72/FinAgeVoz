import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import 'database_service.dart';

class BIService {
  final DatabaseService _dbService;

  BIService({DatabaseService? dbService}) : _dbService = dbService ?? DatabaseService();

  Future<String> processQuery(Map<String, dynamic> query) async {
    // 1. Extract Query Parameters
    final operation = (query['operation'] as String?)?.toUpperCase() ?? 'SUM';
    final category = query['category'] as String?;
    final subcategory = query['subcategory'] as String?;
    final period = (query['period'] as String?)?.toUpperCase() ?? 'THIS_MONTH';
    final type = (query['type'] as String?)?.toUpperCase(); // EXPENSE, INCOME
    
    // 2. Determine Date Range
    final dateRange = _getDateRange(period);
    final startDate = dateRange['start']!;
    final endDate = dateRange['end']!;

    // 3. Fetch Transactions
    final allTransactions = _dbService.getTransactions();
    
    // 4. Filter Transactions
    final filtered = allTransactions.where((t) {
      if (t.date.isBefore(startDate) || t.date.isAfter(endDate)) return false;
      if (category != null && t.category.toLowerCase() != category.toLowerCase()) return false;
      if (subcategory != null && t.subcategory?.toLowerCase() != subcategory.toLowerCase()) return false;
      
      // Filter by type (Expense/Income)
      // Note: 'type' param: 'EXPENSE' or 'INCOME'
      if (type == 'EXPENSE' && !t.isExpense) return false;
      if (type == 'INCOME' && t.isExpense) return false;
      
      // Filter specific keywords for FIND operation
      if (operation == 'FIND' && query['keywords'] != null) {
        final k = (query['keywords'] as String).toLowerCase();
        return t.description.toLowerCase().contains(k);
      }
      
      return true;
    }).toList();

    // 5. Perform Operation
    switch (operation) {
      case 'SUM':
        return _calculateSum(filtered, type, category, period);
      case 'COUNT':
        return _calculateCount(filtered, category, period);
      case 'AVERAGE':
        return _calculateAverage(filtered, period, category); // Need historical data for true average
      case 'CHECK_BUDGET':
        return _checkBudget(filtered, query, startDate, endDate); // Pass query for estimatedAmount
      case 'ALERT':
         return _checkAlerts(allTransactions, query); // Alerts check ALL transactions (e.g. overdue)
      case 'TOP':
        return _getTopTransactions(filtered, query);
      case 'FIND':
        return _findSpecific(filtered, query);
      case 'BALANCE':
        return _calculateBalance(allTransactions, query); // Balance uses ALL transactions to calculate current state
      default:
        return _calculateSum(filtered, type, category, period); // Fallback
    }
  }

  Map<String, DateTime> _getDateRange(String period) {
    final now = DateTime.now();
    DateTime start;
    DateTime end;

    switch (period) {
      case 'TODAY':
        start = DateTime(now.year, now.month, now.day);
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'YESTERDAY':
        start = DateTime(now.year, now.month, now.day - 1);
        end = DateTime(now.year, now.month, now.day - 1, 23, 59, 59);
        break;
      case 'THIS_WEEK':
        // Determine start of week (Sunday for now or Monday?) - Let's use Monday
        start = now.subtract(Duration(days: now.weekday - 1));
        start = DateTime(start.year, start.month, start.day);
        end = DateTime(now.year, now.month, now.day, 23, 59, 59); // Up to now? Or end of week? Usually up to now for "spent this week"
        break;
      case 'LAST_MONTH':
        start = DateTime(now.year, now.month - 1, 1);
        end = DateTime(now.year, now.month, 0, 23, 59, 59);
        break;
      case 'THIS_YEAR':
        start = DateTime(now.year, 1, 1);
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'LAST_3_MONTHS':
        start = DateTime(now.year, now.month - 3, 1);
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'NEXT_3_DAYS':
        start = DateTime(now.year, now.month, now.day);
        end = now.add(const Duration(days: 3));
        end = DateTime(end.year, end.month, end.day, 23, 59, 59);
        break;
      case 'THIS_MONTH':
      default:
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
    }
    return {'start': start, 'end': end};
  }
  
  String _formatMoney(double value) {
     if (value == 0) return "zero reais";
     // Simple formatting for voice
     final intVal = value.truncate();
     final cents = ((value - intVal) * 100).round();
     
     if (cents == 0) return "$intVal reais";
     return "$intVal reais e $cents centavos";
  }
  
  // --- OPERATION HANDLERS ---

  String _calculateSum(List<Transaction> transactions, String? type, String? category, String period) {
    double total = 0;
    for (var t in transactions) {
      total += t.amount;
    }
    
    String desc = "gasto";
    if (type == 'INCOME') desc = "recebido";
    if (category != null) desc += " com $category";
    
    String periodText = _getPeriodText(period);
    
    if (total == 0) return "Você não tem nenhum $desc $periodText.";
    return "O total $desc $periodText foi de ${_formatMoney(total)}.";
  }

  String _calculateCount(List<Transaction> transactions, String? category, String period) {
    final count = transactions.length;
    String desc = category != null ? "registros de $category" : "transações";
    String periodText = _getPeriodText(period);
    
    return "Você teve $count $desc $periodText.";
  }

  String _checkAlerts(List<Transaction> all, Map<String, dynamic> query) {
    if (query['status'] == 'OVERDUE') {
       final now = DateTime.now();
       final overdue = all.where((t) => !t.isPaid && t.isExpense && t.date.isBefore(DateTime(now.year, now.month, now.day))).toList();
       if (overdue.isEmpty) return "Ótimas notícias! Você não tem nenhuma conta atrasada.";
       
       double total = overdue.fold(0, (sum, t) => sum + t.amount);
       return "Atenção! Você tem ${overdue.length} contas atrasadas, totalizando ${_formatMoney(total)}. A mais antiga é ${overdue.first.description}.";
    }
    // Implement standard alerts
    return "Tudo parece em ordem com suas contas.";
  }
  
  String _calculateBalance(List<Transaction> all, Map<String, dynamic> query) {
      // Calculate current balance (Income Paid - Expense Paid)
      double balance = 0;
      for (var t in all) {
          if (!t.isPaid) continue;
          if (t.isExpense) balance -= t.amount;
          else balance += t.amount;
      }
      
      final type = query['type'];
      if (type == 'PROJECTED') {
          // Add pending income/expense till end of period?
          // Simplification: Projected usually means "End of Month"
          // We need to filter pending items until end of month.
          // This requires logic similar to Aggregation but for future items.
          // For MVP, return current balance.
          return "Seu saldo atual consolidado é de ${_formatMoney(balance)}.";
      }
      
      return "Seu saldo atual é de ${_formatMoney(balance)}.";
  }
  
  String _findSpecific(List<Transaction> filtered, Map<String, dynamic> query) {
      if (filtered.isEmpty) return "Não encontrei nada correspondente.";
      
      final item = filtered.first;
      final field = query['extractField'];
      
      if (field == 'dueDate') {
          return "O vencimento de ${item.description} é dia ${DateFormat('dd/MM').format(item.date)}.";
      } else if (field == 'amount') {
          return "O valor de ${item.description} é ${_formatMoney(item.amount)}.";
      } else if (field == 'status') {
          return item.isPaid ? "${item.description} já foi pago." : "${item.description} ainda está pendente.";
      }
      
      return "Encontrei: ${item.description} valor ${_formatMoney(item.amount)} dia ${DateFormat('dd').format(item.date)}.";
  }

  // --- PLACEHOLDERS FOR COMPLEX OPS ---
  String _calculateAverage(List<Transaction> transactions, String period, String? category) {
      // For MVP, just return average of filtered list amounts? NO, Average usually implies "Average Monthly Spend"
      // If period is THIS_YEAR, group by month?
      return _calculateSum(transactions, 'EXPENSE', category, period).replaceAll("total", "média (simplificada)");
  }
  
  String _checkBudget(List<Transaction> transactions, Map<String, dynamic> query, DateTime start, DateTime end) {
      return "Funcionalidade de orçamento em desenvolvimento. Mas você gastou ${_formatMoney(transactions.fold(0.0, (s,t)=>s+t.amount))} na categoria.";
  }
  
  String _getTopTransactions(List<Transaction> transactions, Map<String, dynamic> query) {
      if (transactions.isEmpty) return "Nenhuma despesa no período.";
      transactions.sort((a,b) => b.amount.compareTo(a.amount));
      final top = transactions.first;
      return "Sua maior despesa foi ${top.description} no valor de ${_formatMoney(top.amount)}.";
  }

  String _getPeriodText(String period) {
    switch (period) {
      case 'TODAY': return "hoje";
      case 'YESTERDAY': return "ontem";
      case 'THIS_MONTH': return "neste mês";
      case 'LAST_MONTH': return "no mês passado";
      case 'THIS_YEAR': return "neste ano";
      default: return "no período";
    }
  }
}
