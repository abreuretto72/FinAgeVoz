import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../services/database_service.dart';
import '../utils/localization.dart';

class EditTransactionDialog extends StatefulWidget {
  final Transaction transaction;
  final DatabaseService dbService;
  final String currentLanguage;

  const EditTransactionDialog({
    required this.transaction,
    required this.dbService,
    required this.currentLanguage,
  });

  @override
  State<EditTransactionDialog> createState() => _EditTransactionDialogState();
}

class _EditTransactionDialogState extends State<EditTransactionDialog> {
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  late bool _isExpense;
  late DateTime _selectedDate;
  late String _selectedCategory;
  String? _selectedSubcategory;
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.transaction.description);
    // Show absolute amount for editing, handle sign on save
    _amountController = TextEditingController(text: widget.transaction.amount.abs().toString());
    _isExpense = widget.transaction.isExpense;
    _selectedDate = widget.transaction.date;
    _selectedCategory = widget.transaction.category;
    _selectedSubcategory = widget.transaction.subcategory;
    _loadCategories();
  }

  String t(String key) => AppLocalizations.t(key, widget.currentLanguage);

  Future<void> _loadCategories() async {
    await widget.dbService.init();
    final categories = widget.dbService.getCategories(type: _isExpense ? 'expense' : 'income');
    setState(() {
      _categories = categories;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text(t('edit')),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(labelText: t('description')),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            decoration: InputDecoration(labelText: t('amount')),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text(t('is_expense')),
            value: _isExpense,
            onChanged: (value) {
              setState(() {
                _isExpense = value;
                _loadCategories();
              });
            },
          ),
          const SizedBox(height: 16),
          ListTile(
            title: Text(t('date')),
            subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(_selectedDate)),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (date != null) {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(_selectedDate),
                );
                if (time != null) {
                  setState(() {
                    _selectedDate = DateTime(
                      date.year,
                      date.month,
                      date.day,
                      time.hour,
                      time.minute,
                    );
                  });
                }
              }
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            isExpanded: true,
            value: _selectedCategory,
            decoration: InputDecoration(labelText: t('category')),
            items: _categories.map((cat) {
              return DropdownMenuItem(
                value: cat.name,
                child: Text(AppLocalizations.tCategory(cat.name, widget.currentLanguage)),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCategory = value!;
                _selectedSubcategory = null;
              });
            },
          ),
          if (_categories.any((c) => c.name == _selectedCategory && c.subcategories.isNotEmpty))
            DropdownButtonFormField<String>(
              isExpanded: true,
              value: _selectedSubcategory,
              decoration: InputDecoration(labelText: t('subcategory')),
              items: _categories
                  .firstWhere((c) => c.name == _selectedCategory)
                  .subcategories
                  .map((sub) => DropdownMenuItem(value: sub, child: Text(AppLocalizations.tCategory(sub, widget.currentLanguage))))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSubcategory = value;
                });
              },
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t('cancel')),
        ),
        TextButton(
          onPressed: () {
            final amount = double.tryParse(_amountController.text);
            if (amount == null || _descriptionController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(t('invalid_data'))),
              );
              return;
            }
            // Algebraic v2: Determine sign
            double finalAmount = amount!.abs();
            if (_isExpense) {
              if (widget.transaction.isReversal) {
                // Reversal of Expense -> Positive
                finalAmount = finalAmount;
              } else {
                // Normal Expense -> Negative
                finalAmount = -finalAmount;
              }
            } else {
              if (widget.transaction.isReversal) {
                // Reversal of Income -> Negative
                finalAmount = -finalAmount;
              } else {
                // Normal Income -> Positive
                finalAmount = finalAmount;
              }
            }

            Navigator.pop(context, {
              'description': _descriptionController.text,
              'amount': finalAmount,
              'isExpense': _isExpense,
              'date': _selectedDate,
              'category': _selectedCategory,
              'subcategory': _selectedSubcategory,
            });
          },
          child: Text(t('save')),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}
