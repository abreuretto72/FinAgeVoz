import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import 'database_service.dart';

class TransactionNotificationService {
  final DatabaseService _dbService = DatabaseService();

  Future<List<Transaction>> checkUnpaidInstallments() async {
    await _dbService.init(); // Ensure DB is initialized
    final transactions = _dbService.getTransactions();
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    
    return transactions.where((t) {
      if (!t.isExpense) return false;
      if (t.isPaid) return false;
      if (!t.isInstallment && !t.date.isBefore(now)) {
         // Optionally include non-installments if requested, but user said "Parcela".
         // Keeping strict usually better for now unless specific requirement.
         // Stick to installments as per "Toda parcela".
      }
      if (!t.isInstallment) return false; 
      if (t.installmentNumber == 0) return false; // Down payment (Entrada) is always considered realized/paid
      
      // Normalize transaction date to midnight
      final tDate = DateTime(t.date.year, t.date.month, t.date.day);
      
      // Include Overdue (Past), Today, and Tomorrow
      // tDate <= tomorrow
      return tDate.compareTo(tomorrow) <= 0;
    }).toList();
  }
}
