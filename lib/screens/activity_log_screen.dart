import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../models/operation_history.dart';

class ActivityLogScreen extends StatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<OperationHistory> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  void _loadLogs() {
    // Carrega os últimos 50 logs (ou todos, já que o limite atual é 5 para undo, mas podemos aumentar para visualização se quisermos)
    // O método atual getLastOperations retorna 5 por padrão, mas aceita argumento.
    // Vamos assumir que queremos ver o que tem lá.
    // Nota: O DatabaseService atualmente limita o histórico a 5 itens no addOperationToHistory.
    // Se quisermos um log maior, precisaríamos aumentar esse limite no DatabaseService.
    // Por enquanto, mostramos o que tem.
    setState(() {
      _logs = _dbService.getLastOperations(20); 
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Histórico de Atividades', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _logs.isEmpty
          ? const Center(
              child: Text(
                'Nenhuma atividade recente.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                return Card(
                  color: const Color(0xFF1E1E1E),
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: _buildIconForType(log.type),
                    title: Text(
                      log.displayText,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(log.timestamp),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildIconForType(String type) {
    IconData icon;
    Color color;

    switch (type) {
      case 'transaction':
        icon = Icons.attach_money;
        color = Colors.green;
        break;
      case 'installment':
        icon = Icons.credit_card;
        color = Colors.orange;
        break;
      case 'event':
        icon = Icons.event;
        color = Colors.blue;
        break;
      case 'event_edit':
        icon = Icons.edit_calendar;
        color = Colors.amber;
        break;
      case 'call':
        icon = Icons.phone;
        color = Colors.purple;
        break;
      default:
        icon = Icons.history;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
