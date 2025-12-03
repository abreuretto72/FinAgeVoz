import 'package:hive/hive.dart';

part 'event_model.g.dart';

@HiveType(typeId: 1)
class Event extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final DateTime date;

  @HiveField(3)
  final String description;

  @HiveField(4)
  final bool isCancelled;

  @HiveField(5)
  final String? recurrence; // 'DAILY', 'WEEKLY', 'MONTHLY', 'YEARLY', 'NONE'

  @HiveField(6)
  final DateTime? lastNotifiedDate; // Data da última notificação ao usuário

  @HiveField(7)
  final List<String>? attachments;

  Event({
    required this.id,
    required this.title,
    required this.date,
    required this.description,
    this.isCancelled = false,
    this.recurrence,
    this.lastNotifiedDate,
    this.attachments,
  });
}
