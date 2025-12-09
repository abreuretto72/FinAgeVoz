import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../models/report_filter.dart';
import '../services/database_service.dart';
import '../services/pdf_service.dart';
import '../utils/constants.dart';
import '../utils/localization.dart';
import '../widgets/advanced_filters_dialog.dart';
import 'installments_report_screen.dart';
import 'pdf_preview_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<Transaction> _transactions = [];
  List<Transaction> _filteredTransactions = [];
  ReportFilter _currentFilter = ReportFilter();
  
  String get _currentLanguage => Localizations.localeOf(context).toString();
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _dbService.init();
    final transactions = _dbService.getTransactions();
    final language = _dbService.getLanguage();
    
    setState(() {
      // _currentLanguage = language; // No longer needed
      _transactions = transactions;
      _filteredTransactions = _applyFilters(transactions, _currentFilter);
    });
  }

  String t(String key) => AppLocalizations.t(key, _currentLanguage);

  List<Transaction> _applyFilters(List<Transaction> transactions, ReportFilter filter) {
    return transactions.where((transaction) {
      // Period filter
      final DateTime startDate;
      final DateTime endDate;
      final now = DateTime.now();
      
      switch (filter.periodType) {
        case 'MONTH':
          startDate = DateTime(now.year, now.month, 1);
          endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
          break;
        case 'QUARTER':
          final currentQuarter = ((now.month - 1) ~/ 3) + 1;
          startDate = DateTime(now.year, (currentQuarter - 1) * 3 + 1, 1);
          endDate = DateTime(now.year, currentQuarter * 3 + 1, 0, 23, 59, 59);
          break;
        case 'YEAR':
          startDate = DateTime(now.year, 1, 1);
          endDate = DateTime(now.year, 12, 31, 23, 59, 59);
          break;
        case 'LAST_7':
          startDate = now.subtract(const Duration(days: 7));
          endDate = now;
          break;
        case 'LAST_30':
          startDate = now.subtract(const Duration(days: 30));
          endDate = now;
          break;
        case 'LAST_90':
          startDate = now.subtract(const Duration(days: 90));
          endDate = now;
          break;
        case 'CUSTOM':
          if (filter.startDate == null || filter.endDate == null) {
            return true; // No custom dates set, include all
          }
          startDate = filter.startDate!;
          endDate = filter.endDate!;
          break;
        default:
          startDate = DateTime(now.year, now.month, 1);
          endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      }
      
      if (!transaction.date.isAfter(startDate) || !transaction.date.isBefore(endDate.add(const Duration(days: 1)))) {
        return false;
      }
      
      // Type filter
      if (transaction.isExpense && !filter.includeExpenses) return false;
      if (!transaction.isExpense && !filter.includeIncome) return false;
      
      // Installment filter
      final isInstallment = transaction.installmentId != null;
      if (isInstallment && !filter.includeInstallments) return false;
      if (!isInstallment && !filter.includeSinglePayments) return false;
      
      // Reversal filter
      if (filter.excludeReversals && transaction.isReversal) return false;
      
      // Category filter
      if (filter.selectedCategories.isNotEmpty) {
        if (!filter.selectedCategories.contains(transaction.category)) {
          return false;
        }
      }
      
      // Subcategory filter
      if (filter.selectedSubcategories.isNotEmpty) {
        if (transaction.subcategory == null || 
            !filter.selectedSubcategories.contains(transaction.subcategory)) {
          return false;
        }
      }
      
      // Value filter
      if (filter.minValue != null && transaction.amount < filter.minValue!) {
        return false;
      }
      if (filter.maxValue != null && transaction.amount > filter.maxValue!) {
        return false;
      }
      
      return true;
    }).toList();
  }

  Map<String, double> _getExpensesByCategory() {
    final Map<String, double> categoryTotals = {};
    
    for (var transaction in _filteredTransactions) {
      if (transaction.isExpense) {
        // Algebraic v2: Expense is negative, Reversal is positive.
        // We want positive totals for the chart/list, so we take abs().
        // Wait, if we sum them up:
        // Exp(-100) + Rev(+100) = 0. Correct.
        // But for "Total Expenses" display, we usually want a positive number representing the magnitude.
        // If we just sum t.amount, we get -100.
        // So for the category totals map, we should probably store the NET amount (which will be negative for net expense).
        
        categoryTotals[transaction.category] = 
            (categoryTotals[transaction.category] ?? 0) + transaction.amount;
      }
    }
    
    // Convert to absolute values for display in Pie Chart
    // Since expenses are negative, the totals will be negative.
    // We want positive magnitudes for the chart.
    final Map<String, double> absoluteTotals = {};
    categoryTotals.forEach((key, value) {
      absoluteTotals[key] = value.abs();
    });
    
    // Remove categories with <= 0 total to avoid issues in pie chart
    absoluteTotals.removeWhere((key, value) => value <= 0.01);
    
    return absoluteTotals;
  }

  double get _totalIncome {
    double total = 0;
    for (var t in _filteredTransactions) {
      if (!t.isExpense) {
        // Income is positive. Reversal is negative.
        // Sum is correct.
        total += t.amount;
      }
    }
    return total;
  }

  double get _totalExpenses {
    double total = 0;
    for (var t in _filteredTransactions) {
      if (t.isExpense) {
        // Expense is negative. Reversal is positive.
        // Sum is negative.
        // We want to return a positive magnitude for "Total Expenses".
        total += t.amount;
      }
    }
    // Return absolute value for display purposes (e.g. "Expenses: R$ 500")
    return total.abs();
  }

  double get _balance => _totalIncome - _totalExpenses;

  String _getActiveFiltersText() {
    final List<String> filters = [];
    
    // Period
    switch (_currentFilter.periodType) {
      case 'MONTH':
        filters.add(t('period_month'));
        break;
      case 'QUARTER':
        filters.add(t('period_quarter_short'));
        break;
      case 'YEAR':
        filters.add(t('period_year_short'));
        break;
      case 'LAST_7':
        filters.add(t('period_last_7'));
        break;
      case 'LAST_30':
        filters.add(t('period_last_30'));
        break;
      case 'LAST_90':
        filters.add(t('period_last_90'));
        break;
      case 'CUSTOM':
        if (_currentFilter.startDate != null && _currentFilter.endDate != null) {
          filters.add('${DateFormat.yMd(_currentLanguage).format(_currentFilter.startDate!)} - ${DateFormat.yMd(_currentLanguage).format(_currentFilter.endDate!)}');
        }
        break;
    }
    
    // Categories
    if (_currentFilter.selectedCategories.isNotEmpty) {
      filters.add('${_currentFilter.selectedCategories.length} ${t('categories_count')}');
    }
    
    // Subcategories
    if (_currentFilter.selectedSubcategories.isNotEmpty) {
      filters.add('${_currentFilter.selectedSubcategories.length} ${t('subcategories_count')}');
    }
    
    // Values
    if (_currentFilter.minValue != null || _currentFilter.maxValue != null) {
      filters.add(t('filtered_values'));
    }
    
    // Type
    final List<String> types = [];
    if (!_currentFilter.includeExpenses) types.add(t('no_expenses'));
    if (!_currentFilter.includeIncome) types.add(t('no_income'));
    if (!_currentFilter.includeInstallments) types.add(t('no_installments'));
    if (!_currentFilter.includeSinglePayments) types.add(t('no_single_payments'));
    if (types.isNotEmpty) {
      filters.add(types.join(', '));
    }
    
    return '${t('active_filters')}${filters.join(' • ')} (${_filteredTransactions.length} ${t('transactions_count_label')})';
  }

  final GlobalKey _globalKey = GlobalKey();

  Future<void> _captureAndExportPdf() async {
    try {
      // Wait for build to complete
      await Future.delayed(const Duration(milliseconds: 100));
      
      final boundary = _globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      // Capture image with higher pixel ratio for better quality
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PdfPreviewScreen(
              title: t('financial_report_title'),
              buildPdf: (format) => PdfService.generateFinancialReportBytes(
                pngBytes,
                _filteredTransactions,
                _currentLanguage,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      print("Error capturing image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t('error_pdf_gen'))),
        );
      }
    }
  }

  Future<void> _captureAndSharePdf() async {
    try {
      // Wait for build to complete
      await Future.delayed(const Duration(milliseconds: 100));
      
      final boundary = _globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      // Capture image with higher pixel ratio for better quality
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      if (mounted) {
        await PdfService.shareFinancialReport(pngBytes, _currentFilter.periodType, _filteredTransactions, _currentLanguage);
      }
    } catch (e) {
      print("Error capturing image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t('error_pdf_gen'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Map internal language codes to standard locales for NumberFormat
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
    final expensesByCategory = _getExpensesByCategory();

    return Scaffold(
      appBar: AppBar(
        title: Text(t('reports_title')),
        actions: [
          // Filter button
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: _currentFilter.isDefault ? null : Colors.orange,
            ),
            tooltip: t('advanced_filters'),
            onPressed: () async {
              final result = await showDialog<ReportFilter>(
                context: context,
                builder: (context) => AdvancedFiltersDialog(
                  initialFilter: _currentFilter,
                  currentLanguage: _currentLanguage,
                ),
              );
              
              if (result != null) {
                setState(() {
                  _currentFilter = result;
                  _filteredTransactions = _applyFilters(_transactions, _currentFilter);
                });
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_view_month),
            tooltip: t('view_installments'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const InstallmentsReportScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.green),
            tooltip: 'Compartilhar no WhatsApp',
            onPressed: _captureAndSharePdf,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: t('export_pdf'),
            onPressed: _captureAndExportPdf,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: t('share'),
            onPressed: _captureAndSharePdf,
          ),
        ],
      ),
      body: RepaintBoundary(
        key: _globalKey,
        child: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Active filters indicator
                if (!_currentFilter.isDefault) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.filter_list, color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getActiveFiltersText(),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _currentFilter = ReportFilter();
                              _filteredTransactions = _applyFilters(_transactions, _currentFilter);
                            });
                          },
                          child: Text(t('clear')),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Summary Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        t('income'),
                        currencyFormat.format(_totalIncome),
                        Colors.green,
                        Icons.arrow_upward,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        t('expenses'),
                        currencyFormat.format(_totalExpenses),
                        Colors.red,
                        Icons.arrow_downward,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSummaryCard(
                  t('balance_total'),
                  currencyFormat.format(_balance),
                  _balance >= 0 ? Colors.blue : Colors.orange,
                  _balance >= 0 ? Icons.account_balance_wallet : Icons.warning,
                ),
                
                const SizedBox(height: 32),
                
                // Pie Chart - Expenses by Category
                if (expensesByCategory.isNotEmpty) ...[
                  Text(
                    t('chart_expenses_category'),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 250,
                    child: PieChart(
                      PieChartData(
                        sections: _buildPieChartSections(expensesByCategory),
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildLegend(expensesByCategory, currencyFormat),
                ],
                
                const SizedBox(height: 32),
                
                // Bar Chart - Income vs Expenses
                Text(
                  t('chart_income_expense'),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 250,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: [_totalIncome, _totalExpenses].reduce((a, b) => a > b ? a : b) * 1.2,
                      barGroups: [
                        BarChartGroupData(
                          x: 0,
                          barRods: [
                            BarChartRodData(
                              toY: _totalIncome,
                              color: Colors.green,
                              width: 40,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                        BarChartGroupData(
                          x: 1,
                          barRods: [
                            BarChartRodData(
                              toY: _totalExpenses,
                              color: Colors.red,
                              width: 40,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                      ],
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              switch (value.toInt()) {
                                case 0:
                                  return Text(t('income'));
                                case 1:
                                  return Text(t('expenses'));
                                default:
                                  return const Text('');
                              }
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 60,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                NumberFormat.compact(locale: locale).format(value),
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
                
                // Transaction List
                _buildTransactionList(currencyFormat),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color, IconData icon) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(Map<String, double> data) {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
    ];

    int index = 0;
    final total = data.values.fold(0.0, (sum, value) => sum + value);

    return data.entries.map((entry) {
      final percentage = (entry.value / total * 100);
      final color = colors[index % colors.length];
      index++;

      return PieChartSectionData(
        value: entry.value,
        title: '${percentage.toStringAsFixed(1)}%',
        color: color,
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildLegend(Map<String, double> data, NumberFormat currencyFormat) {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
    ];

    int index = 0;

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: data.entries.map((entry) {
        final color = colors[index % colors.length];
        final categoryDescription = AppConstants.categoryDescriptions[entry.key] ?? '';
        index++;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${AppLocalizations.tCategory(entry.key, _currentLanguage)}: ${currencyFormat.format(entry.value)}',
              style: const TextStyle(fontSize: 12),
            ),
            if (categoryDescription.isNotEmpty) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(AppLocalizations.tCategory(entry.key, _currentLanguage)),
                      content: Text(categoryDescription),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(t('close')),
                        ),
                      ],
                    ),
                  );
                },
                child: Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ],
        );
      }).toList(),
    );
  }
  Widget _buildTransactionList(NumberFormat currencyFormat) {
    if (_filteredTransactions.isEmpty) {
      return const SizedBox.shrink();
    }

    // Sort transactions by date (newest first)
    final sortedTransactions = List<Transaction>.from(_filteredTransactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Text(
          t('detailed_transactions'),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedTransactions.length,
          itemBuilder: (context, index) {
            final transaction = sortedTransactions[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 2,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: transaction.isReversal 
                      ? Colors.orange.withOpacity(0.1) 
                      : (transaction.isExpense ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1)),
                  child: Icon(
                    transaction.isReversal 
                        ? Icons.undo 
                        : (transaction.isExpense ? Icons.arrow_downward : Icons.arrow_upward),
                    color: transaction.isReversal 
                        ? Colors.orange 
                        : (transaction.isExpense ? Colors.red : Colors.green),
                    size: 20,
                  ),
                ),
                title: Text(
                  transaction.description,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      '${DateFormat.yMd(_currentLanguage).format(transaction.date)} • ${transaction.category}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    if (transaction.subcategory != null)
                      Text(
                        transaction.subcategory!,
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                  ],
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
                        fontSize: 14,
                      ),
                    ),
                    if (transaction.isInstallment)
                      Text(
                        transaction.installmentText,
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
