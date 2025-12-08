import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/medicine_model.dart';
import '../../services/database_service.dart';
import '../../services/medicine_service.dart';
import 'medicine_form_screen.dart';

class MedicineListScreen extends StatefulWidget {
  const MedicineListScreen({super.key});

  @override
  State<MedicineListScreen> createState() => _MedicineListScreenState();
}

class _MedicineListScreenState extends State<MedicineListScreen> {
  final DatabaseService _db = DatabaseService();
  final MedicineService _medicineService = MedicineService();
  List<Remedio> _remedios = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final list = _db.getRemedios();
    setState(() {
      _remedios = list;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Remédios'),
      ),
      body: _remedios.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Icon(Icons.medication_outlined, size: 64, color: Colors.grey),
                   const SizedBox(height: 16),
                   const Text("Nenhum remédio cadastrado."),
                   const SizedBox(height: 16),
                   ElevatedButton(
                     onPressed: _navigateToAdd,
                     child: const Text("Cadastrar Remédio"),
                   )
                ],
              ),
            )
          : ListView.builder(
              itemCount: _remedios.length,
              itemBuilder: (context, index) {
                final remedio = _remedios[index];
                return _buildRemedioCard(remedio);
              },
            ),
      floatingActionButton: _remedios.isEmpty ? null : FloatingActionButton(
        onPressed: _navigateToAdd,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildRemedioCard(Remedio remedio) {
    // Get next dose info
    // We need to iterate posologias
    // This might be async or expensive, ideally cache or calculate in loadData
    // For now simple UI
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: const Icon(Icons.medication, color: Colors.blue),
        ),
        title: Text(remedio.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("${remedio.concentracao} • ${remedio.formaFarmaceutica}"),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _navigateToDetail(remedio),
      ),
    );
  }

  void _navigateToAdd() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MedicineFormScreen()),
    );
    _loadData();
  }

  void _navigateToDetail(Remedio remedio) async {
    // Navigate to detail/edit
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MedicineFormScreen(remedio: remedio)),
    );
    _loadData();
  }
}
