import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/transaction_model.dart';
import '../models/event_model.dart';
import '../utils/localization.dart';

import '../models/agenda_models.dart';

class PdfService {
  static Future<void> generateAndPrint(
    List<Transaction> transactions,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    final pdf = _buildTransactionsReportPdf(transactions, startDate, endDate);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'relatorio_financeiro_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  static Future<void> generateAndShare(
    List<Transaction> transactions,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    final pdf = _buildTransactionsReportPdf(transactions, startDate, endDate);
    final fileName = 'relatorio_financeiro_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
    final file = await _savePdfToTemp(pdf, fileName);
    await Share.shareXFiles([XFile(file.path)], text: 'Relatório Financeiro - FinAgeVoz');
  }

  static pw.Document _buildTransactionsReportPdf(
    List<Transaction> transactions,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    final pdf = pw.Document();
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFormat = DateFormat('dd/MM/yyyy');

    // Calculate totals
    double totalIncome = 0;
    double totalExpense = 0;
    for (var t in transactions) {
      if (t.isExpense) {
        // Algebraic v2: Expense is negative.
        // We want positive magnitude for "Total Expenses".
        totalExpense += t.amount;
      } else {
        totalIncome += t.amount;
      }
    }
    // Convert expense total to positive for display
    totalExpense = totalExpense.abs();
    
    final balance = totalIncome - totalExpense;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Relatório Financeiro', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                      pw.Text('FinAgeVoz', style: pw.TextStyle(fontSize: 18, color: PdfColors.grey)),
                      pw.Text('Gerado em: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}', style: pw.TextStyle(fontSize: 10, color: PdfColors.black)),
                  ]),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Período: ${startDate != null ? dateFormat.format(startDate) : "Início"} - ${endDate != null ? dateFormat.format(endDate) : "Hoje"}'),
                    pw.Text('Total Transações: ${transactions.length}'),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Receitas: ${currencyFormat.format(totalIncome)}', style: const pw.TextStyle(color: PdfColors.green)),
                    pw.Text('Despesas: ${currencyFormat.format(totalExpense)}', style: const pw.TextStyle(color: PdfColors.red)),
                    pw.Text('Saldo: ${currencyFormat.format(balance)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              context: context,
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
              headerHeight: 25,
              cellHeight: 30,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.centerRight,
              },
              headers: ['Data', 'Descrição', 'Categoria', 'Valor'],
              data: transactions.map((t) {
                return [
                  dateFormat.format(t.date),
                  t.description,
                  t.subcategory != null ? '${t.category} > ${t.subcategory}' : t.category,
                  t.isExpense ? '- ${currencyFormat.format(t.amount)}' : currencyFormat.format(t.amount),
                ];
              }).toList(),
            ),
          ];
        },
      ),
    );
    return pdf;
  }

  static Future<void> generateEventsReport(
    List<Event> events,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    final pdf = _buildEventsReportPdf(events, startDate, endDate);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'agenda_eventos_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  static Future<void> shareEventsReport(
    List<Event> events,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    final pdf = _buildEventsReportPdf(events, startDate, endDate);
    final fileName = 'agenda_eventos_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
    final file = await _savePdfToTemp(pdf, fileName);
    await Share.shareXFiles([XFile(file.path)], text: 'Relatório de Eventos - FinAgeVoz');
  }

  static pw.Document _buildEventsReportPdf(
    List<Event> events,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Agenda de Eventos', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                      pw.Text('FinAgeVoz', style: pw.TextStyle(fontSize: 18, color: PdfColors.grey)),
                      pw.Text('Gerado em: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}', style: pw.TextStyle(fontSize: 10, color: PdfColors.black)),
                  ]),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Período: ${startDate != null ? DateFormat('dd/MM/yyyy').format(startDate) : "Início"} - ${endDate != null ? DateFormat('dd/MM/yyyy').format(endDate) : "Hoje"}'),
                pw.Text('Total Eventos: ${events.length}'),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              context: context,
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
              headerHeight: 25,
              cellHeight: 30,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.center,
              },
              headers: ['Data/Hora', 'Título', 'Descrição', 'Status'],
              data: events.map((e) {
                return [
                  dateFormat.format(e.date),
                  e.title,
                  e.description,
                  e.isCancelled ? 'Cancelado' : 'Ativo',
                ];
              }).toList(),
            ),
          ];
        },
      ),
    );
    return pdf;
  }

  static Future<void> generateFinancialReport(
    Uint8List imageBytes,
    String period,
    List<Transaction> transactions,
    String languageCode,
  ) async {
    final pdf = _buildFinancialChartsPdf(imageBytes, transactions, languageCode);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'relatorio_graficos_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  static Future<Uint8List> generateFinancialReportBytes(
    Uint8List imageBytes,
    List<Transaction> transactions,
    String languageCode,
  ) async {
    final pdf = _buildFinancialChartsPdf(imageBytes, transactions, languageCode);
    return pdf.save();
  }

  static Future<void> shareFinancialReport(
    Uint8List imageBytes,
    String period,
    List<Transaction> transactions,
    String languageCode,
  ) async {
    final pdf = _buildFinancialChartsPdf(imageBytes, transactions, languageCode);
    final fileName = 'relatorio_graficos_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
    final file = await _savePdfToTemp(pdf, fileName);
    await Share.shareXFiles([XFile(file.path)], text: 'Relatório Gráfico - FinAgeVoz');
  }

  static pw.Document _buildFinancialChartsPdf(Uint8List imageBytes, List<Transaction> transactions, String languageCode) {
    final pdf = pw.Document();
    final image = pw.MemoryImage(imageBytes);

    // Page 1: Charts Image
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Image(image, fit: pw.BoxFit.contain),
          );
        },
      ),
    );

    // Subsequent Pages: Transaction List Grouped by Category
    if (transactions.isNotEmpty) {
      final currencyFormat = NumberFormat.simpleCurrency(locale: languageCode);
      final dateFormat = DateFormat('dd/MM/yyyy');

      // Group by category
      final Map<String, List<Transaction>> groupedTransactions = {};
      for (var t in transactions) {
        if (!groupedTransactions.containsKey(t.category)) {
          groupedTransactions[t.category] = [];
        }
        groupedTransactions[t.category]!.add(t);
      }

      // Sort categories alphabetically
      final sortedCategories = groupedTransactions.keys.toList()..sort();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            final List<pw.Widget> widgets = [];
            
            widgets.add(pw.Header(level: 1, text: AppLocalizations.t('category_breakdown', languageCode)));
            widgets.add(pw.SizedBox(height: 10));

            for (var category in sortedCategories) {
              final categoryTransactions = groupedTransactions[category]!;
              // Sort transactions by date descending
              categoryTransactions.sort((a, b) => b.date.compareTo(a.date));
              
              // Calculate total for this category
              double catExpense = 0;
              double catIncome = 0;
              for (var t in categoryTransactions) {
                if (t.isExpense) {
                  catExpense += t.amount;
                } else {
                  catIncome += t.amount;
                }
              }
              // Convert expense total to positive for calculation
              catExpense = catExpense.abs();
              
              final netTotal = catIncome - catExpense;

              widgets.add(
                pw.Container(
                  color: PdfColors.grey200,
                  padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(category, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                      pw.Text(
                        '${AppLocalizations.t('total_label', languageCode)}${currencyFormat.format(netTotal)}',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, 
                          fontSize: 12,
                          color: netTotal >= 0 ? PdfColors.green : PdfColors.red
                        )
                      ),
                    ],
                  ),
                )
              );
              
              widgets.add(pw.SizedBox(height: 5));

              widgets.add(
                pw.Table.fromTextArray(
                  context: context,
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.white),
                  headerHeight: 20,
                  cellHeight: 18,
                  cellAlignments: {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.centerLeft,
                    2: pw.Alignment.centerRight,
                  },
                  columnWidths: {
                    0: const pw.FixedColumnWidth(80),
                    1: const pw.FlexColumnWidth(),
                    2: const pw.FixedColumnWidth(100),
                  },
                  headers: [
                    AppLocalizations.t('table_date', languageCode),
                    AppLocalizations.t('table_description', languageCode),
                    AppLocalizations.t('table_value', languageCode)
                  ],
                  data: categoryTransactions.map((t) {
                    final description = t.subcategory != null 
                        ? '${t.description} (${t.subcategory})' 
                        : t.description;
                    return [
                      dateFormat.format(t.date),
                      description,
                      t.isExpense ? '- ${currencyFormat.format(t.amount)}' : currencyFormat.format(t.amount),
                    ];
                  }).toList(),
                  border: null,
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.grey700),
                  cellStyle: const pw.TextStyle(fontSize: 10),
                  rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
                )
              );
              
              widgets.add(pw.SizedBox(height: 15));
            }

            return widgets;
          },
        ),
      );
    }

    return pdf;
  }

  static Future<void> generateTransactionsPdf(
    List<Transaction> transactions,
    NumberFormat currencyFormat,
    DateFormat dateFormat,
    double balance,
    String languageCode,
  ) async {
    final pdf = _buildDetailedTransactionsPdf(transactions, currencyFormat, dateFormat, balance, languageCode);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'transacoes_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf',
    );
  }

  static Future<Uint8List> generateTransactionsPdfBytes(
    List<Transaction> transactions,
    NumberFormat currencyFormat,
    DateFormat dateFormat,
    double balance,
    String languageCode,
  ) async {
    final pdf = _buildDetailedTransactionsPdf(transactions, currencyFormat, dateFormat, balance, languageCode);
    return pdf.save();
  }

  static Future<void> shareTransactionsPdf(
    List<Transaction> transactions,
    NumberFormat currencyFormat,
    DateFormat dateFormat,
    double balance,
    String languageCode,
  ) async {
    final pdf = _buildDetailedTransactionsPdf(transactions, currencyFormat, dateFormat, balance, languageCode);
    final fileName = 'transacoes_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
    final file = await _savePdfToTemp(pdf, fileName);
    await Share.shareXFiles([XFile(file.path)], text: 'Relatório de Transações - FinAgeVoz');
  }

  static pw.Document _buildDetailedTransactionsPdf(
    List<Transaction> transactions,
    NumberFormat currencyFormat,
    DateFormat dateFormat,
    double balance,
    String languageCode,
  ) {
    final pdf = pw.Document();

    // Calculate totals
    double totalIncome = 0;
    double totalExpense = 0;
    for (var t in transactions) {
      if (t.isExpense) {
        totalExpense += t.amount;
      } else {
        totalIncome += t.amount;
      }
    }
    // Convert expense total to positive for display
    totalExpense = totalExpense.abs();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(AppLocalizations.t('transactions_report_title', languageCode), style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                      pw.Text(AppLocalizations.t('app_title', languageCode), style: pw.TextStyle(fontSize: 18, color: PdfColors.grey)),
                      pw.Text('Gerado em: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}', style: pw.TextStyle(fontSize: 10, color: PdfColors.black)),
                  ]),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(AppLocalizations.t('total_income', languageCode), style: const pw.TextStyle(fontSize: 12)),
                    pw.Text(currencyFormat.format(totalIncome), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.green)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(AppLocalizations.t('total_expense', languageCode), style: const pw.TextStyle(fontSize: 12)),
                    pw.Text(currencyFormat.format(totalExpense), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.red)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(AppLocalizations.t('balance_label', languageCode), style: const pw.TextStyle(fontSize: 12)),
                    pw.Text(
                      currencyFormat.format(balance),
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: balance >= 0 ? PdfColors.green : PdfColors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue),
              cellAlignment: pw.Alignment.centerLeft,
              headers: [
                AppLocalizations.t('table_date', languageCode),
                AppLocalizations.t('table_description', languageCode),
                AppLocalizations.t('table_category', languageCode),
                AppLocalizations.t('table_value', languageCode)
              ],
              data: transactions.map((t) {
                return [
                  dateFormat.format(t.date),
                  t.description,
                  t.category,
                  currencyFormat.format(t.amount),
                ];
              }).toList(),
            ),
          ];
        },
      ),
    );
    return pdf;
  }

  static Future<void> generateEventsPdf(
    List<Event> events,
    DateFormat dateFormat,
    String languageCode,
  ) async {
    final pdf = _buildDetailedEventsPdf(events, dateFormat, languageCode);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'eventos_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf',
    );
  }

  static Future<Uint8List> generateEventsPdfBytes(
    List<Event> events,
    DateFormat dateFormat,
    String languageCode,
  ) async {
    final pdf = _buildDetailedEventsPdf(events, dateFormat, languageCode);
    return pdf.save();
  }

  static Future<void> shareEventsPdf(
    List<Event> events,
    DateFormat dateFormat,
    String languageCode,
  ) async {
    final pdf = _buildDetailedEventsPdf(events, dateFormat, languageCode);
    final fileName = 'eventos_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
    final file = await _savePdfToTemp(pdf, fileName);
    await Share.shareXFiles([XFile(file.path)], text: 'Relatório de Eventos - FinAgeVoz');
  }

  static pw.Document _buildDetailedEventsPdf(
    List<Event> events,
    DateFormat dateFormat,
    String languageCode,
  ) {
    final pdf = pw.Document();

    // Separate cancelled and active events
    final activeEvents = events.where((e) => !e.isCancelled).toList();
    final cancelledEvents = events.where((e) => e.isCancelled).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(AppLocalizations.t('events_report_title', languageCode), style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                      pw.Text('FinAgeVoz', style: pw.TextStyle(fontSize: 18, color: PdfColors.grey)),
                      pw.Text('Gerado em: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}', style: pw.TextStyle(fontSize: 10, color: PdfColors.black)),
                  ]),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(AppLocalizations.t('total_events', languageCode), style: const pw.TextStyle(fontSize: 12)),
                    pw.Text('${events.length}', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(AppLocalizations.t('active_events', languageCode), style: const pw.TextStyle(fontSize: 12)),
                    pw.Text('${activeEvents.length}', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.green)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(AppLocalizations.t('cancelled_events', languageCode), style: const pw.TextStyle(fontSize: 12)),
                    pw.Text('${cancelledEvents.length}', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.red)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            if (activeEvents.isNotEmpty) ...[
              pw.Text(AppLocalizations.t('active_events_title', languageCode), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.green),
                cellAlignment: pw.Alignment.centerLeft,
                headers: [
                  AppLocalizations.t('table_date', languageCode),
                  AppLocalizations.t('table_title', languageCode),
                  AppLocalizations.t('table_description', languageCode)
                ],
                data: activeEvents.map((e) {
                  return [
                    dateFormat.format(e.date),
                    e.title,
                    e.description,
                  ];
                }).toList(),
              ),
              pw.SizedBox(height: 20),
            ],
            if (cancelledEvents.isNotEmpty) ...[
              pw.Text(AppLocalizations.t('cancelled_events_title', languageCode), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.red),
                cellAlignment: pw.Alignment.centerLeft,
                headers: [
                  AppLocalizations.t('table_date', languageCode),
                  AppLocalizations.t('table_title', languageCode),
                  AppLocalizations.t('table_description', languageCode)
                ],
                data: cancelledEvents.map((e) {
                  return [
                    dateFormat.format(e.date),
                    e.title,
                    e.description,
                  ];
                }).toList(),
              ),
            ],
          ];
        },
      ),
    );
    return pdf;
  }

  static Future<void> generateAgendaReport(
    List<AgendaItem> items,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    final pdf = _buildAgendaReportPdf(items, startDate, endDate);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'agenda_inteligente_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  static Future<void> shareAgendaReport(
    List<AgendaItem> items,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    final pdf = _buildAgendaReportPdf(items, startDate, endDate);
    final fileName = 'agenda_inteligente_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
    final file = await _savePdfToTemp(pdf, fileName);
    await Share.shareXFiles([XFile(file.path)], text: 'Relatório Agenda Inteligente - FinAgeVoz');
  }

  static pw.Document _buildAgendaReportPdf(
    List<AgendaItem> items,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');

    // Group items by type
    final compromissos = items.where((i) => i.tipo == AgendaItemType.COMPROMISSO || i.tipo == AgendaItemType.TAREFA).toList();
    final aniversarios = items.where((i) => i.tipo == AgendaItemType.ANIVERSARIO).toList();
    final remedios = items.where((i) => i.tipo == AgendaItemType.REMEDIO).toList();
    final pagamentos = items.where((i) => i.tipo == AgendaItemType.PAGAMENTO).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                   pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                      pw.Text('Agenda Inteligente', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Relatório Detalhado', style: pw.TextStyle(fontSize: 14)),
                   ]),
                   pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                      pw.Text('FinAgeVoz', style: pw.TextStyle(fontSize: 18, color: PdfColors.grey)),
                      pw.Text('Gerado em: ${dateFormat.format(DateTime.now())} ${timeFormat.format(DateTime.now())}', style: pw.TextStyle(fontSize: 10, color: PdfColors.black)),
                   ]),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Período: ${startDate != null ? dateFormat.format(startDate) : "Início"} - ${endDate != null ? dateFormat.format(endDate) : "Fim"}'),
                pw.Text('Total de Itens: ${items.length}'),
              ],
            ),
            pw.SizedBox(height: 20),
            
            // 1. Compromissos e Tarefas
            if (compromissos.isNotEmpty) ...[
               pw.Header(level: 1, text: "Compromissos e Tarefas"),
               pw.Table.fromTextArray(
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.blue),
                  cellAlignment: pw.Alignment.centerLeft,
                  headers: ['Data/Hora', 'Título', 'Descrição', 'Status'],
                  data: compromissos.map((i) {
                     String dh = i.dataInicio != null ? dateFormat.format(i.dataInicio!) : "-";
                     if (i.horarioInicio != null) dh += " ${i.horarioInicio}";
                     return [dh, i.titulo, i.descricao ?? '', i.status.toString().split('.').last];
                  }).toList(),
               ),
               pw.SizedBox(height: 15),
            ],

            // 2. Aniversários
            if (aniversarios.isNotEmpty) ...[
               pw.Header(level: 1, text: "Aniversários"),
               pw.Table.fromTextArray(
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.pink),
                  cellAlignment: pw.Alignment.centerLeft,
                  headers: ['Data', 'Aniversariante', 'Mensagem Padrão'],
                  data: aniversarios.map((i) {
                     String dh = i.dataInicio != null ? dateFormat.format(i.dataInicio!) : "-";
                     return [dh, i.aniversario?.nomePessoa ?? i.titulo, i.aniversario?.mensagemPadrao ?? ''];
                  }).toList(),
               ),
               pw.SizedBox(height: 15),
            ],

            // 3. Remédios
            if (remedios.isNotEmpty) ...[
               pw.Header(level: 1, text: "Medicação"),
               pw.Table.fromTextArray(
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.purple),
                  cellAlignment: pw.Alignment.centerLeft,
                  headers: ['Remédio', 'Horário', 'Dosagem', 'Status'],
                  data: remedios.map((i) {
                     String dh = i.dataInicio != null ? dateFormat.format(i.dataInicio!) : "-";
                     if (i.horarioInicio != null) dh += " ${i.horarioInicio}";
                     // Virtual items might have 'created' date as reference if dataInicio is missing, but usually virtual items have specific date
                     return [
                        i.remedio?.nome ?? i.titulo,
                        dh,
                        i.remedio?.dosagem ?? '-',
                        i.status.toString().split('.').last
                     ];
                  }).toList(),
               ),
               pw.SizedBox(height: 15),
            ],

            // 4. Pagamentos
            if (pagamentos.isNotEmpty) ...[
               pw.Header(level: 1, text: "Pagamentos"),
               pw.Table.fromTextArray(
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.green),
                  cellAlignment: pw.Alignment.centerLeft,
                  headers: ['Vencimento', 'Descrição', 'Valor', 'Status'],
                  data: pagamentos.map((i) {
                     String dh = i.dataInicio != null ? dateFormat.format(i.dataInicio!) : "-";
                     final val = i.pagamento != null ? "R\$ ${i.pagamento!.valor.toStringAsFixed(2)}" : "-";
                     return [dh, i.titulo, val, i.pagamento?.status ?? 'PENDENTE'];
                  }).toList(),
               ),
               pw.SizedBox(height: 15),
            ],
          ];
        },
      ),
    );
    return pdf;
  }

  static Future<File> _savePdfToTemp(pw.Document pdf, String fileName) async {
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}

