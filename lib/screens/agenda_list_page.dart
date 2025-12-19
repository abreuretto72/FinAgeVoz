import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../utils/localization.dart';

import '../models/agenda_models.dart';
import '../models/medicine_model.dart';
import '../models/transaction_model.dart';
import '../utils/hive_setup.dart';
import '../services/agenda_repository.dart';
import '../services/medicine_service.dart';
import '../services/database_service.dart';
import 'agenda_form_screen.dart';
import '../widgets/edit_transaction_dialog.dart';
import 'medicines/medicine_list_screen.dart';
import 'medicines/medicine_form_screen.dart';
import '../services/pdf_service.dart';
import '../services/agenda_csv_service.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class AgendaListPage extends StatefulWidget {
  const AgendaListPage({super.key});

  @override
  State<AgendaListPage> createState() => _AgendaListPageState();
}

class _AgendaListPageState extends State<AgendaListPage> {
  final repo = AgendaRepository();
  final MedicineService _medService = MedicineService();
  final DatabaseService _db = DatabaseService();

  String get _currentLanguage => Localizations.localeOf(context).toString();

  void _handleMedicineAction(AgendaItem item) {
    if (item.remedio == null || item.remedio!.id == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro: Item de remédio inválido ou sem ID.')));
        return;
    }
    
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('Marcar como Tomado'),
              onTap: () {
                 // TODO: Implement mark as taken
                 Navigator.pop(ctx);
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Em breve: Marcar como tomado')));
              },
            ),
            ListTile(
               leading: const Icon(Icons.edit, color: Colors.blue),
               title: const Text('Editar Remédio'),
               onTap: () async {
                  Navigator.pop(ctx);
                  final remedio = _db.getRemedio(item.remedio!.id!);
                  if (remedio != null) {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => MedicineFormScreen(remedio: remedio)));
                  } else {
                     if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: Remédio não encontrado no banco de dados (ID: ${item.remedio!.id}).')));
                     }
                  }
               },
            ),
             ListTile(
               leading: const Icon(Icons.rule, color: Colors.orange),
               title: const Text('Gerenciar Posologia'),
               onTap: () async {
                   Navigator.pop(ctx);
                   final remedio = _db.getRemedio(item.remedio!.id!);
                    if (remedio != null && item.remedio!.posologiaId != null) {
                      // We can go to posology editing directly if we want, but MedicineForm is safer entry
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => MedicineFormScreen(remedio: remedio)));
                    }
               }
            ),
        ],
      ),
      )
    );
  }

  void _handlePaymentAction(AgendaItem item) {
    if (item.pagamento?.transactionId == null) return;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Registro Vinculado"),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text("Registros da aba Pagamentos não podem ser editados aqui. Edite o lançamento financeiro correspondente."),
             SizedBox(height: 12),
             Text("Você será redirecionado para o lançamento original.", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.open_in_new),
            label: const Text("Ir para Financeiro"),
            onPressed: () async {
               Navigator.pop(ctx);
               // Find Transaction and Open Edit Dialog
               try {
                 final transaction = _db.getTransactions().firstWhere((t) => t.id == item.pagamento!.transactionId);
                 
                 await showDialog(
                   context: context,
                   builder: (context) => EditTransactionDialog(
                     transaction: transaction,
                     dbService: _db,
                     currentLanguage: _currentLanguage,
                   ),
                 );
                 
                 // Refresh UI after coming back (sync happens automatically in DB service)
                 setState(() {}); 
               } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transação original não encontrada (possivelmente excluída).')));
                    // Se não achou, talvez devêssemos oferecer para excluir o fantasma da agenda?
                    // Mas o sync deve tratar.
                  }
               }
            },
          ),
        ],
      ),
    );
  }



  /// Centralized method to fetch all items (manual + virtual)
  List<AgendaItem> _getAllItems({DateTime? rangeStart, DateTime? rangeEnd}) {
      // Filter: Exclude Paid items (Visual Safety Net)
      // The user strictly wants only PENDING items in this list.
      final manualItems = agendaBox.values.where((i) {
         if (i.status == ItemStatus.CONCLUIDO) return false;
         if (i.pagamento != null && (i.pagamento!.status == 'PAGO' || i.pagamento!.status == 'CONCLUIDO')) return false;
         return true;
      }).toList();
      
      final virtualItems = <AgendaItem>[];

      // Transactions -> Agenda
      // Transactions -> Agenda (Virtual Items REMOVED - Now managed by Source of Truth Sync in DatabaseService)
      // Earlier logic generated virtual items on the fly. Now, they are persisted synced copies.
      // Keeping this comment block to confirm removal of duplicate logic.
      
      // Medicines -> Agenda (Virtual items for future doses)
      // Default range for list view is usually -2 days to +30 days if not specified
      final now = DateTime.now();
      final effectiveStart = rangeStart ?? now.subtract(const Duration(days: 2));
      final effectiveEnd = rangeEnd ?? now.add(const Duration(days: 30)); 
      
      final allRemedios = _db.getRemedios();
      for (var r in allRemedios) {
          final posologias = _db.getPosologias(r.id);
          for (var p in posologias) {
              final doses = _medService.calculateNextDoses(p, effectiveStart, limit: 100); 
              for (var d in doses) {
                  if (d.isAfter(effectiveEnd)) break;
                  // Only add if after start
                  if (d.isBefore(effectiveStart)) continue;
                  
                  virtualItems.add(_medService.createVirtualAgendaItem(r, p, d));
              }
          }
      }

      final allItems = [...manualItems, ...virtualItems];
      
      // Filter manual items by date if range is provided
      if (rangeStart != null || rangeEnd != null) {
         allItems.removeWhere((item) {
             final d = item.dataInicio ?? item.criadoEm;
             if (rangeStart != null && d.isBefore(rangeStart)) return true;
             if (rangeEnd != null && d.isAfter(rangeEnd)) return true;
             return false;
         });
      }

      allItems.sort((a, b) {
          final da = a.dataInicio ?? a.criadoEm;
          final db = b.dataInicio ?? b.criadoEm;
          return da.compareTo(db);
      });
      
      return allItems;
  }

  Future<void> _showPdfFilterDialog() async {
    // Default vars
    DateTime? startDate = DateTime.now();
    DateTime? endDate = DateTime.now().add(const Duration(days: 7));
    bool includeCompromissos = true;
    bool includeAniversarios = true;
    bool includeRemedios = true;
    bool includePagamentos = true;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Filtrar Relatório PDF'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Selecione o período e os tipos de eventos para o relatório.', style: TextStyle(fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 15),
                    
                    // Date Range
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text("Início: ${DateFormat.yMd(Localizations.localeOf(context).toString()).format(startDate!)}"),
                      trailing: const Icon(Icons.calendar_today, size: 20),
                      onTap: () async {
                         final d = await showDatePicker(context: context, initialDate: startDate!, firstDate: DateTime(2020), lastDate: DateTime(2030));
                         if (d != null) setState(() => startDate = d);
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text("Fim: ${DateFormat.yMd(Localizations.localeOf(context).toString()).format(endDate!)}"),
                      trailing: const Icon(Icons.calendar_today, size: 20),
                      onTap: () async {
                         final d = await showDatePicker(context: context, initialDate: endDate!, firstDate: DateTime(2020), lastDate: DateTime(2030));
                         if (d != null) setState(() => endDate = d);
                      },
                    ),
                    const Divider(),
                    
                    // Types
                    CheckboxListTile(
                      title: const Text("Compromissos/Tarefas"),
                      value: includeCompromissos,
                      onChanged: (v) => setState(() => includeCompromissos = v!),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    CheckboxListTile(
                      title: const Text("Aniversários"),
                      value: includeAniversarios,
                      onChanged: (v) => setState(() => includeAniversarios = v!),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    CheckboxListTile(
                      title: const Text("Remédios"),
                      value: includeRemedios,
                      onChanged: (v) => setState(() => includeRemedios = v!),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    CheckboxListTile(
                      title: const Text("Pagamentos"),
                      value: includePagamentos,
                      onChanged: (v) => setState(() => includePagamentos = v!),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Gerar PDF'),
                  onPressed: () async {
                    Navigator.pop(context);
                    
                    // Fetch items based on Date Range
                    // Note: We might want slightly wider range or exact.
                    // Let's us exact range end of day
                    final start = DateTime(startDate!.year, startDate!.month, startDate!.day);
                    final end = DateTime(endDate!.year, endDate!.month, endDate!.day, 23, 59, 59);

                    var items = _getAllItems(rangeStart: start, rangeEnd: end);
                    
                    // Filter Types
                    items = items.where((i) {
                       if (i.tipo == AgendaItemType.COMPROMISSO || i.tipo == AgendaItemType.TAREFA) return includeCompromissos;
                       if (i.tipo == AgendaItemType.ANIVERSARIO) return includeAniversarios;
                       if (i.tipo == AgendaItemType.REMEDIO) return includeRemedios;
                       if (i.tipo == AgendaItemType.PAGAMENTO) return includePagamentos;
                       return true;
                    }).toList();

                    if (items.isEmpty) {
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nenhum item encontrado para os filtros selecionados.')));
                       return;
                    }

                    // Generate Actions
                    showModalBottomSheet(
                       context: context,
                       builder: (ctx) {
                          return SafeArea(
                            child: Column(
                               mainAxisSize: MainAxisSize.min,
                               children: [
                                  ListTile(
                                    leading: const Icon(Icons.share),
                                    title: const Text('Compartilhar PDF'),
                                    onTap: () async {
                                       Navigator.pop(ctx);
                                       await PdfService.shareAgendaReport(items, start, end, _currentLanguage);
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.print),
                                    title: const Text('Imprimir'),
                                    onTap: () async {
                                       Navigator.pop(ctx);
                                       await PdfService.generateAgendaReport(items, start, end, _currentLanguage);
                                    },
                                  )
                               ]
                            ),
                          );
                       }
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
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
              title: const Text('Exportar CSV'),
              subtitle: const Text('Salvar backup ou abrir em Excel'),
              onTap: () {
                Navigator.pop(ctx);
                _showExportFilterCsvDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_download),
              title: const Text('Importar CSV'),
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
          
          final service = AgendaCsvService();
          // Show loading
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Processando importação...')));
          }
          
          final report = await service.importCsv(content);
          
          if (mounted) {
             showDialog(
                context: context, 
                builder: (ctx) => AlertDialog(
                   title: const Text("Importação Concluída"),
                   content: Text("Itens importados: ${report['imported']}\nItens ignorados (duplicados): ${report['ignored']}"),
                   actions: [TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text("OK"))],
                )
             );
             setState(() {}); // Refresh list
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
    bool allTypes = true;
    bool includeCompromissos = true;
    bool includeRemedios = true;
    bool includeAniversarios = true;
    bool includePagamentos = true;

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
                      const Text("Selecione o período e tipos.", style: TextStyle(color: Colors.grey)),
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
                        title: const Text("Compromissos"),
                        value: includeCompromissos,
                        onChanged: (v) => setState(() => includeCompromissos = v!),
                      ),
                      CheckboxListTile(
                        title: const Text("Remédios"),
                        value: includeRemedios,
                        onChanged: (v) => setState(() => includeRemedios = v!),
                      ),
                      CheckboxListTile(
                        title: const Text("Aniversários"),
                        value: includeAniversarios,
                        onChanged: (v) => setState(() => includeAniversarios = v!),
                      ),
                       CheckboxListTile(
                        title: const Text("Pagamentos"),
                        value: includePagamentos,
                        onChanged: (v) => setState(() => includePagamentos = v!),
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
                       var all = _getAllItems(rangeStart: startDate, rangeEnd: endDate);
                       // _getAllItems usually filters by range if provided.
                       // However, _getAllItems implementation logic for range is:
                       /*
                         if (rangeStart != null || rangeEnd != null) {
                             allItems.removeWhere...
                         }
                       */
                       // But if startDate is null, it returns everything (which is what we want for "Todo o periodo").
                       // Wait, _getAllItems default logic (lines 138+) uses default range if NOT provided?
                       // Let's check _getAllItems:
                       // "final effectiveStart = rangeStart ?? now.subtract(const Duration(days: 2));"
                       
                       // So if I pass NULL, it defaults to localized view. 
                       // I need to implement a dedicated "GetAllForExport" or pass a special flag.
                       // Or just manually iterate Repo.
                       
                       var itemsToExport = <AgendaItem>[];

                       if (startDate == null) {
                           // Get ALL from Repo directly to avoid "View Range" limitations
                           // But manual Items only.
                           // For Virtual Items (Remedies), we need to generate them for a reasonable range?
                           // "Exportar Agenda Recorrente para CSV" is tricky. Infinite series.
                           // Convention: For Export "All", we usually export the DEFINITIONS (Manual items) + Transactions.
                           // Virtual Occurrences are ephemeral.
                           // BUT the prompt says "Conteúdo... Data de Início...".
                           // If I have a recurring medicine 3x/day, do I export 1000 lines?
                           // The prompt says "Recorrência (Ex: Diária)". This implies defining the Rule, NOT the occurrences.
                           
                           // So I should fetch Manual Items from Repo.
                           itemsToExport = repo.getAll(); // Manual only.
                           
                           // And add Transactions (Payments)
                           final trans = _db.getTransactions();
                           for (var t in trans) {
                               itemsToExport.add(AgendaItem(
                                  tipo: AgendaItemType.PAGAMENTO,
                                  titulo: t.description,
                                  dataInicio: t.date,
                                  status: t.isPaid ? ItemStatus.CONCLUIDO : ItemStatus.PENDENTE,
                                  pagamento: PagamentoInfo(
                                     valor: t.amount, 
                                     status: t.isPaid ? 'PAGO' : 'PENDENTE', 
                                     dataVencimento: t.date,
                                     transactionId: t.id
                                  )
                               ));
                           }

                       } else {
                           // If Range defined, maybe we export occurrences?
                           // Let's stick to Definitions within range + Occurrences?
                           // Prompt: "Recorrência... Data de Fim...".
                           // It seems the user wants the LIST of items.
                           // If I have a recurring event, I export the event object.
                           itemsToExport = _getAllItems(rangeStart: startDate, rangeEnd: endDate);
                           // NOTE: _getAllItems generates VIRTUAL occurrences for Remedies.
                           // This might be what the user wants if filtering by Date Range.
                       }

                       // Filter Types
                       itemsToExport = itemsToExport.where((i) {
                           if ((i.tipo == AgendaItemType.COMPROMISSO || i.tipo == AgendaItemType.TAREFA) && !includeCompromissos) return false;
                           if (i.tipo == AgendaItemType.REMEDIO && !includeRemedios) return false;
                           if (i.tipo == AgendaItemType.ANIVERSARIO && !includeAniversarios) return false;
                           if (i.tipo == AgendaItemType.PAGAMENTO && !includePagamentos) return false;
                           return true;
                       }).toList();

                       if (itemsToExport.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nenhum item para exportar.")));
                          return;
                       }
                       
                       final service = AgendaCsvService();
                       final csv = service.generateCsv(itemsToExport);
                       final filename = "agenda_export_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv";
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
    return FutureBuilder(
      future: ensureAgendaBoxOpen(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        
        return DefaultTabController(
          length: 4,
          child: Scaffold(
            appBar: AppBar(
               title: const Text('Agenda Inteligente'),
               bottom: const TabBar(
                 tabs: [
                   Tab(text: 'Compromissos'),
                   Tab(text: 'Aniversários'),
                   Tab(text: 'Remédios'),
                   Tab(text: 'Pagamentos'),
                 ],
               ),
               actions: [
                 IconButton(
                   icon: const Icon(Icons.search),
                   tooltip: "Buscar na aba atual",
                   onPressed: () {
                     showSearch(
                       context: context,
                       delegate: AgendaSearchDelegate(
                         allItems: _getAllItems(),
                         currentLanguage: _currentLanguage,
                       ),
                     );
                   },
                 ),
                 IconButton(
                   icon: const Icon(Icons.import_export),
                   tooltip: "Importar/Exportar CSV",
                   onPressed: _showImportExportOptions,
                 ),
                 IconButton(
                   icon: const Icon(Icons.picture_as_pdf),
                   tooltip: "Relatório PDF",
                   onPressed: _showPdfFilterDialog,
                 ),

               ],
            ),
            body: ListenableBuilder(
              listenable: Listenable.merge([
                  agendaBox.listenable(),
                  Hive.box<Transaction>('transactions').listenable(),
                  Hive.box<Remedio>('remedios').listenable(),
                  Hive.box<Posologia>('posologias').listenable(),
                  Hive.box<HistoricoTomada>('historico_tomadas').listenable(),
              ]),
              builder: (context, _) {
                final allItems = _getAllItems(); // Uses default range for view
                
                final compromissos = <AgendaItem>[];
                final aniversarios = <AgendaItem>[];
                final remedios = <AgendaItem>[];
                final pagamentos = <AgendaItem>[];
                
                for (var item in allItems) {
                   if (item.tipo == AgendaItemType.ANIVERSARIO) {
                      aniversarios.add(item);
                   } else if (item.tipo == AgendaItemType.REMEDIO) {
                      remedios.add(item);
                   } else if (item.tipo == AgendaItemType.PAGAMENTO) {
                      // IGNORAR itens da AgendaBox para esta aba.
                      // A aba Pagamentos é populada exclusivamente via _db.getTransactions() abaixo.
                      continue; 
                  } else {
                      compromissos.add(item);
                   }
                }
                
                // --- ORIGEM EXCLUSIVA: MÓDULO FINANCEIRO ---
                // Popula a aba Pagamentos apenas com lançamentos PENDENTES.
                final transactions = _db.getTransactions();
                for (var t in transactions) {
                   // FILTRO RIGOROSO: Apenas não pagos/não realizados (Regra de Ouro: isRealized == true -> Excluir)
                   if (t.isRealized) continue;
                   
                   // Criar item espelho (Somente Leitura)
                   pagamentos.add(AgendaItem(
                       tipo: AgendaItemType.PAGAMENTO,
                       titulo: "${t.isExpense ? 'Pagar' : 'Receber'}: ${t.description}",
                       dataInicio: t.date, 
                       horarioInicio: null,
                       status: ItemStatus.PENDENTE,
                       pagamento: PagamentoInfo(
                          transactionId: t.id,
                          valor: t.amount,
                          status: 'PENDENTE',
                          dataVencimento: t.date,
                       )
                   ));
                }
                
                // Ordenar Pagamentos por data de vencimento
                pagamentos.sort((a, b) {
                    final da = a.dataInicio ?? DateTime.now();
                    final db = b.dataInicio ?? DateTime.now();
                    return da.compareTo(db);
                });

                // Sort anniversaries by next occurrence
                aniversarios.sort((a, b) {
                   final nextA = _getNextBirthday(a.dataInicio);
                   final nextB = _getNextBirthday(b.dataInicio);
                   return nextA.compareTo(nextB);
                });

                return TabBarView(
                  children: [
                    _buildList(compromissos, emptyMsg: 'Nenhum compromisso.'),
                    _buildList(aniversarios, emptyMsg: 'Nenhum aniversário.', useNextAnniversaryDate: true),
                    _buildList(remedios, emptyMsg: 'Nenhum remédio agendado.'),
                    _buildList(pagamentos, emptyMsg: 'Nenhum pagamento agendado.'),
                  ],
                );
              },
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AgendaFormScreen())),
              child: const Icon(Icons.add),
            ),
          ),
        );
       },
    );
   }

   Widget _buildList(List<AgendaItem> itens, {required String emptyMsg, bool useNextAnniversaryDate = false}) {
       if (itens.isEmpty) {
            return Center(child: Text(emptyMsg));
       }
       return ListView.builder(
            itemCount: itens.length,
            padding: const EdgeInsets.only(bottom: 80),
            itemBuilder: (context, index) {
              final item = itens[index];
              DateTime date = item.dataInicio ?? item.criadoEm;
              
              if (useNextAnniversaryDate && item.tipo == AgendaItemType.ANIVERSARIO) {
                 date = _getNextBirthday(date);
              }

              bool showHeader = true;
              if (index > 0) {
                final prev = itens[index - 1];
                DateTime prevDate = prev.dataInicio ?? prev.criadoEm;
                if (useNextAnniversaryDate && prev.tipo == AgendaItemType.ANIVERSARIO) {
                   prevDate = _getNextBirthday(prevDate);
                }
                
                if (_isSameDay(date, prevDate)) showHeader = false;
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showHeader)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Text(
                        _getDateHeader(date, _currentLanguage),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                      ),
                    ),
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                     child: ListTile(
                       leading: _buildLeadingIcon(item),
                       title: Text(item.titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
                       subtitle: Text(_buildSubtitle(item)),
                       trailing: item.tipo == AgendaItemType.REMEDIO 
                         ? IconButton(
                             icon: const Icon(Icons.edit, color: Colors.blue),
                             onPressed: () {
                               if (item.remedio != null && item.remedio!.id != null) {
                                 _handleMedicineAction(item);
                               }
                             },
                           )
                         : item.tipo == AgendaItemType.PAGAMENTO && item.pagamento?.transactionId != null
                           ? const Icon(Icons.lock, size: 16, color: Colors.grey)
                           : Row(
                               mainAxisSize: MainAxisSize.min,
                               children: [
                                 IconButton(
                                   icon: const Icon(Icons.edit, color: Colors.blue),
                                   onPressed: () {
                                     Navigator.push(context, MaterialPageRoute(builder: (_) => AgendaFormScreen(item: item)));
                                   },
                                 ),
                                 IconButton(
                                   icon: const Icon(Icons.delete, color: Colors.grey),
                                   onPressed: () => showDialog(
                                     context: context, 
                                     builder: (ctx) => AlertDialog(
                                        title: const Text("Excluir item?"),
                                        content: Text("Tem certeza que deseja excluir '${item.titulo}'?"),
                                        actions: [
                                           TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
                                           TextButton(onPressed: () { 
                                              repo.deleteItem(item); 
                                              Navigator.pop(ctx); 
                                           }, child: const Text("Excluir", style: TextStyle(color: Colors.red))),
                                        ],
                                     )
                                   ),
                                 ),
                               ],
                             ),
                       onTap: () {
                          if (item.remedio != null && item.remedio!.id != null) {
                              _handleMedicineAction(item);
                          } else if (item.tipo == AgendaItemType.PAGAMENTO && item.pagamento?.transactionId != null) {
                              _handlePaymentAction(item);
                          } else {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => AgendaFormScreen(item: item)));
                          }
                       },
                    ),
                  ),
                ],
              );
            },
          );
   }

  Icon _buildLeadingIcon(AgendaItem item) {
    if (item.remedio != null) {
         if (item.status == ItemStatus.CONCLUIDO) return const Icon(Icons.check_circle, color: Colors.green);
         return const Icon(Icons.medication, color: Colors.purple);
    }
    switch (item.tipo) {
      case AgendaItemType.COMPROMISSO:
        return const Icon(Icons.event);
      case AgendaItemType.TAREFA:
        return const Icon(Icons.check_circle_outline);
      case AgendaItemType.PAGAMENTO:
        return const Icon(Icons.attach_money);
      case AgendaItemType.REMEDIO:
        return const Icon(Icons.medication);
      case AgendaItemType.ANIVERSARIO:
        return const Icon(Icons.cake);
      default:
        return const Icon(Icons.more_horiz);
    }
  }

  String _buildSubtitle(AgendaItem item) {
    final buffer = StringBuffer();

    if (item.dataInicio != null) {
      final d = item.dataInicio!;
      buffer.write(DateFormat.yMd(Localizations.localeOf(context).toString()).format(d));
    }

    if (item.horarioInicio != null) {
      if (buffer.isNotEmpty) buffer.write(' ');
      buffer.write(item.horarioInicio);
    }

    if (item.tipo == AgendaItemType.PAGAMENTO && item.pagamento != null) {
      if (buffer.isNotEmpty) buffer.write(' • ');
      final currency = NumberFormat.simpleCurrency(locale: Localizations.localeOf(context).toString()).format(item.pagamento!.valor);
      buffer.write('$currency (${item.pagamento!.status})');
    }

    if (item.remedio != null) {
       // Only show specific status if relevant
    }

    if (item.tipo == AgendaItemType.ANIVERSARIO && item.aniversario != null) {
      if (buffer.isNotEmpty) buffer.write(' • ');
      buffer.write('Aniversário de ${item.aniversario!.nomePessoa}');
    }

    return buffer.toString();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _getDateHeader(DateTime d, String locale) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final check = DateTime(d.year, d.month, d.day);

    if (check.isAtSameMomentAs(today)) return AppLocalizations.t('today', locale);
    if (check.isAtSameMomentAs(tomorrow)) return AppLocalizations.t('tomorrow', locale);
    return DateFormat('EEEE, d MMM', locale).format(d);
  }
  DateTime _getNextBirthday(DateTime? birthDate) {
    if (birthDate == null) return DateTime(2100);
    final now = DateTime.now();
    DateTime next = DateTime(now.year, birthDate.month, birthDate.day);
    // Compare date components only
    final today = DateTime(now.year, now.month, now.day);
    if (next.isBefore(today)) {
      next = DateTime(now.year + 1, birthDate.month, birthDate.day);
    }
    return next;
  }
}

// Search Delegate for Agenda
class AgendaSearchDelegate extends SearchDelegate<AgendaItem?> {
  final List<AgendaItem> allItems;
  final String currentLanguage;

  AgendaSearchDelegate({
    required this.allItems,
    required this.currentLanguage,
  });

  @override
  String get searchFieldLabel => 'Buscar na agenda...';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    if (query.isEmpty) {
      return const Center(
        child: Text('Digite algo para buscar...'),
      );
    }

    // Filter using 'contains' (case insensitive)
    final results = allItems.where((item) {
      final queryLower = query.toLowerCase();
      final titleLower = item.titulo.toLowerCase();
      final descLower = (item.descricao ?? '').toLowerCase();
      
      return titleLower.contains(queryLower) || descLower.contains(queryLower);
    }).toList();

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Nenhum resultado para "$query"'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: _getIcon(item),
            title: Text(item.titulo),
            subtitle: Text(_getSubtitle(item)),
            onTap: () {
              close(context, item);
            },
          ),
        );
      },
    );
  }

  Icon _getIcon(AgendaItem item) {
    switch (item.tipo) {
      case AgendaItemType.COMPROMISSO:
        return const Icon(Icons.event, color: Colors.blue);
      case AgendaItemType.TAREFA:
        return const Icon(Icons.check_circle_outline, color: Colors.green);
      case AgendaItemType.PAGAMENTO:
        return const Icon(Icons.attach_money, color: Colors.orange);
      case AgendaItemType.REMEDIO:
        return const Icon(Icons.medication, color: Colors.purple);
      case AgendaItemType.ANIVERSARIO:
        return const Icon(Icons.cake, color: Colors.pink);
      default:
        return const Icon(Icons.more_horiz);
    }
  }

  String _getSubtitle(AgendaItem item) {
    final buffer = StringBuffer();
    
    if (item.dataInicio != null) {
      buffer.write(DateFormat.yMd(currentLanguage).format(item.dataInicio!));
    }
    
    if (item.horarioInicio != null) {
      if (buffer.isNotEmpty) buffer.write(' ');
      buffer.write(item.horarioInicio);
    }
    
    if (item.descricao != null && item.descricao!.isNotEmpty) {
      if (buffer.isNotEmpty) buffer.write(' • ');
      buffer.write(item.descricao);
    }
    
    return buffer.toString();
  }
}
