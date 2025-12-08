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

  @HiveField(13)
  final DateTime? updatedAt;

  @HiveField(14)
  final bool isDeleted;

  @HiveField(15)
  final bool isSynced;

  @HiveField(16)
  final bool isPaid;

  @HiveField(17)
  final DateTime? paymentDate;

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
    DateTime? updatedAt,
    this.isDeleted = false,
    this.isSynced = false,
    this.isPaid = false,
    this.paymentDate,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'isExpense': isExpense,
      'date': date.toIso8601String(),
      'isReversal': isReversal,
      'originalTransactionId': originalTransactionId,
      'category': category,
      'subcategory': subcategory,
      'installmentId': installmentId,
      'installmentNumber': installmentNumber,
      'totalInstallments': totalInstallments,
      'attachments': attachments,
      'updatedAt': updatedAt?.toIso8601String(),
      'isDeleted': isDeleted,
      'isPaid': isPaid,
      'paymentDate': paymentDate?.toIso8601String(),
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      description: map['description'],
      amount: (map['amount'] as num).toDouble(),
      isExpense: map['isExpense'],
      date: DateTime.parse(map['date']),
      isReversal: map['isReversal'] ?? false,
      originalTransactionId: map['originalTransactionId'],
      category: map['category'] ?? 'Outras Despesas',
      subcategory: map['subcategory'],
      installmentId: map['installmentId'],
      installmentNumber: map['installmentNumber'],
      totalInstallments: map['totalInstallments'],
      attachments: map['attachments'] != null ? List<String>.from(map['attachments']) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      isDeleted: map['isDeleted'] ?? false,
      isSynced: true, // When coming from cloud, it is synced
      isPaid: map['isPaid'] ?? false,
      paymentDate: map['paymentDate'] != null ? DateTime.parse(map['paymentDate']) : null,
    );
  }

  // Helper to check if this is an installment transaction
  bool get isInstallment => installmentId != null && installmentNumber != null && totalInstallments != null;

  // Helper to get installment display text
  String get installmentText => isInstallment ? 'Parcela $installmentNumber/$totalInstallments' : '';

  // Helper to determine if transaction is realized (Cash Flow)
  // Refined Rules:
  // - Income: Realized if Paid OR Date <= Today (Presumption of receipt)
  // - Expense: Realized ONLY if Paid (Strict liquidity view)
  bool get isRealized {
    if (isPaid) return true;
    
    // User requested: If date <= Today, it is realized/performed.
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    return date.isBefore(tomorrow);
  }

  // Helper to check for Overdue status (Atrasado)
  // Only applies to Expenses that are NOT paid and date < today
  bool get isOverdue {
    if (!isExpense) return false;
    if (isPaid) return false;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Explicitly strictly before today (yesterday or older)
    return date.isBefore(today);
  }
}
