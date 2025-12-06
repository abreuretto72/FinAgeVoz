import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import 'database_service.dart';

class TransactionNotificationService {
  final DatabaseService _dbService = DatabaseService();

  Future<List<Transaction>> checkUpcomingInstallments() async {
    await _dbService.init(); // Ensure DB is initialized
    final transactions = _dbService.getTransactions();
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    
    return transactions.where((t) {
      if (!t.isExpense) return false;
      if (t.isPaid) return false;
      if (!t.isInstallment) return false; // Only installments per user request
      
      // Check if date is tomorrow (ignoring time)
      return t.date.year == tomorrow.year && 
             t.date.month == tomorrow.month && 
             t.date.day == tomorrow.day;
    }).toList();
  }
}
