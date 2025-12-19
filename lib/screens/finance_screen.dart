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
import '../services/subscription/feature_gate.dart';
import '../services/subscription/subscription_service.dart';
import '../services/transaction_csv_service.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

enum TransactionType { all, income, expense }
enum FilterPeriod { today, thisWeek, thisMonth, last30Days, all }
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
  
  FilterPeriod _selectedPeriod = FilterPeriod.last30Days;
  DateTime? _selectedDate;
  TransactionType _selectedType = TransactionType.all;
  String _searchQuery = '';
  SortBy _sortBy = SortBy.date;
  bool _isAscending = false;
  bool _showOnlyWithAttachments = false;
  bool _isSearching = false;
  double _filteredBalance = 0; // Legacy, kept for PDF
  double _totalBalance = 0;
  double _cashFlowBalance = 0;
  
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
          case FilterPeriod.last30Days:
            final start = now.subtract(const Duration(days: 31));
            final end = now.add(const Duration(days: 1));
            matchesPeriod = transaction.date.isAfter(start) && transaction.date.isBefore(end);
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

    // Calculate balances
    _filteredBalance = 0;
    // Use Realized Balance (Cash Flow) as primary indicator - Aligned with Voice/AI
    _totalBalance = _dbService.getRealizedBalance();
    _cashFlowBalance = 0;
    
    // final now = DateTime.now(); // Removed duplicate

    for (var t in _filteredTransactions) {
      // Removed local _totalBalance addition to show Global Balance regardless of filter
      
      // Cash Flow Balance (Realized Only - relative to filter)
      if (t.isRealized) {
        _cashFlowBalance += t.amount;
      }
    }
    
    _filteredBalance = _cashFlowBalance; // Use Cash Flow for PDF/Legacy display if needed

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
    final dateFormat = DateFormat.yMd(_currentLanguage);
    final currencyFormat = NumberFormat.simpleCurrency(locale: _currentLanguage);

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

  Future<void> _showImportExportOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.file_upload),
              title: const Text('Exportar Dados (CSV)'),
              subtitle: const Text('Salvar backup ou abrir em Excel'),
              onTap: () {
                Navigator.pop(ctx);
                _showExportFilterCsvDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_download),
              title: const Text('Importar Dados (CSV)'),
              subtitle: const Text('Restaurar dados de arquivo'),
              onTap: () {
                Navigator.pop(ctx);
                _handleImportCsv();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleImportCsv() async {
    try {
      final result = await FilePicker.platform.pickFiles(
         type: FileType.custom,
         allowedExtensions: ['csv'],
      );

      if (result != null && result.files.single.path != null) {
          final file = File(result.files.single.path!);
          final content = await file.readAsString();
          
          final service = TransactionCsvService();
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Processando importação...')));
          }
          
          final report = await service.importCsv(content);
          
          if (mounted) {
             showDialog(
                context: context, 
                builder: (ctx) => AlertDialog(
                   title: const Text("Importação Concluída"),
                   content: Text("Transações importadas: ${report['imported']}\nIgnoradas (duplicadas): ${report['ignored']}"),
                   actions: [TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text("OK"))],
                )
             );
             _loadData(); // Refresh list
          }
      }
    } catch (e) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao importar: $e')));
    }
  }

  Future<void> _showExportFilterCsvDialog() async {
    // Default vars (All Time)
    DateTime? startDate;
    DateTime? endDate;
    bool includeIncome = true;
    bool includeExpense = true;
    bool includePaid = true;
    bool includePending = true;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
               title: const Text('Exportar CSV'),
               content: SingleChildScrollView(
                 child: Column(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                      const Text("Selecione o filtro dos dados.", style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 10),
                      SwitchListTile(
                        title: const Text("Todo o Período"),
                        value: startDate == null, 
                        onChanged: (v) => setState(() {
                           if (v) { startDate = null; endDate = null; } 
                           else { startDate = DateTime.now(); endDate = DateTime.now().add(const Duration(days: 30)); }
                        }),
                      ),
                      if (startDate != null) ...[
                          ListTile(
                             title: Text("Início: ${DateFormat.yMd(_currentLanguage).format(startDate!)}"),
                             onTap: () async {
                                final d = await showDatePicker(context: context, initialDate: startDate!, firstDate: DateTime(2020), lastDate: DateTime(2030));
                                if (d!=null) setState(()=>startDate=d);
                             },
                          ),
                          ListTile(
                             title: Text("Fim: ${DateFormat.yMd(_currentLanguage).format(endDate!)}"),
                             onTap: () async {
                                final d = await showDatePicker(context: context, initialDate: endDate!, firstDate: DateTime(2020), lastDate: DateTime(2030));
                                if (d!=null) setState(()=>endDate=d);
                             },
                          ),
                      ],
                      const Divider(),
                      CheckboxListTile(
                        title: const Text("Receitas"),
                        value: includeIncome,
                        onChanged: (v) => setState(() => includeIncome = v!),
                      ),
                      CheckboxListTile(
                        title: const Text("Despesas"),
                        value: includeExpense,
                        onChanged: (v) => setState(() => includeExpense = v!),
                      ),
                      const SizedBox(height: 5),
                      const Text("Status:", style: TextStyle(fontWeight: FontWeight.bold)),
                      CheckboxListTile(
                        title: const Text("Pagas/Recebidas"),
                        value: includePaid,
                        onChanged: (v) => setState(() => includePaid = v!),
                      ),
                       CheckboxListTile(
                        title: const Text("Pendentes"),
                        value: includePending,
                        onChanged: (v) => setState(() => includePending = v!),
                      ),
                   ],
                 ),
               ),
               actions: [
                 TextButton(onPressed: ()=>Navigator.pop(context), child: const Text("Cancelar")),
                 ElevatedButton(
                    child: const Text("Exportar"),
                    onPressed: () async {
                       Navigator.pop(context);
                       
                       // Filter Logic
                       var list = List<Transaction>.from(_transactions);
                       
                       if (startDate != null && endDate != null) {
                         list = list.where((t) => t.date.isAfter(startDate!.subtract(const Duration(days: 1))) && t.date.isBefore(endDate!.add(const Duration(days: 1)))).toList();
                       }

                       list = list.where((t) {
                           if (t.isExpense && !includeExpense) return false;
                           if (!t.isExpense && !includeIncome) return false;
                           
                           bool isSettled = t.isPaid; // 'Paid' means Settled in UI terms? 
                           // TransactionModel: isPaid usually means settled.
                           // But prompt distinguishes "Pagas/Recebidas" vs "Pendentes/Atrasadas"
                           
                           if (isSettled && !includePaid) return false;
                           if (!isSettled && !includePending) return false;

                           return true;
                       }).toList();

                       if (list.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nenhuma transação para exportar.")));
                          return;
                       }
                       
                       final service = TransactionCsvService();
                       final csv = service.generateCsv(list);
                       final filename = "finance_export_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv";
                       await service.shareCsv(csv, filename);
                    },
                 )
               ]
            );
          }
        );
      }
    );
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
    final dateFormat = DateFormat.yMd(locale);

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
                 icon: const Icon(Icons.import_export),
                 tooltip: "Importar/Exportar CSV",
                 onPressed: _showImportExportOptions,
               ),
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
                final allowed = await FeatureGate(SubscriptionService()).canUseFeature(context, AppFeature.useAdvancedReports);
                if (!allowed) return;

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
                final allowed = await FeatureGate(SubscriptionService()).canUseFeature(context, AppFeature.useAdvancedReports);
                if (!allowed) return;

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
          // Balance Card (Dual)
          Card(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () async {
                          final allowed = await FeatureGate(SubscriptionService()).canUseFeature(context, AppFeature.useAdvancedReports);
                          if (!allowed) return;

                          try {
                            // Balance Total: Show ALL transactions including future installments (parcelas a vencer)
                            final balanceTransactions = List<Transaction>.from(_transactions);
                            
                            // Sort mainly by date descending for report
                            balanceTransactions.sort((a, b) => b.date.compareTo(a.date));

                            if (mounted) {
                                Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => PdfPreviewScreen(
                                    title: "Relatório de Saldo Total",
                                    buildPdf: (format) => PdfService.generateCashFlowPdfBytes(
                                        balanceTransactions,
                                        currencyFormat,
                                        dateFormat,
                                        _totalBalance,
                                        _currentLanguage,
                                        "Relatório do Saldo Total",
                                    ),
                                    ),
                                ),
                                );
                            }
                          } catch (e) {
                            if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('${t('error')}: $e')),
                                );
                            }
                          }
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t('balance_total') + " (Atual)", style: const TextStyle(fontSize: 12, color: Colors.grey, decoration: TextDecoration.underline)),
                            Text(
                              currencyFormat.format(_totalBalance),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _totalBalance >= 0 ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () async {
                          final allowed = await FeatureGate(SubscriptionService()).canUseFeature(context, AppFeature.useAdvancedReports);
                          if (!allowed) return;

                          try {
                            // Filter realized transactions for Cash Flow
                            final cashFlowTransactions = _filteredTransactions.where((t) => t.isRealized).toList();
                            
                            if (mounted) {
                                Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => PdfPreviewScreen(
                                    title: "Relatório de Fluxo de Caixa",
                                    buildPdf: (format) => PdfService.generateCashFlowPdfBytes(
                                        cashFlowTransactions,
                                        currencyFormat,
                                        dateFormat,
                                        _cashFlowBalance,
                                        _currentLanguage,
                                        "Relatório de Fluxo de Caixa",
                                    ),
                                    ),
                                ),
                                );
                            }
                          } catch (e) {
                            if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('${t('error')}: $e')),
                                );
                            }
                          }
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text("Fluxo de Caixa (Realizado)", style: TextStyle(fontSize: 12, color: Colors.grey, decoration: TextDecoration.underline)),
                            Text(
                              currencyFormat.format(_cashFlowBalance),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _cashFlowBalance >= 0 ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

                // 2. Last 30 Days (Default)
                ChoiceChip(
                  label: Text(t('period_last_30')),
                  selected: _selectedPeriod == FilterPeriod.last30Days && _selectedDate == null,
                  onSelected: (selected) {
                    setState(() {
                      _selectedPeriod = FilterPeriod.last30Days;
                      _selectedDate = null;
                      _applyFilters();
                    });
                  },
                ),
                const SizedBox(width: 8),

                // 3. Month (Period)
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

                        final isOverdue = transaction.isOverdue;
                        final isPending = !transaction.isRealized;

                        return Opacity(
                          opacity: isPending ? 0.6 : 1.0, 
                          child: ListTile(
                            selected: isSelected,
                            selectedTileColor: isOverdue 
                                ? Colors.red.withOpacity(0.1) 
                                : Colors.blue.withOpacity(0.1),
                            leading: _isSelectionMode
                              ? Checkbox(
                                  value: isSelected,
                                  onChanged: (value) => _toggleSelection(transaction.id),
                                )
                              : CircleAvatar(
                                  backgroundColor: transaction.isReversal 
                                      ? Colors.orange[100] 
                                      : (transaction.isExpense 
                                          ? (isOverdue ? Colors.red[50] : Colors.red[100]) 
                                          : Colors.green[100]),
                                  child: isOverdue
                                    ? const Icon(Icons.warning, color: Colors.red)
                                    : (transaction.isRealized
                                        ? const Icon(Icons.check, color: Colors.black54, size: 16)
                                        : (transaction.attachments != null && transaction.attachments!.isNotEmpty
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
                                                // If not realized (pending), show schedule icon, else show direction
                                                isPending ? Icons.schedule : (transaction.isExpense ? Icons.arrow_downward : Icons.arrow_upward),
                                                color: transaction.isReversal 
                                                    ? Colors.orange 
                                                    : (transaction.isExpense ? Colors.red : Colors.green),
                                              ))),
                                ),
                            title: Row(
                              children: [
                                Expanded(child: Text(
                                  transaction.isInstallment 
                                    ? '${transaction.description} (${transaction.installmentText})'
                                    : transaction.description,
                                  style: TextStyle(
                                    decoration: transaction.isPaid ? TextDecoration.none : null,
                                    fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                                    color: isOverdue ? Colors.red : null,
                                  ),
                                )),
                                if (transaction.isPaid)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 4),
                                    child: Icon(Icons.check_circle, color: Colors.green, size: 16),
                                  ),
                              ],
                            ),
                            subtitle: Text(
                              '${AppLocalizations.tCategory(transaction.category, _currentLanguage)} • ${dateFormat.format(transaction.date)}',
                              style: TextStyle(
                                color: isOverdue ? Colors.redAccent : null,
                              ),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  currencyFormat.format(transaction.amount),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: transaction.isExpense ? Colors.red : Colors.green,
                                  ),
                                ),
                                Builder(
                                  builder: (context) {
                                    // Status Logic Refined (Regra de Ouro: Date <= Today -> Paid/Received)
                                    final now = DateTime.now();
                                    final today = DateTime(now.year, now.month, now.day);
                                    final isFuture = transaction.date.isAfter(today.add(const Duration(days: 1)).subtract(const Duration(seconds: 1))); // Date > Today (end of day) logic or simply Date >= Tomorrow
                                    // Actually, strict comparison:
                                    final tDate = DateTime(transaction.date.year, transaction.date.month, transaction.date.day);
                                    final isPastOrToday = !tDate.isAfter(today);
                                    
                                    String statusText = "";
                                    Color statusColor = Colors.grey;
                                    FontWeight statusWeight = FontWeight.normal;

                                    if (transaction.isExpense) {
                                      // EXPENSE LOGIC
                                      if (transaction.isPaid || isPastOrToday) {
                                        statusText = t('status_paid');
                                        statusColor = Colors.green;
                                        // Refined for Safety:
                                        if (!transaction.isPaid && isPastOrToday) {
                                            statusText = t('status_paid');
                                            statusColor = Colors.green;
                                        }
                                      } else {
                                        // Future
                                        statusText = t('status_pending');
                                        statusColor = Colors.grey;
                                      }
                                    } else {
                                      // INCOME LOGIC (Receitas)
                                      if (transaction.isPaid || isPastOrToday) {
                                        statusText = t('status_received');
                                        statusColor = Colors.green;
                                      } else {
                                        statusText = t('status_to_receive');
                                        statusColor = Colors.grey;
                                      }
                                    }
                                    
                                    // Handle "Atrasado" legacy/explicit case if strictly needed?
                                    // "Outros Casos: Transação não marcada manualmente como 'Paga' E ... -> Atrasado"
                                    // This applies if we deviate from Regra de Ouro.
                                    // Let's stick to the prompt's Table 100%.

                                    return Text(
                                      statusText,
                                      style: TextStyle(fontSize: 10, color: statusColor, fontWeight: statusWeight),
                                    );
                                  }
                                ),
                              ],
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
                                if (!transaction.isPaid && transaction.isExpense)
                                  TextButton.icon(
                                    icon: const Icon(Icons.check, color: Colors.green),
                                    label: const Text('Marcar como Pago', style: TextStyle(color: Colors.green)),
                                    onPressed: () async {
                                      Navigator.pop(context);
                                      await _dbService.markTransactionAsPaid(transaction.id, DateTime.now());
                                      _loadData();
                                    },
                                  ),
                                TextButton.icon(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  label: Text(t('edit')),
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    await _editTransaction(transaction);
                                  },
                                ),


                                TextButton.icon(
                                  icon: const Icon(Icons.attach_file),
                                  label: Text(t('attachments_label')),
                                  onPressed: () async {
                                    final allowed = await FeatureGate(SubscriptionService()).canUseFeature(context, AppFeature.createAttachment);
                                    if (!allowed) return;

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
                                          await _dbService.updateTransaction(transaction.id, updatedTransaction);
                                          _loadData();
                                        },
                                      ),
                                    );
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
                      ),
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
  Future<void> _editTransaction(Transaction transaction) async {
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => EditTransactionDialog(
          transaction: transaction,
          dbService: _dbService,
          currentLanguage: _currentLanguage,
        ),
      );

      if (result != null) {
        final updatedTransaction = Transaction(
          id: transaction.id,
          description: result['description'],
          amount: result['amount'],
          isExpense: result['isExpense'],
          date: result['date'],
          category: result['category'],
          subcategory: result['subcategory'],
          attachments: transaction.attachments,
          updatedAt: DateTime.now(),
          isDeleted: transaction.isDeleted,
          isSynced: transaction.isSynced,
          installmentId: transaction.installmentId,
          installmentNumber: transaction.installmentNumber,
          totalInstallments: transaction.totalInstallments,
          originalTransactionId: transaction.originalTransactionId,
          isReversal: transaction.isReversal,
          isPaid: result['isPaid'],
          paymentDate: result['paymentDate'],
        );

        await _dbService.updateTransaction(transaction.id, updatedTransaction);
        _loadData();
      }
  }
}
