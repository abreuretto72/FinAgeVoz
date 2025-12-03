import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../services/database_service.dart';
import '../services/import_service.dart';
import '../utils/localization.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> with SingleTickerProviderStateMixin {
  final DatabaseService _dbService = DatabaseService();
  late TabController _tabController;
  List<Category> _categories = [];
  
  String get _currentLanguage => Localizations.localeOf(context).toString();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCategories();
  }

  String t(String key) => AppLocalizations.t(key, _currentLanguage);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    await _dbService.init();
    final language = _dbService.getLanguage();
    setState(() {
      // _currentLanguage = language; // No longer needed
      _categories = _dbService.getCategories();
    });
  }

  Future<void> _addCategory() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String selectedType = _tabController.index == 0 ? 'expense' : 'income';

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(t('add_category')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: t('category_name_label')),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descController,
                    decoration: InputDecoration(labelText: t('category_desc_label')),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: InputDecoration(labelText: t('type')),
                    items: [
                      DropdownMenuItem(value: 'expense', child: Text(t('expense'))),
                      DropdownMenuItem(value: 'income', child: Text(t('income'))),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedType = value;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text(t('cancel'))),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final desc = descController.text.trim();
                    if (name.isNotEmpty) {
                      await _dbService.addCategory(Category(
                        name: name, 
                        description: desc,
                        type: selectedType,
                      ));
                      await _loadCategories();
                    }
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Text(t('save')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteCategory(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('delete_category')),
        content: Text(t('confirm_delete')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t('delete')),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await _dbService.deleteCategory(index);
    if (!success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('delete_category_error'))));
      }
    }
    await _loadCategories();
  }

  Future<void> _addSubcategory(Category category) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${t('new_subcategory_title')}${category.name}'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: t('subcategory_name_label')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(t('cancel'))),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                category.subcategories.add(controller.text.trim());
                await category.save(); 
                setState(() {});
                if (mounted) Navigator.pop(context);
              }
            },
            child: Text(t('save')),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSubcategory(Category category, String subcategory) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('delete_subcategory')),
        content: Text(t('confirm_delete')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t('delete')),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    category.subcategories.remove(subcategory);
    await category.save();
    setState(() {});
  }

  Widget _buildCategoryList(String type) {
    final filtered = _categories.where((c) => c.type == type).toList();
    if (filtered.isEmpty) {
      return Center(child: Text(t('no_categories')));
    }
    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, i) {
        final cat = filtered[i];
        // We need the original index for deletion, which is tricky with a filtered list.
        // Ideally DatabaseService should expose delete by ID or object, but it uses index.
        // For now, we find the index in the main list.
        final originalIndex = _categories.indexOf(cat);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ExpansionTile(
            title: Text(AppLocalizations.tCategory(cat.name, _currentLanguage), style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(cat.description, maxLines: 1, overflow: TextOverflow.ellipsis),
            leading: Icon(type == 'expense' ? Icons.money_off : Icons.attach_money, 
                color: type == 'expense' ? Colors.red : Colors.green),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.blue),
                  onPressed: () => _addSubcategory(cat),
                  tooltip: t('add_subcategory_tooltip'),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteCategory(originalIndex),
                  tooltip: t('delete_category'),
                ),
                const Icon(Icons.expand_more),
              ],
            ),
            children: cat.subcategories.map((sub) {
              return ListTile(
                dense: true,
                leading: const Icon(Icons.subdirectory_arrow_right, size: 16),
                title: Text(AppLocalizations.tCategory(sub, _currentLanguage)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, size: 18),
                  onPressed: () => _deleteSubcategory(cat, sub),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t('categories_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: t('export_csv'),
            onPressed: () async {
              try {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(child: CircularProgressIndicator()),
                );
                
                final importService = ImportService();
                await importService.exportCategoriesToCsv();
                
                if (mounted) Navigator.pop(context); // Close loading
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(t('categories_exported_success')), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (mounted) Navigator.pop(context); // Close loading
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${t('error_export')}$e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: t('tab_expense'), icon: const Icon(Icons.money_off)),
            Tab(text: t('tab_income'), icon: const Icon(Icons.attach_money)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCategoryList('expense'),
          _buildCategoryList('income'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCategory,
        tooltip: t('add_category'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
