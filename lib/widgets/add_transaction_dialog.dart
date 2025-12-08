import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../services/database_service.dart';
import '../utils/localization.dart';
import '../utils/installment_helper.dart';

class AddTransactionDialog extends StatefulWidget {
  final VoidCallback onTransactionAdded;

  const AddTransactionDialog({
    super.key,
    required this.onTransactionAdded,
  });

  @override
  State<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> {
  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  
  // Installment controllers
  final TextEditingController _downPaymentController = TextEditingController(text: '0,00');
  final TextEditingController _installmentsCountController = TextEditingController();
  final TextEditingController _installmentAmountController = TextEditingController();

  bool _isExpense = true;
  bool _isInstallment = false;
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'Outras Despesas';
  String? _selectedSubcategory;
  List<Category> _categories = [];
  String _currentLanguage = 'pt_BR';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _dbService.init();
    final language = _dbService.getLanguage();
    setState(() {
      _currentLanguage = language;
    });
    _loadCategories();
  }

  String t(String key) => AppLocalizations.t(key, _currentLanguage);

  Future<void> _loadCategories() async {
    final categories = _dbService.getCategories(type: _isExpense ? 'expense' : 'income');
    setState(() {
      _categories = categories;
      if (!_categories.any((c) => c.name == _selectedCategory)) {
        if (_categories.isNotEmpty) {
          _selectedCategory = _categories.first.name;
          _selectedSubcategory = null;
        } else {
          _selectedCategory = '';
          _selectedSubcategory = null;
        }
      }
    });
  }

  double _calculateTotal() {
    if (!_isInstallment) return 0.0;
    final downPayment = double.tryParse(_downPaymentController.text.replaceAll(',', '.')) ?? 0.0;
    final count = int.tryParse(_installmentsCountController.text) ?? 0;
    final amount = double.tryParse(_installmentAmountController.text.replaceAll(',', '.')) ?? 0.0;
    return downPayment + (count * amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t('add_transaction')),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (_descriptionController.text.isEmpty || _selectedCategory.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(t('invalid_data'))),
                );
                return;
              }

              if (_isInstallment) {
                final downPayment = double.tryParse(_downPaymentController.text.replaceAll(',', '.')) ?? 0.0;
                final count = int.tryParse(_installmentsCountController.text);
                final amount = double.tryParse(_installmentAmountController.text.replaceAll(',', '.'));

                if (count == null || count < 2 || amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Dados de parcelamento inválidos')),
                  );
                  return;
                }

                final totalAmount = downPayment + (count * amount);
                
                final firstInstallmentDate = DateTime(
                  _selectedDate.year,
                  _selectedDate.month + 1,
                  _selectedDate.day,
                );

                final transactions = InstallmentHelper.createInstallments(
                  description: _descriptionController.text,
                  totalAmount: totalAmount,
                  installments: count,
                  firstInstallmentDate: firstInstallmentDate,
                  category: _selectedCategory,
                  subcategory: _selectedSubcategory,
                  isExpense: _isExpense,
                  downPayment: downPayment,
                  downPaymentDate: _selectedDate,
                );

                for (var transaction in transactions) {
                  await _dbService.addTransaction(transaction);
                }
              } else {
                final amount = double.tryParse(_amountController.text.replaceAll(',', '.'));
                if (amount == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(t('invalid_data'))),
                  );
                  return;
                }

                final now = DateTime.now();
                final isTodayOrPast = _selectedDate.isBefore(now) || 
                                     (_selectedDate.year == now.year && _selectedDate.month == now.month && _selectedDate.day == now.day);

                final newTransaction = Transaction(
                  id: const Uuid().v4(),
                  description: _descriptionController.text,
                  amount: amount,
                  isExpense: _isExpense,
                  date: _selectedDate,
                  category: _selectedCategory,
                  subcategory: _selectedSubcategory,
                  isPaid: isTodayOrPast,
                  paymentDate: isTodayOrPast ? _selectedDate : null,
                );

                await _dbService.addTransaction(newTransaction);
              }
              
              widget.onTransactionAdded();
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: Text(t('save'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: t('description'),
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            
            // Toggle Installment
            Card(
              child: SwitchListTile(
                title: Text(t('is_installment')),
                value: _isInstallment,
                onChanged: (value) {
                  setState(() {
                    _isInstallment = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),

            if (_isInstallment) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _downPaymentController,
                      decoration: InputDecoration(
                        labelText: t('down_payment'),
                        border: const OutlineInputBorder(),
                        prefixText: 'R\$ ',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _installmentsCountController,
                      decoration: InputDecoration(
                        labelText: t('installment_count'),
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _installmentAmountController,
                decoration: InputDecoration(
                  labelText: t('installment_amount'),
                  border: const OutlineInputBorder(),
                  prefixText: 'R\$ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              Text(
                '${t('total_calculated')} R\$ ${_calculateTotal().toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ] else
              TextField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: t('amount'),
                  border: const OutlineInputBorder(),
                  prefixText: 'R\$ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              
            const SizedBox(height: 16),
            Card(
              child: SwitchListTile(
                title: Text(t('is_expense')),
                subtitle: Text(_isExpense ? t('expense') : t('income')),
                value: _isExpense,
                onChanged: (value) {
                  setState(() {
                    _isExpense = value;
                    _loadCategories();
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                title: Text(t('date')),
                subtitle: Text(DateFormat('dd/MM/yyyy HH:mm', _currentLanguage).format(_selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) {
                    if (context.mounted) {
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
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
            if (_categories.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                value: _selectedCategory.isNotEmpty ? _selectedCategory : null,
                decoration: InputDecoration(
                  labelText: t('category'),
                  border: const OutlineInputBorder(),
                ),
                items: _categories.map((cat) {
                  return DropdownMenuItem(
                    value: cat.name,
                    child: Text(AppLocalizations.tCategory(cat.name, _currentLanguage)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                    _selectedSubcategory = null;
                  });
                },
              ),
              const SizedBox(height: 16),
              if (_categories.any((c) => c.name == _selectedCategory && c.subcategories.isNotEmpty))
                DropdownButtonFormField<String>(
                  value: _selectedSubcategory,
                  decoration: InputDecoration(
                    labelText: t('subcategory'),
                    border: const OutlineInputBorder(),
                  ),
                  items: _categories
                      .firstWhere((c) => c.name == _selectedCategory)
                      .subcategories
                      .map((sub) => DropdownMenuItem(
                            value: sub,
                            child: Text(AppLocalizations.tCategory(sub, _currentLanguage)),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSubcategory = value;
                    });
                  },
                ),
            ] else
              Text(t('no_categories')),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _downPaymentController.dispose();
    _installmentsCountController.dispose();
    _installmentAmountController.dispose();
    super.dispose();
  }
}
