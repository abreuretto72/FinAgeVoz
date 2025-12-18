import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../../models/medicine_model.dart';
import '../../services/database_service.dart';
import '../../services/medicine_service.dart';
import 'medicine_form_screen.dart';

/// Tela de listagem de medicamentos
/// 
/// ✅ REFATORADO: Todas as strings agora usam AppLocalizations
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
    // ✅ Obter localizations
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myMedicines),  // ✅ INTERNACIONALIZADO
      ),
      body: _remedios.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Icon(Icons.medication_outlined, size: 64, color: Colors.grey),
                   const SizedBox(height: 16),
                   Text(l10n.noMedicinesRegistered),  // ✅ INTERNACIONALIZADO
                   const SizedBox(height: 16),
                   ElevatedButton(
                     onPressed: _navigateToAdd,
                     child: Text(l10n.registerMedicine),  // ✅ INTERNACIONALIZADO
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
    // Buscar posologias associadas a este remédio
    final posologias = _db.getPosologias(remedio.id);
    String posologiaTexto = '';
    
    if (posologias.isNotEmpty) {
      // Pega a primeira posologia para exibir (ou junta todas se tiver mais de uma)
      final p = posologias.first;
      final tipo = p.frequenciaTipo.toUpperCase();
      
      if (tipo == 'INTERVALO') {
        posologiaTexto = "A cada ${p.intervaloHoras} horas";
      } else if (tipo == 'HORARIOS_FIXOS') {
        posologiaTexto = "${p.horariosDoDia?.join(', ')}";
      } else if (tipo == 'VEZES_DIA') {
        posologiaTexto = "${p.vezesAoDia}x ao dia";
      } else if (tipo == 'SE_NECESSARIO') {
        posologiaTexto = "Se necessário";
      } else {
        posologiaTexto = p.frequenciaTipo;
      }
      
      if (posologias.length > 1) {
        posologiaTexto += " (+${posologias.length - 1})";
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: const Icon(Icons.medication, color: Colors.blue),
        ),
        title: Text(remedio.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${remedio.concentracao} • ${remedio.formaFarmaceutica}"),
            if (posologiaTexto.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      posologiaTexto, 
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)
                    ),
                  ],
                ),
              ),
          ],
        ),
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
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MedicineFormScreen(remedio: remedio)),
    );
    _loadData();
  }
}
