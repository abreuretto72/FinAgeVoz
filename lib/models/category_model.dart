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

  Category({
    required this.name,
    required this.description,
    this.subcategories = const [],
    this.type = 'expense', // Default to expense for backward compatibility (though we recommend reinstall)
  });
}
