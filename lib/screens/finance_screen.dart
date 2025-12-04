import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../services/database_service.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../services/pdf_service.dart';
import '../utils/localization.dart';
import '../widgets/edit_transaction_dialog.dart';
import '../widgets/add_transaction_dialog.dart';
import '../widgets/attachments_dialog.dart';
import 'package:url_launcher/url_launcher.dart';
import 'pdf_preview_screen.dart';

enum TransactionType { all, income, expense }
enum FilterPeriod { today, thisWeek, thisMonth, all }
enum SortBy { date, amount, type, description }

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<Transaction> _transactions = [];
  List<Transaction> _filteredTransactions = [];
  
  FilterPeriod _selectedPeriod = FilterPeriod.thisMonth;
  DateTime? _selectedDate;
  TransactionType _selectedType = TransactionType.all;
  String _searchQuery = '';
  SortBy _sortBy = SortBy.date;
  bool _isAscending = false;
  bool _showOnlyWithAttachments = false;
  bool _isSearching = false;
  double _filteredBalance = 0;
  
  String get _currentLanguage => Localizations.localeOf(context).toString();

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String t(String key) => AppLocalizations.t(key, _currentLanguage);

  Future<void> _loadData() async {
    await _dbService.init();
    final transactions = _dbService.getTransactions();
    final language = _dbService.getLanguage();
    
    setState(() {
      // _currentLanguage = language; // No longer needed
      _transactions = transactions;
      _applyFilters();
    });
  }

  void _applyFilters() {
    final now = DateTime.now();
    _filteredTransactions = _transactions.where((transaction) {
      // Period filter
      bool matchesPeriod = true;
      if (_selectedDate == null) {
        switch (_selectedPeriod) {
          case FilterPeriod.today:
            matchesPeriod = transaction.date.year == now.year &&
                transaction.date.month == now.month &&
                transaction.date.day == now.day;
            break;
          case FilterPeriod.thisWeek:
            final weekStart = now.subtract(Duration(days: now.weekday - 1));
            final weekEnd = weekStart.add(const Duration(days: 6));
            matchesPeriod = transaction.date.isAfter(weekStart.subtract(const Duration(days: 1))) &&
                transaction.date.isBefore(weekEnd.add(const Duration(days: 1)));
            break;
          case FilterPeriod.thisMonth:
            matchesPeriod = transaction.date.year == now.year && transaction.date.month == now.month;
            break;
          case FilterPeriod.all:
            matchesPeriod = true;
            break;
        }
      } else {
        matchesPeriod = transaction.date.year == _selectedDate!.year &&
            transaction.date.month == _selectedDate!.month &&
            transaction.date.day == _selectedDate!.day;
      }

      // Type filter
      bool matchesType = true;
      switch (_selectedType) {
        case TransactionType.income:
          matchesType = !transaction.isExpense;
          break;
        case TransactionType.expense:
          matchesType = transaction.isExpense;
          break;
        case TransactionType.all:
          matchesType = true;
          break;
      }

      // Search filter
      bool matchesSearch = true;
      if (_searchQuery.isNotEmpty) {
        matchesSearch = transaction.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            transaction.category.toLowerCase().contains(_searchQuery.toLowerCase());
      }

      // Attachments filter
      bool matchesAttachments = true;
      if (_showOnlyWithAttachments) {
        matchesAttachments = transaction.attachments != null && transaction.attachments!.isNotEmpty;
      }

      return matchesPeriod && matchesType && matchesSearch && matchesAttachments;
    }).toList();

    // Calculate balance
    _filteredBalance = 0;
    for (var t in _filteredTransactions) {
      // Pure summation logic (Algebraic v2)
      _filteredBalance += t.amount;
    }

    _sortTransactions();
  }

  void _sortTransactions() {
    switch (_sortBy) {
      case SortBy.date:
        _filteredTransactions.sort((a, b) => 
          _isAscending ? a.date.compareTo(b.date) : b.date.compareTo(a.date));
        break;
      case SortBy.amount:
        _filteredTransactions.sort((a, b) => 
          _isAscending ? a.amount.compareTo(b.amount) : b.amount.compareTo(a.amount));
        break;
      case SortBy.type:
        _filteredTransactions.sort((a, b) {
          final aValue = a.isExpense ? 1 : 0;
          final bValue = b.isExpense ? 1 : 0;
          return _isAscending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
        });
        break;
      case SortBy.description:
        _filteredTransactions.sort((a, b) => 
          _isAscending ? a.description.compareTo(b.description) : b.description.compareTo(a.description));
        break;
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedPeriod = FilterPeriod.all;
        _applyFilters();
      });
    }
  }

  bool _isSelectionMode = false;
  final Set<String> _selectedTransactionIds = {};

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectedTransactionIds.clear();
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedTransactionIds.contains(id)) {
        _selectedTransactionIds.remove(id);
        if (_selectedTransactionIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedTransactionIds.add(id);
      }
    });
  }

  Future<void> _shareOnWhatsApp() async {
    if (_selectedTransactionIds.isEmpty) return;

    final selectedTransactions = _transactions
        .where((t) => _selectedTransactionIds.contains(t.id))
        .toList();

    if (selectedTransactions.isEmpty) return;

    final buffer = StringBuffer();
    buffer.writeln("*Minhas Transações - FinAgeVoz*");
    buffer.writeln("");

    double total = 0;
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat = NumberFormat.simpleCurrency(locale: 'pt_BR');

    for (var t in selectedTransactions) {
      buffer.writeln("📅 ${dateFormat.format(t.date)}");
      buffer.writeln("📝 ${t.description}");
      buffer.writeln("💰 ${currencyFormat.format(t.amount)} (${t.isExpense ? 'Despesa' : 'Receita'})");
      buffer.writeln("");
      
      total += t.amount;
    }

    buffer.writeln("*Total Selecionado: ${currencyFormat.format(total)}*");

    final text = Uri.encodeComponent(buffer.toString());
    final url = Uri.parse("https://wa.me/?text=$text");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t('whatsapp_error'))),
        );
      }
    }
    
    // Exit selection mode after sharing
    setState(() {
      _isSelectionMode = false;
      _selectedTransactionIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    String locale = _currentLanguage;
    if (locale == 'pt_BR') locale = 'pt_BR';
    else if (locale == 'pt_PT') locale = 'pt_PT';
    else if (locale == 'en') locale = 'en_US';
    else if (locale == 'es') locale = 'es_ES';
    else if (locale == 'de') locale = 'de_DE';
    else if (locale == 'hi') locale = 'hi_IN';
    else if (locale == 'zh') locale = 'zh_CN';
    else if (locale == 'it') locale = 'it_IT';
    else if (locale == 'fr') locale = 'fr_FR';
    else if (locale == 'ja') locale = 'ja_JP';
    else if (locale == 'ar') locale = 'ar_SA';
    else if (locale == 'bn') locale = 'bn_IN';
    else if (locale == 'ru') locale = 'ru_RU';
    else if (locale == 'id') locale = 'id_ID';

    final currencyFormat = NumberFormat.simpleCurrency(locale: locale);
    final dateFormat = DateFormat('dd/MM/yyyy', locale);

    return Scaffold(
      appBar: AppBar(
        leading: _isSelectionMode 
          ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: _toggleSelectionMode,
            )
          : (_isSearching 
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() {
                      _isSearching = false;
                      _searchQuery = '';
                      _searchController.clear();
                      _applyFilters();
                    });
                  },
                )
              : null),
        title: _isSelectionMode 
          ? Text('${_selectedTransactionIds.length} selecionados')
          : (_isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: t('search_hint'),
                    border: InputBorder.none,
                    hintStyle: const TextStyle(color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _applyFilters();
                    });
                  },
                )
              : Text(t('nav_finance'))),
        actions: [
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.share, color: Colors.green),
              tooltip: 'Enviar para WhatsApp',
              onPressed: _shareOnWhatsApp,
            )
          else ...[

            if (!_isSearching)
              IconButton(
                icon: const Icon(Icons.search),
                tooltip: t('search_hint'),
                onPressed: () {
                  setState(() {
                    _isSearching = true;
                  });
                },
              ),
            IconButton(
              icon: const Icon(Icons.filter_alt_off),
              tooltip: t('clear_filters'),
              onPressed: () {
                setState(() {
                  _selectedPeriod = FilterPeriod.all;
                  _selectedType = TransactionType.all;
                  _selectedDate = null;
                  _searchQuery = '';
                  _showOnlyWithAttachments = false;
                  _searchController.clear();
                  _isSearching = false;
                  _applyFilters();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(t('filters_cleared')), duration: const Duration(seconds: 1)),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.share, color: Colors.green),
              tooltip: t('share_report'),
              onPressed: () async {
                try {
                  await PdfService.shareTransactionsPdf(
                    _filteredTransactions,
                    currencyFormat,
                    dateFormat,
                    _filteredBalance,
                    _currentLanguage,
                  );
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${t('error')}: $e')),
                    );
                  }
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: () async {
                try {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PdfPreviewScreen(
                        title: t('transactions_report_title'),
                        buildPdf: (format) => PdfService.generateTransactionsPdfBytes(
                          _filteredTransactions,
                          currencyFormat,
                          dateFormat,
                          _filteredBalance,
                          _currentLanguage,
                        ),
                      ),
                    ),
                  );
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${t('error')}: $e')),
                    );
                  }
                }
              },
            ),
            PopupMenuButton<SortBy>(
              initialValue: _sortBy,
              onSelected: (SortBy value) {
                setState(() {
                  _sortBy = value;
                  _applyFilters();
                });
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<SortBy>>[
                PopupMenuItem<SortBy>(
                  value: SortBy.date,
                  child: Row(children: [
                     Icon(Icons.calendar_today, size: 20, color: _sortBy == SortBy.date ? Theme.of(context).colorScheme.primary : null),
                     const SizedBox(width: 8),
                     Text(t('date')),
                  ]),
                ),
                PopupMenuItem<SortBy>(
                  value: SortBy.amount,
                  child: Row(children: [
                     Icon(Icons.attach_money, size: 20, color: _sortBy == SortBy.amount ? Theme.of(context).colorScheme.primary : null),
                     const SizedBox(width: 8),
                     Text(t('amount')),
                  ]),
                ),
                PopupMenuItem<SortBy>(
                  value: SortBy.type,
                  child: Row(children: [
                     Icon(Icons.category, size: 20, color: _sortBy == SortBy.type ? Theme.of(context).colorScheme.primary : null),
                     const SizedBox(width: 8),
                     Text(t('type')),
                  ]),
                ),
              ],
            ),
            IconButton(
              icon: Icon(_isAscending ? Icons.arrow_upward : Icons.arrow_downward),
              tooltip: _isAscending ? "Ordem crescente" : "Ordem decrescente",
              onPressed: () {
                setState(() {
                  _isAscending = !_isAscending;
                  _applyFilters();
                });
              },
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Balance Card (Compact)
          Card(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t('balance_total'), style: const TextStyle(fontSize: 14)),
                      Text(
                        currencyFormat.format(_filteredBalance),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _filteredBalance >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    "${_filteredTransactions.length} ${t('transactions_count_label')}",
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),

          // Unified Filters Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                // 1. All (Type)
                FilterChip(
                  label: Text(t('filter_all')),
                  selected: _selectedType == TransactionType.all,
                  onSelected: (selected) {
                    setState(() {
                      _selectedType = TransactionType.all;
                      _applyFilters();
                    });
                  },
                ),
                const SizedBox(width: 8),

                // 2. Month (Period)
                ChoiceChip(
                  label: Text(t('period_month')),
                  selected: _selectedPeriod == FilterPeriod.thisMonth && _selectedDate == null,
                  onSelected: (selected) {
                    setState(() {
                      _selectedPeriod = FilterPeriod.thisMonth;
                      _selectedDate = null;
                      _applyFilters();
                    });
                  },
                ),
                const SizedBox(width: 8),

                // 3. Income (Type)
                FilterChip(
                  label: Text(t('income')),
                  selected: _selectedType == TransactionType.income,
                  onSelected: (selected) {
                    setState(() {
                      _selectedType = TransactionType.income;
                      _applyFilters();
                    });
                  },
                ),
                const SizedBox(width: 8),

                // 4. Expense (Type)
                FilterChip(
                  label: Text(t('expenses')),
                  selected: _selectedType == TransactionType.expense,
                  onSelected: (selected) {
                    setState(() {
                      _selectedType = TransactionType.expense;
                      _applyFilters();
                    });
                  },
                ),
                const SizedBox(width: 8),

                // 5. Today (Period)
                ChoiceChip(
                  label: Text(t('period_today')),
                  selected: _selectedPeriod == FilterPeriod.today && _selectedDate == null,
                  onSelected: (selected) {
                    setState(() {
                      _selectedPeriod = FilterPeriod.today;
                      _selectedDate = null;
                      _applyFilters();
                    });
                  },
                ),
                const SizedBox(width: 8),

                // 6. Week (Period)
                ChoiceChip(
                  label: Text(t('period_week')),
                  selected: _selectedPeriod == FilterPeriod.thisWeek && _selectedDate == null,
                  onSelected: (selected) {
                    setState(() {
                      _selectedPeriod = FilterPeriod.thisWeek;
                      _selectedDate = null;
                      _applyFilters();
                    });
                  },
                ),
                const SizedBox(width: 8),

                // 7. Date Picker
                ActionChip(
                  avatar: const Icon(Icons.calendar_today, size: 16),
                  label: Text(_selectedDate == null 
                      ? t('select_date') 
                      : dateFormat.format(_selectedDate!)),
                  onPressed: _pickDate,
                ),
                if (_selectedDate != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        setState(() {
                          _selectedDate = null;
                          _applyFilters();
                        });
                      },
                    ),
                  ),
                const SizedBox(width: 8),
                
                // 8. Attachments Filter
                FilterChip(
                  avatar: const Icon(Icons.attach_file, size: 16),
                  label: Text(t('filter_attachments')),
                  selected: _showOnlyWithAttachments,
                  onSelected: (selected) {
                    setState(() {
                      _showOnlyWithAttachments = selected;
                      _applyFilters();
                    });
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 4),

          // List
          Expanded(
            child: _filteredTransactions.isEmpty
                ? Center(child: Text(t('no_transactions')))
                : ListView.builder(
                    itemCount: _filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final transaction = _filteredTransactions[index];
                      final transactionIndex = _transactions.indexOf(transaction);
                      final isSelected = _selectedTransactionIds.contains(transaction.id);

                      return ListTile(
                        selected: isSelected,
                        selectedTileColor: Colors.blue.withOpacity(0.1),
                        leading: _isSelectionMode
                          ? Checkbox(
                              value: isSelected,
                              onChanged: (value) => _toggleSelection(transaction.id),
                            )
                          : CircleAvatar(
                              backgroundColor: transaction.isReversal 
                                  ? Colors.orange[100] 
                                  : (transaction.isExpense ? Colors.red[100] : Colors.green[100]),
                              child: (transaction.attachments != null && transaction.attachments!.isNotEmpty)
                                  ? Text(
                                      String.fromCharCode(Icons.attach_file.codePoint),
                                      style: TextStyle(
                                        fontFamily: Icons.attach_file.fontFamily,
                                        package: Icons.attach_file.fontPackage,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: transaction.isExpense ? Colors.red : Colors.green,
                                      ),
                                    )
                                  : Icon(
                                      transaction.isReversal 
                                          ? Icons.undo 
                                          : (transaction.isExpense ? Icons.arrow_downward : Icons.arrow_upward),
                                      color: transaction.isReversal 
                                          ? Colors.orange 
                                          : (transaction.isExpense ? Colors.red : Colors.green),
                                    ),
                            ),
                        title: Text(
                          transaction.isInstallment 
                            ? '${transaction.description} (${transaction.installmentText})'
                            : transaction.description
                        ),
                        subtitle: Text('${AppLocalizations.tCategory(transaction.category, _currentLanguage)} • ${dateFormat.format(transaction.date)}'),
                        trailing: Text(
                          currencyFormat.format(transaction.amount),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: transaction.isExpense ? Colors.red : Colors.green,
                          ),
                        ),
                        onLongPress: () {
                          if (!_isSelectionMode) {
                            _toggleSelectionMode();
                            _toggleSelection(transaction.id);
                          }
                        },
                        onTap: () {
                          if (_isSelectionMode) {
                            _toggleSelection(transaction.id);
                            return;
                          }
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(transaction.description),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${t('amount')}: ${currencyFormat.format(transaction.amount)}'),
                                  Text('${t('date')}: ${dateFormat.format(transaction.date)}'),
                                  Text('${t('category')}: ${AppLocalizations.tCategory(transaction.category, _currentLanguage)}'),
                                  if (transaction.subcategory?.isNotEmpty ?? false)
                                    Text('${t('subcategory')}: ${AppLocalizations.tCategory(transaction.subcategory!, _currentLanguage)}'),
                                  Text('${t('type')}: ${transaction.isExpense ? t('expense') : t('income')}'),
                                ],
                              ),
                              actions: [
                                if (!transaction.isReversal)
                                  TextButton.icon(
                                    icon: const Icon(Icons.undo),
                                    label: Text(t('reverse')),
                                    onPressed: () async {
                                      Navigator.pop(context);
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text(t('reverse')),
                                          content: Text('${t('confirm_reverse')}: ${transaction.description}?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, false),
                                              child: Text(t('cancel')),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, true),
                                              child: Text(t('reverse')),
                                            ),
                                          ],
                                        ),
                                      );
                                      
                                      if (confirm == true) {
                                        final reversalTransaction = Transaction(
                                          id: const Uuid().v4(),
                                          description: '${t('reversal_of')} ${transaction.description}',
                                          amount: -transaction.amount,
                                          isExpense: transaction.isExpense,
                                          date: DateTime.now(),
                                          category: transaction.category,
                                          subcategory: transaction.subcategory,
                                          isReversal: true,
                                          originalTransactionId: transaction.id,
                                        );
                                        await _dbService.addTransaction(reversalTransaction);
                                        _loadData();
                                      }
                                    },
                                  ),
                                TextButton.icon(
                                  icon: const Icon(Icons.attach_file),
                                  label: Text(t('attachments_label')),
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    await showDialog(
                                      context: context,
                                      builder: (context) => AttachmentsDialog(
                                        initialAttachments: transaction.attachments ?? [],
                                        onSave: (updatedAttachments) async {
                                          final updatedTransaction = Transaction(
                                            id: transaction.id,
                                            description: transaction.description,
                                            amount: transaction.amount,
                                            isExpense: transaction.isExpense,
                                            date: transaction.date,
                                            isReversal: transaction.isReversal,
                                            originalTransactionId: transaction.originalTransactionId,
                                            category: transaction.category,
                                            subcategory: transaction.subcategory,
                                            installmentId: transaction.installmentId,
                                            installmentNumber: transaction.installmentNumber,
                                            totalInstallments: transaction.totalInstallments,
                                            attachments: updatedAttachments,
                                          );
                                          await _dbService.updateTransaction(transactionIndex, updatedTransaction);
                                          _loadData();
                                        },
                                      ),
                                    );
                                  },
                                ),
                                TextButton.icon(
                                  icon: const Icon(Icons.edit),
                                  label: Text(t('edit')),
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    // Show edit dialog
                                    final result = await showDialog<Map<String, dynamic>>(
                                      context: context,
                                      builder: (context) => EditTransactionDialog(
                                        transaction: transaction,
                                        dbService: _dbService,
                                        currentLanguage: _currentLanguage,
                                      ),
                                    );
                                    if (result != null && transactionIndex >= 0) {
                                      final updatedTransaction = Transaction(
                                        id: transaction.id,
                                        description: result['description'] ?? transaction.description,
                                        amount: result['amount'] ?? transaction.amount,
                                        isExpense: result['isExpense'] ?? transaction.isExpense,
                                        date: result['date'] ?? transaction.date,
                                        category: result['category'] ?? transaction.category,
                                        subcategory: result['subcategory'] ?? transaction.subcategory,
                                        isReversal: transaction.isReversal,
                                        originalTransactionId: transaction.originalTransactionId,
                                        attachments: transaction.attachments,
                                      );
                                      await _dbService.updateTransaction(transactionIndex, updatedTransaction);
                                      _loadData();
                                    }
                                  },
                                ),
                                TextButton.icon(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  label: Text(t('delete'), style: const TextStyle(color: Colors.red)),
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    
                                    if (transaction.isInstallment) {
                                      // Ask if user wants to delete only this installment or all
                                      final result = await showDialog<String>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text(t('delete_transaction')),
                                          content: Text(t('delete_installment_msg')),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, 'cancel'),
                                              child: Text(t('cancel')),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, 'single'),
                                              child: Text(t('delete_this')),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, 'all'),
                                              child: Text(t('delete_all'), style: const TextStyle(color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (result == 'single') {
                                        await transaction.delete();
                                        _loadData();
                                      } else if (result == 'all' && transaction.installmentId != null) {
                                        await _dbService.deleteTransactionSeries(transaction.installmentId!);
                                        _loadData();
                                      }
                                    } else {
                                      // Normal deletion
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text(t('delete_transaction')),
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
                                      
                                      if (confirm == true) {
                                        await transaction.delete();
                                        _loadData();
                                      }
                                    }
                                  },
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(t('close')),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTransactionDialog(),
        tooltip: 'Adicionar Transação',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddTransactionDialog() {
    showDialog(
      context: context,
      builder: (context) => AddTransactionDialog(
        onTransactionAdded: () {
          _loadData();
        },
      ),
    );
  }
}
