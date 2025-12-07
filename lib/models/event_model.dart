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

  @HiveField(8)
  final DateTime? updatedAt;

  @HiveField(9)
  final bool isDeleted;

  @HiveField(10)
  final bool isSynced;

  @HiveField(11)
  final int reminderMinutes; // Minutes before event to remind (Default 30)

  Event({
    required this.id,
    required this.title,
    required this.date,
    required this.description,
    this.isCancelled = false,
    this.recurrence,
    this.lastNotifiedDate,
    this.attachments,
    DateTime? updatedAt,
    this.isDeleted = false,
    this.isSynced = false,
    this.reminderMinutes = 30,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'description': description,
      'isCancelled': isCancelled,
      'recurrence': recurrence,
      'lastNotifiedDate': lastNotifiedDate?.toIso8601String(),
      'attachments': attachments,
      'updatedAt': updatedAt?.toIso8601String(),
      'isDeleted': isDeleted,
      'reminderMinutes': reminderMinutes,
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'],
      title: map['title'],
      date: DateTime.parse(map['date']),
      description: map['description'],
      isCancelled: map['isCancelled'] ?? false,
      recurrence: map['recurrence'],
      lastNotifiedDate: map['lastNotifiedDate'] != null ? DateTime.parse(map['lastNotifiedDate']) : null,
      attachments: map['attachments'] != null ? List<String>.from(map['attachments']) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      isDeleted: map['isDeleted'] ?? false,
      isSynced: true,
      reminderMinutes: map['reminderMinutes'] ?? 30,
    );
  }
}
