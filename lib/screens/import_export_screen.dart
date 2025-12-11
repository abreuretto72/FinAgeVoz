import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../services/transaction_csv_service.dart';
import '../services/agenda_csv_service.dart';
import '../services/google_calendar_service.dart';
import '../services/database_service.dart';
import '../services/agenda_repository.dart';
import '../models/transaction_model.dart';
import '../models/agenda_models.dart';


class ImportExportScreen extends StatefulWidget {
  const ImportExportScreen({super.key});

  @override
  State<ImportExportScreen> createState() => _ImportExportScreenState();
}

class _ImportExportScreenState extends State<ImportExportScreen> {
  final DatabaseService _db = DatabaseService();
  final AgendaRepository _repo = AgendaRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Importação & Exportação'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade700, Colors.blue.shade900],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              children: [
                Icon(Icons.import_export, size: 48, color: Colors.white),
                SizedBox(height: 12),
                Text(
                  'Gerenciamento de Dados',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Gerencie planilhas financeiras e sincronize com Google Calendar',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Planilhas Section
          _buildSectionHeader('Planilhas Financeiras (CSV)', Icons.table_chart),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  title: 'Exportar',
                  subtitle: 'Gerar planilha CSV',
                  icon: Icons.file_upload,
                  color: Colors.green,
                  onTap: () => _exportTransactions(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  title: 'Importar',
                  subtitle: 'Carregar planilha CSV',
                  icon: Icons.file_download,
                  color: Colors.blue,
                  onTap: () => _importTransactions(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Agenda Google Section
          _buildSectionHeader('Agenda Google', Icons.calendar_today),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  title: 'Exportar',
                  subtitle: 'Enviar para Google',
                  icon: Icons.file_upload,
                  color: Colors.orange,
                  onTap: () => _exportAgenda(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  title: 'Importar',
                  subtitle: 'Buscar do Google',
                  icon: Icons.file_download,
                  color: Colors.purple,
                  onTap: () => _importAgenda(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Planilhas: Arquivos CSV compatíveis com Excel/Sheets. Agenda: Sincronização com Google Calendar.',
                    style: TextStyle(color: Colors.blue.shade900, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue.shade700),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== TRANSAÇÕES =====
  Future<void> _exportTransactions() async {
    // Usar a mesma lógica do FinanceScreen
    final transactions = _db.getTransactions();
    
    if (transactions.isEmpty) {
      _showMessage('Nenhuma transação para exportar.');
      return;
    }

    final service = TransactionCsvService();
    final csv = service.generateCsv(transactions);
    final filename = "finance_export_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv";
    
    try {
      await service.shareCsv(csv, filename);
      _showMessage('Exportação concluída! ${transactions.length} transações exportadas.');
    } catch (e) {
      _showMessage('Erro ao exportar: $e');
    }
  }

  Future<void> _importTransactions() async {
    // Mostra instruções primeiro
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('Importar Transações'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Campos Obrigatórios:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              _buildRequiredField('1', 'Tipo', 'Receita ou Despesa'),
              _buildRequiredField('2', 'Data', 'AAAA-MM-DD ou DD/MM/AAAA'),
              _buildRequiredField('3', 'Valor', 'Aceita vírgula ou ponto'),
              _buildRequiredField('4', 'Descrição', 'Histórico da transação'),
              _buildRequiredField('5', 'Categoria', 'Nome da categoria'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.amber.shade700),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Linhas com campos inválidos serão ignoradas',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Selecionar Arquivo'),
          ),
        ],
      ),
    );

    if (proceed != true) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        
        _showMessage('Processando importação...');
        
        final service = TransactionCsvService();
        final report = await service.importCsv(content);
        
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text("Importação Concluída"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "✅ Transações importadas: ${report['imported']}\n"
                      "⚠️ Ignoradas: ${report['ignored']}",
                      style: const TextStyle(fontSize: 16),
                    ),
                    if (report['errors'] != null && (report['errors'] as List).isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      const Text(
                        'Detalhes dos Erros:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: (report['errors'] as List).length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                '• ${(report['errors'] as List)[index]}',
                                style: const TextStyle(fontSize: 12, color: Colors.red),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("OK"),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      _showMessage('Erro ao importar: $e');
    }
  }

  Widget _buildRequiredField(String number, String field, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  field,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  // ===== AGENDA =====
  Future<void> _exportAgenda() async {
    final items = _repo.getAll();
    
    if (items.isEmpty) {
      _showMessage('Nenhum item da agenda para exportar.');
      return;
    }

    final service = AgendaCsvService();
    final csv = service.generateCsv(items);
    final filename = "agenda_export_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv";
    
    try {
      await service.shareCsv(csv, filename);
      _showMessage('Exportação concluída! ${items.length} itens exportados.');
    } catch (e) {
      _showMessage('Erro ao exportar: $e');
    }
  }


  Future<void> _importAgenda() async {
    // Importar do Google Calendar
    final service = GoogleCalendarService();
    
    try {
      // 1. Autenticar com Google
      _showMessage('Conectando com Google...');
      
      final authResult = await service.authenticate();
      
      if (!authResult['success']) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Erro de Autenticação'),
                ],
              ),
              content: Text(authResult['error'] ?? 'Falha ao conectar com Google'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        return;
      }
      
      // 2. Selecionar período
      final period = await _showPeriodSelector();
      if (period == null) {
        await service.signOut();
        return; // Usuário cancelou
      }
      
      // 3. Importar eventos
      _showMessage('Importando eventos do Google Calendar...');
      
      final result = await service.importEvents(
        startDate: period['start'],
        endDate: period['end'],
      );
      
      // 4. Desconectar
      await service.signOut();
      
      // 5. Mostrar resultado
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  result['success'] ? Icons.check_circle : Icons.error_outline,
                  color: result['success'] ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                const Text('Importação do Google'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (result['success']) ...[
                    Text(
                      '✅ Eventos importados: ${result['imported']}\n'
                      '⚠️ Ignorados (duplicados): ${result['ignored']}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    if (result['errors'] != null && (result['errors'] as List).isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      const Text(
                        'Avisos:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 150),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: (result['errors'] as List).length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                '• ${(result['errors'] as List)[index]}',
                                style: const TextStyle(fontSize: 12, color: Colors.orange),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ] else ...[
                    Text(
                      result['error'] ?? 'Erro desconhecido',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      await service.signOut();
      _showMessage('Erro ao importar: $e');
    }
  }

  Future<Map<String, DateTime>?> _showPeriodSelector() async {
    DateTime? startDate;
    DateTime? endDate;
    int selectedOption = 1; // 0=7dias, 1=30dias, 2=90dias, 3=custom

    return showDialog<Map<String, DateTime>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          // Calcula datas baseado na opção selecionada
          switch (selectedOption) {
            case 0:
              startDate = DateTime.now();
              endDate = DateTime.now().add(const Duration(days: 7));
              break;
            case 1:
              startDate = DateTime.now();
              endDate = DateTime.now().add(const Duration(days: 30));
              break;
            case 2:
              startDate = DateTime.now();
              endDate = DateTime.now().add(const Duration(days: 90));
              break;
            case 3:
              // Personalizado - mantém as datas selecionadas
              startDate ??= DateTime.now();
              endDate ??= DateTime.now().add(const Duration(days: 30));
              break;
          }

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.blue),
                SizedBox(width: 8),
                Text('Selecionar Período'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Importar eventos de qual período?',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  RadioListTile<int>(
                    title: const Text('Próximos 7 dias'),
                    value: 0,
                    groupValue: selectedOption,
                    onChanged: (value) => setState(() => selectedOption = value!),
                  ),
                  RadioListTile<int>(
                    title: const Text('Próximos 30 dias'),
                    subtitle: const Text('Recomendado'),
                    value: 1,
                    groupValue: selectedOption,
                    onChanged: (value) => setState(() => selectedOption = value!),
                  ),
                  RadioListTile<int>(
                    title: const Text('Próximos 90 dias'),
                    value: 2,
                    groupValue: selectedOption,
                    onChanged: (value) => setState(() => selectedOption = value!),
                  ),
                  RadioListTile<int>(
                    title: const Text('Personalizado'),
                    value: 3,
                    groupValue: selectedOption,
                    onChanged: (value) => setState(() => selectedOption = value!),
                  ),
                  if (selectedOption == 3) ...[
                    const SizedBox(height: 8),
                    ListTile(
                      title: Text(
                        'Início: ${DateFormat('dd/MM/yyyy').format(startDate!)}',
                      ),
                      trailing: const Icon(Icons.calendar_month),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: startDate!,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (date != null) {
                          setState(() => startDate = date);
                        }
                      },
                    ),
                    ListTile(
                      title: Text(
                        'Fim: ${DateFormat('dd/MM/yyyy').format(endDate!)}',
                      ),
                      trailing: const Icon(Icons.calendar_month),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: endDate!,
                          firstDate: startDate!,
                          lastDate: DateTime(2030),
                        );
                        if (date != null) {
                          setState(() => endDate = date);
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, {
                  'start': startDate!,
                  'end': endDate!,
                }),
                child: const Text('Importar'),
              ),
            ],
          );
        },
      ),
    );
  }


  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
}
