import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/report_filter.dart';
import '../models/category_model.dart';
import '../services/database_service.dart';
import '../utils/localization.dart';

class AdvancedFiltersDialog extends StatefulWidget {
  final ReportFilter initialFilter;
  final String currentLanguage;

  const AdvancedFiltersDialog({
    super.key,
    required this.initialFilter,
    required this.currentLanguage,
  });

  @override
  State<AdvancedFiltersDialog> createState() => _AdvancedFiltersDialogState();
}

class _AdvancedFiltersDialogState extends State<AdvancedFiltersDialog> {
  late ReportFilter _filter;
  final DatabaseService _dbService = DatabaseService();
  List<Category> _allCategories = [];
  final TextEditingController _minValueController = TextEditingController();
  final TextEditingController _maxValueController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
    _loadCategories();
    
    if (_filter.minValue != null) {
      _minValueController.text = _filter.minValue!.toStringAsFixed(2);
    }
    if (_filter.maxValue != null) {
      _maxValueController.text = _filter.maxValue!.toStringAsFixed(2);
    }
  }

  Future<void> _loadCategories() async {
    await _dbService.init();
    final categories = _dbService.getCategories();
    setState(() {
      _allCategories = categories;
    });
  }

  String t(String key) => AppLocalizations.t(key, widget.currentLanguage);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.filter_list, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    t('advanced_filters'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPeriodSection(),
                    const Divider(height: 32),
                    _buildCategoriesSection(),
                    const Divider(height: 32),
                    _buildValuesSection(),
                    const Divider(height: 32),
                    _buildTypeSection(),
                  ],
                ),
              ),
            ),
            
            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _filter = ReportFilter();
                        _minValueController.clear();
                        _maxValueController.clear();
                      });
                    },
                    child: Text(t('clear_filters')),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, _filter),
                    child: Text(t('apply_filters')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.calendar_today, size: 20, color: Colors.blue),
            SizedBox(width: 8),
            Text(
              t('period_label').replaceAll(': ', ''),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildPeriodChip(t('period_month'), 'MONTH'),
            _buildPeriodChip(t('period_quarter'), 'QUARTER'),
            _buildPeriodChip(t('period_year'), 'YEAR'),
            _buildPeriodChip(t('period_last_7'), 'LAST_7'),
            _buildPeriodChip(t('period_last_30'), 'LAST_30'),
            _buildPeriodChip(t('period_last_90'), 'LAST_90'),
            _buildPeriodChip(t('period_custom'), 'CUSTOM'),
          ],
        ),
        if (_filter.periodType == 'CUSTOM') ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ListTile(
                  title: Text(t('start_date'), style: const TextStyle(fontSize: 12)),
                  subtitle: Text(
                    _filter.startDate != null
                        ? DateFormat('dd/MM/yyyy').format(_filter.startDate!)
                        : t('select'),
                  ),
                  trailing: const Icon(Icons.calendar_today, size: 20),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _filter.startDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        _filter = _filter.copyWith(startDate: date);
                      });
                    }
                  },
                ),
              ),
              Expanded(
                child: ListTile(
                  title: Text(t('end_date'), style: const TextStyle(fontSize: 12)),
                  subtitle: Text(
                    _filter.endDate != null
                        ? DateFormat('dd/MM/yyyy').format(_filter.endDate!)
                        : t('select'),
                  ),
                  trailing: const Icon(Icons.calendar_today, size: 20),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _filter.endDate ?? DateTime.now(),
                      firstDate: _filter.startDate ?? DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        _filter = _filter.copyWith(endDate: date);
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPeriodChip(String label, String value) {
    final isSelected = _filter.periodType == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filter = _filter.copyWith(periodType: value);
        });
      },
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.category, size: 20, color: Colors.blue),
            SizedBox(width: 8),
            Text(
              t('categories_subcategories'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Categories
        Text(t('categories_label'), style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _allCategories.map((category) {
            final isSelected = _filter.selectedCategories.contains(category.name);
            return FilterChip(
              label: Text(AppLocalizations.tCategory(category.name, widget.currentLanguage)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  final newCategories = List<String>.from(_filter.selectedCategories);
                  if (selected) {
                    newCategories.add(category.name);
                  } else {
                    newCategories.remove(category.name);
                    // Remove subcategories of this category
                    final newSubcategories = List<String>.from(_filter.selectedSubcategories);
                    newSubcategories.removeWhere((sub) => category.subcategories.contains(sub));
                    _filter = _filter.copyWith(selectedSubcategories: newSubcategories);
                  }
                  _filter = _filter.copyWith(selectedCategories: newCategories);
                });
              },
            );
          }).toList(),
        ),
        
        // Subcategories (only for selected categories)
        if (_filter.selectedCategories.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(t('subcategories_label'), style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          ..._filter.selectedCategories.map((categoryName) {
            final category = _allCategories.firstWhere((c) => c.name == categoryName);
            if (category.subcategories.isEmpty) return const SizedBox.shrink();
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.tCategory(categoryName, widget.currentLanguage),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: category.subcategories.map((subcategory) {
                    final isSelected = _filter.selectedSubcategories.contains(subcategory);
                    return FilterChip(
                      label: Text(
                        AppLocalizations.tCategory(subcategory, widget.currentLanguage),
                        style: const TextStyle(fontSize: 12),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          final newSubcategories = List<String>.from(_filter.selectedSubcategories);
                          if (selected) {
                            newSubcategories.add(subcategory);
                          } else {
                            newSubcategories.remove(subcategory);
                          }
                          _filter = _filter.copyWith(selectedSubcategories: newSubcategories);
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
              ],
            );
          }).toList(),
        ],
      ],
    );
  }

  Widget _buildValuesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.attach_money, size: 20, color: Colors.blue),
            SizedBox(width: 8),
            Text(
              t('value_range'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _minValueController,
                decoration: InputDecoration(
                  labelText: t('min_value'),
                  prefixText: 'R\$ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) {
                  final parsed = double.tryParse(value.replaceAll(',', '.'));
                  _filter = _filter.copyWith(minValue: parsed);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _maxValueController,
                decoration: InputDecoration(
                  labelText: t('max_value'),
                  prefixText: 'R\$ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) {
                  final parsed = double.tryParse(value.replaceAll(',', '.'));
                  _filter = _filter.copyWith(maxValue: parsed);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.swap_vert, size: 20, color: Colors.blue),
            SizedBox(width: 8),
            Text(
              t('transaction_type'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          title: Text(t('expenses')),
          value: _filter.includeExpenses,
          onChanged: (value) {
            setState(() {
              _filter = _filter.copyWith(includeExpenses: value);
            });
          },
        ),
        CheckboxListTile(
          title: Text(t('income')),
          value: _filter.includeIncome,
          onChanged: (value) {
            setState(() {
              _filter = _filter.copyWith(includeIncome: value);
            });
          },
        ),
        CheckboxListTile(
          title: Text(t('installments')),
          value: _filter.includeInstallments,
          onChanged: (value) {
            setState(() {
              _filter = _filter.copyWith(includeInstallments: value);
            });
          },
        ),
        CheckboxListTile(
          title: Text(t('single_payments')),
          value: _filter.includeSinglePayments,
          onChanged: (value) {
            setState(() {
              _filter = _filter.copyWith(includeSinglePayments: value);
            });
          },
        ),
        CheckboxListTile(
          title: Text(t('exclude_reversals')),
          value: _filter.excludeReversals,
          onChanged: (value) {
            setState(() {
              _filter = _filter.copyWith(excludeReversals: value);
            });
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _minValueController.dispose();
    _maxValueController.dispose();
    super.dispose();
  }
}
