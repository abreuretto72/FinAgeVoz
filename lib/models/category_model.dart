import 'package:hive/hive.dart';

part 'category_model.g.dart';

@HiveType(typeId: 3)
class Category extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String description;

  @HiveField(2)
  List<String> subcategories;

  @HiveField(3)
  String type; // 'income' or 'expense'

  @HiveField(4)
  final String id;

  @HiveField(5)
  final DateTime? updatedAt;

  @HiveField(6)
  final bool isDeleted;

  @HiveField(7)
  final bool isSynced;

  Category({
    required this.name,
    required this.description,
    this.subcategories = const [],
    this.type = 'expense',
    String? id,
    DateTime? updatedAt,
    this.isDeleted = false,
    this.isSynced = false,
  }) : id = id ?? name.toLowerCase().replaceAll(' ', '_'), // Fallback ID for existing items
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'subcategories': subcategories,
      'type': type,
      'updatedAt': updatedAt?.toIso8601String(),
      'isDeleted': isDeleted,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      subcategories: List<String>.from(map['subcategories'] ?? []),
      type: map['type'] ?? 'expense',
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      isDeleted: map['isDeleted'] ?? false,
      isSynced: true,
    );
  }
}
