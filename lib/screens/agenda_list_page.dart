import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../models/agenda_models.dart';
import '../models/medicine_model.dart';
import '../models/transaction_model.dart';
import '../utils/hive_setup.dart';
import '../services/agenda_repository.dart';
import '../services/medicine_service.dart';
import '../services/database_service.dart';
import 'agenda_form_screen.dart';
import 'medicines/medicine_list_screen.dart';
import 'medicines/medicine_form_screen.dart';
import '../services/pdf_service.dart';

class AgendaListPage extends StatefulWidget {
  const AgendaListPage({super.key});

  @override
  State<AgendaListPage> createState() => _AgendaListPageState();
}

class _AgendaListPageState extends State<AgendaListPage> {
  final repo = AgendaRepository();
  final MedicineService _medService = MedicineService();
  final DatabaseService _db = DatabaseService();

  void _handleMedicineAction(AgendaItem item) {
    if (item.remedio == null || item.remedio!.id == null) return;
    
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
    
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('Confirmar Pagamento'),
              subtitle: Text('R\$ ${item.pagamento!.valor.toStringAsFixed(2)}'),
              onTap: () async {
                 Navigator.pop(ctx);
                 await _db.markTransactionAsPaid(item.pagamento!.transactionId!, DateTime.now());
                 if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pagamento confirmado e registrado!')));
                 }
              },
            ),
             ListTile(
               leading: const Icon(Icons.info_outline, color: Colors.blue),
               title: const Text('Ver Detalhes'),
               onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pressione e segure para mais opções')));
               },
            ),
          ],
        ),
      ),
    );
  }



  /// Centralized method to fetch all items (manual + virtual)
  List<AgendaItem> _getAllItems({DateTime? rangeStart, DateTime? rangeEnd}) {
      final manualItems = agendaBox.values.toList();
      final virtualItems = <AgendaItem>[];

      // Transactions -> Agenda
      final transactionBox = Hive.box<Transaction>('transactions');
      for (var t in transactionBox.values) {
          if (t.isExpense && 
              (t.totalInstallments ?? 0) > 1 && 
              (t.installmentNumber ?? 0) > 0 &&
              !t.isDeleted &&
              !t.isPaid) {
              
              if (rangeStart != null && t.date.isBefore(rangeStart)) continue;
              if (rangeEnd != null && t.date.isAfter(rangeEnd)) continue;

              virtualItems.add(AgendaItem(
                  tipo: AgendaItemType.PAGAMENTO,
                  titulo: "${t.description} (${t.installmentNumber}/${t.totalInstallments})",
                  dataInicio: t.date,
                  horarioInicio: "08:00",
                  status: t.isPaid ? ItemStatus.CONCLUIDO : ItemStatus.PENDENTE,
                  pagamento: PagamentoInfo(
                      valor: t.amount,
                      status: t.isPaid ? "PAGO" : "PENDENTE",
                      dataVencimento: t.date,
                      descricaoFinanceira: "Parcela ${t.installmentNumber}/${t.totalInstallments}",
                      transactionId: t.id,
                  )
              ));
          }
      }
      
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
                      title: Text("Início: ${DateFormat('dd/MM/yyyy').format(startDate!)}"),
                      trailing: const Icon(Icons.calendar_today, size: 20),
                      onTap: () async {
                         final d = await showDatePicker(context: context, initialDate: startDate!, firstDate: DateTime(2020), lastDate: DateTime(2030));
                         if (d != null) setState(() => startDate = d);
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text("Fim: ${DateFormat('dd/MM/yyyy').format(endDate!)}"),
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
                                       await PdfService.shareAgendaReport(items, start, end);
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.print),
                                    title: const Text('Imprimir'),
                                    onTap: () async {
                                       Navigator.pop(ctx);
                                       await PdfService.generateAgendaReport(items, start, end);
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
                      pagamentos.add(item);
                  } else {
                      compromissos.add(item);
                   }
                }

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
                        _getDateHeader(date),
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
                      trailing: item.remedio == null ? IconButton(
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
                      ) : const Icon(Icons.auto_awesome, size: 16, color: Colors.purpleAccent),
                       onTap: () {
                          if (item.remedio != null) {
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
      buffer.write('${d.day}/${d.month}/${d.year}');
    }

    if (item.horarioInicio != null) {
      if (buffer.isNotEmpty) buffer.write(' ');
      buffer.write(item.horarioInicio);
    }

    if (item.tipo == AgendaItemType.PAGAMENTO && item.pagamento != null) {
      if (buffer.isNotEmpty) buffer.write(' • ');
      buffer.write(
          'R\$ ${item.pagamento!.valor.toStringAsFixed(2)} (${item.pagamento!.status})');
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

  String _getDateHeader(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final check = DateTime(d.year, d.month, d.day);

    if (check.isAtSameMomentAs(today)) return "Hoje";
    if (check.isAtSameMomentAs(tomorrow)) return "Amanhã";
    return DateFormat('EEEE, d MMM', 'pt_BR').format(d);
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
