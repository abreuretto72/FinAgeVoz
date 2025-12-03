import 'package:hive/hive.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: 0)
class Transaction extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String description;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final bool isExpense;

  @HiveField(4)
  final DateTime date;

  @HiveField(5)
  final bool isReversal;

  @HiveField(6)
  final String? originalTransactionId;

  @HiveField(7)
  final String category;

  @HiveField(8)
  final String? subcategory;

  // Installment fields
  @HiveField(9)
  final String? installmentId; // ID único para agrupar parcelas

  @HiveField(10)
  final int? installmentNumber; // Número da parcela (1, 2, 3...)

  @HiveField(11)
  final int? totalInstallments; // Total de parcelas (12, 6, etc.)

  @HiveField(12)
  final List<String>? attachments;

  Transaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.isExpense,
    required this.date,
    this.isReversal = false,
    this.originalTransactionId,
    this.category = 'Outras Despesas',
    this.subcategory,
    this.installmentId,
    this.installmentNumber,
    this.totalInstallments,
    this.attachments,
  });

  // Helper to check if this is an installment transaction
  bool get isInstallment => installmentId != null && installmentNumber != null && totalInstallments != null;

  // Helper to get installment display text
  String get installmentText => isInstallment ? 'Parcela $installmentNumber/$totalInstallments' : '';
}
