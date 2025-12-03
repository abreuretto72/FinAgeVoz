import 'package:hive/hive.dart';

part 'operation_history.g.dart';

@HiveType(typeId: 4)
class OperationHistory extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String type; // 'transaction', 'installment', 'event', 'event_edit'

  @HiveField(2)
  final List<String> transactionIds; // IDs das transações criadas

  @HiveField(3)
  final String description;

  @HiveField(4)
  final DateTime timestamp;

  @HiveField(5)
  final int? installmentCount; // Número de parcelas (se for parcelamento)

  @HiveField(6)
  final double? totalAmount; // Valor total (se for parcelamento)

  @HiveField(7)
  final String? eventId; // ID do evento (se for operação de evento)

  @HiveField(8)
  final Map<String, dynamic>? eventSnapshot; // Snapshot do evento antes da edição

  OperationHistory({
    required this.id,
    required this.type,
    required this.transactionIds,
    required this.description,
    required this.timestamp,
    this.installmentCount,
    this.totalAmount,
    this.eventId,
    this.eventSnapshot,
  });

  // Helper to get display text
  String get displayText {
    if (type == 'installment') {
      return '$description - $installmentCount parcelas';
    } else if (type == 'event') {
      return 'Evento: $description';
    } else if (type == 'event_edit') {
      return 'Edição de evento: $description';
    } else if (type == 'call') {
      return 'Ligação: $description';
    }
    return description;
  }

  // Helper to check if this is an installment operation
  bool get isInstallment => type == 'installment';
  
  // Helper to check if this is an event operation
  bool get isEvent => type == 'event' || type == 'event_edit';
}
