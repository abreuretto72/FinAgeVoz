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
                   icon: const Icon(Icons.medication),
                   tooltip: "Gerenciar Remédios",
                   onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MedicineListScreen())),
                 )
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
                
                final now = DateTime.now();
                final rangeStart = now.subtract(const Duration(days: 2));
                final rangeEnd = now.add(const Duration(days: 30)); 
                
                final allRemedios = _db.getRemedios();
                for (var r in allRemedios) {
                   final posologias = _db.getPosologias(r.id);
                   for (var p in posologias) {
                       final doses = _medService.calculateNextDoses(p, rangeStart, limit: 100); 
                       for (var d in doses) {
                           if (d.isAfter(rangeEnd)) break;
                           virtualItems.add(_medService.createVirtualAgendaItem(r, p, d));
                       }
                   }
                }

                final allItems = [...manualItems, ...virtualItems]
                  ..sort((a, b) {
                    final da = a.dataInicio ?? a.criadoEm;
                    final db = b.dataInicio ?? b.criadoEm;
                    return da.compareTo(db);
                  });
                
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

                return TabBarView(
                  children: [
                    _buildList(compromissos, emptyMsg: 'Nenhum compromisso.'),
                    _buildList(aniversarios, emptyMsg: 'Nenhum aniversário.'),
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

   Widget _buildList(List<AgendaItem> itens, {required String emptyMsg}) {
       if (itens.isEmpty) {
            return Center(child: Text(emptyMsg));
       }
       return ListView.builder(
            itemCount: itens.length,
            padding: const EdgeInsets.only(bottom: 80),
            itemBuilder: (context, index) {
              final item = itens[index];
              final date = item.dataInicio ?? item.criadoEm;
              
              bool showHeader = true;
              if (index > 0) {
                final prev = itens[index - 1];
                final prevDate = prev.dataInicio ?? prev.criadoEm;
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
}
