import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../services/database_service.dart';
import '../services/pdf_service.dart';
import '../utils/localization.dart';
import 'pdf_preview_screen.dart';

class InstallmentsReportScreen extends StatefulWidget {
  const InstallmentsReportScreen({super.key});

  @override
  State<InstallmentsReportScreen> createState() => _InstallmentsReportScreenState();
}

class _InstallmentsReportScreenState extends State<InstallmentsReportScreen> {
  final DatabaseService _dbService = DatabaseService();
  Map<int, Map<int, List<Transaction>>> _groupedTransactions = {};
  Map<int, Map<int, List<Transaction>>> _filteredGroupedTransactions = {};
  
  String get _currentLanguage => Localizations.localeOf(context).toString();
  bool _isLoading = true;
  
  int? _selectedYear;
  int? _selectedMonth;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _dbService.init();
    final allTransactions = _dbService.getTransactions();
    final language = _dbService.getLanguage();

    // Filter only installments
    final installments = allTransactions.where((t) => t.isInstallment).toList();

    // Group by Year -> Month
    final grouped = <int, Map<int, List<Transaction>>>{};

    for (var transaction in installments) {
      final year = transaction.date.year;
      final month = transaction.date.month;

      if (!grouped.containsKey(year)) {
        grouped[year] = {};
      }
      if (!grouped[year]!.containsKey(month)) {
        grouped[year]![month] = [];
      }
      grouped[year]![month]!.add(transaction);
    }

    // Sort transactions within each month by date
    for (var year in grouped.keys) {
      for (var month in grouped[year]!.keys) {
        grouped[year]![month]!.sort((a, b) => a.date.compareTo(b.date));
      }
    }

    setState(() {
      _groupedTransactions = grouped;
      // _currentLanguage = language; // No longer needed
      _isLoading = false;
      _applyFilters();
    });
  }
  
  void _applyFilters() {
    if (_selectedYear == null && _selectedMonth == null) {
      _filteredGroupedTransactions = _groupedTransactions;
      return;
    }
    
    final filtered = <int, Map<int, List<Transaction>>>{};
    
    for (var year in _groupedTransactions.keys) {
      if (_selectedYear != null && year != _selectedYear) continue;
      
      for (var month in _groupedTransactions[year]!.keys) {
        if (_selectedMonth != null && month != _selectedMonth) continue;
        
        if (!filtered.containsKey(year)) {
          filtered[year] = {};
        }
        filtered[year]![month] = _groupedTransactions[year]![month]!;
      }
    }
    
    setState(() {
      _filteredGroupedTransactions = filtered;
    });
  }

  String t(String key) => AppLocalizations.t(key, _currentLanguage);

  @override
  Widget build(BuildContext context) {
    // Locale setup for formatting
    String locale = _currentLanguage;
    if (locale == 'pt_BR' || locale == 'pt_PT') locale = 'pt_BR';
    else if (locale == 'en') locale = 'en_US';
    
    final currencyFormat = NumberFormat.simpleCurrency(locale: locale);
    final dateFormat = DateFormat.MMMM(locale);

    // Get sorted years
    final sortedYears = _groupedTransactions.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: Text(t('installments_report_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.green),
            tooltip: t('share_whatsapp'),
            onPressed: () async {
              try {
                // Flatten all transactions for PDF
                final allInstallments = <Transaction>[];
                for (var year in _groupedTransactions.keys) {
                  for (var month in _groupedTransactions[year]!.keys) {
                    allInstallments.addAll(_groupedTransactions[year]![month]!);
                  }
                }
                
                // Calculate total
                final total = allInstallments.fold(0.0, (sum, t) => sum + t.amount);
                
                await PdfService.shareTransactionsPdf(
                  allInstallments,
                  currencyFormat,
                  DateFormat('dd/MM/yyyy', locale),
                  total,
                  _currentLanguage,
                );
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${t('error_share_pdf')}$e')),
                  );
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: t('export_pdf'),
            onPressed: () async {
              try {
                // Flatten all transactions for PDF
                final allInstallments = <Transaction>[];
                for (var year in _groupedTransactions.keys) {
                  for (var month in _groupedTransactions[year]!.keys) {
                    allInstallments.addAll(_groupedTransactions[year]![month]!);
                  }
                }
                
                // Calculate total
                final total = allInstallments.fold(0.0, (sum, t) => sum + t.amount);
                
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PdfPreviewScreen(
                      title: t('installments_report_title'),
                      buildPdf: (format) => PdfService.generateTransactionsPdfBytes(
                        allInstallments,
                        currencyFormat,
                        DateFormat('dd/MM/yyyy', locale),
                        total,
                        _currentLanguage,
                      ),
                    ),
                  ),
                );
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${t('error_pdf_gen')}: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _groupedTransactions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.credit_card_off, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        t('no_installments_found'),
                        style: const TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Filter chips
                    Container(
                      padding: const EdgeInsets.all(8),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // Year filter
                            PopupMenuButton<int?>(
                              child: Chip(
                                avatar: const Icon(Icons.calendar_today, size: 18),
                                label: Text(_selectedYear == null ? '${t('year_filter')}${t('filter_all')}' : '${t('year_filter')}$_selectedYear'),
                                deleteIcon: _selectedYear != null ? const Icon(Icons.close, size: 18) : null,
                                onDeleted: _selectedYear != null ? () {
                                  setState(() {
                                    _selectedYear = null;
                                    _applyFilters();
                                  });
                                } : null,
                              ),
                              itemBuilder: (context) {
                                final years = _groupedTransactions.keys.toList()..sort();
                                return [
                                  PopupMenuItem<int?>(
                                    value: null,
                                    child: Text(t('filter_all')),
                                  ),
                                  ...years.map((year) => PopupMenuItem<int?>(
                                    value: year,
                                    child: Text(year.toString()),
                                  )),
                                ];
                              },
                              onSelected: (year) {
                                setState(() {
                                  _selectedYear = year;
                                  _applyFilters();
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            // Month filter
                            PopupMenuButton<int?>(
                              child: Chip(
                                avatar: const Icon(Icons.date_range, size: 18),
                                label: Text(_selectedMonth == null ? '${t('month_filter')}${t('filter_all')}' : '${t('month_filter')}${DateFormat.MMMM(locale).format(DateTime(2000, _selectedMonth!))}'),
                                deleteIcon: _selectedMonth != null ? const Icon(Icons.close, size: 18) : null,
                                onDeleted: _selectedMonth != null ? () {
                                  setState(() {
                                    _selectedMonth = null;
                                    _applyFilters();
                                  });
                                } : null,
                              ),
                              itemBuilder: (context) {
                                return [
                                  PopupMenuItem<int?>(
                                    value: null,
                                    child: Text(t('filter_all')),
                                  ),
                                  ...List.generate(12, (i) => i + 1).map((month) {
                                    final monthName = DateFormat.MMMM(locale).format(DateTime(2000, month));
                                    return PopupMenuItem<int?>(
                                      value: month,
                                      child: Text('${monthName[0].toUpperCase()}${monthName.substring(1)}'),
                                    );
                                  }),
                                ];
                              },
                              onSelected: (month) {
                                setState(() {
                                  _selectedMonth = month;
                                  _applyFilters();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    // List
                    Expanded(
                      child: _filteredGroupedTransactions.isEmpty
                          ? Center(
                              child: Text(
                                t('no_filtered_installments'),
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredGroupedTransactions.keys.length,
                  itemBuilder: (context, yearIndex) {
                    final sortedYears = _filteredGroupedTransactions.keys.toList()..sort();
                    final year = sortedYears[yearIndex];
                    final monthsMap = _filteredGroupedTransactions[year]!;
                    final sortedMonths = monthsMap.keys.toList()..sort();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            year.toString(),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        ...sortedMonths.map((month) {
                          final transactions = monthsMap[month]!;
                          final totalAmount = transactions.fold(0.0, (sum, t) => sum + t.amount);
                          final monthName = dateFormat.format(DateTime(year, month));
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: ExpansionTile(
                              title: Text(
                                '${monthName[0].toUpperCase()}${monthName.substring(1)} $year',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                '${t('total_label')}${currencyFormat.format(totalAmount)}',
                                style: TextStyle(
                                  color: totalAmount >= 0 ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              children: transactions.map((t) {
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: t.isExpense ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                                    child: Icon(
                                      t.isExpense ? Icons.remove : Icons.add,
                                      color: t.isExpense ? Colors.red : Colors.green,
                                      size: 16,
                                    ),
                                  ),
                                  title: Text(t.description),
                                  subtitle: Text(t.installmentText),
                                  trailing: Text(
                                    currencyFormat.format(t.amount),
                                    style: TextStyle(
                                      color: t.isExpense ? Colors.red : Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
                    ),
                  ],
                ),
    );
  }
}
