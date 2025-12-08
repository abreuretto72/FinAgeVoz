import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../models/medicine_model.dart';
import '../models/agenda_models.dart';
import '../services/database_service.dart';

class MedicineService {
  final DatabaseService _db = DatabaseService();

  // Helper to generate next doses
  List<DateTime> calculateNextDoses(Posologia posologia, DateTime fromDate, {int limit = 10}) {
    List<DateTime> doses = [];
    DateTime base = posologia.inicioTratamento;
    
    // Safety check
    if (posologia.fimTratamento != null && fromDate.isAfter(posologia.fimTratamento!)) {
      return [];
    }

    // Logic based on types
    if (posologia.frequenciaTipo == 'INTERVALO') {
      int interval = posologia.intervaloHoras ?? 8;
      if (interval < 1) interval = 1;

      // Start from 'base' and add interval until > fromDate
      // Optimization: jump to near fromDate
      // (fromDate - base) / interval
      
      // We want to find the first dose > fromDate (or >= fromDate if we want upcoming inclusive)
      
      // Simple loop for now (assuming treatments aren't 100 years old)
      DateTime current = base;
      while (current.isBefore(fromDate)) {
        current = current.add(Duration(hours: interval));
      }
      
      for (int i = 0; i < limit; i++) {
        if (posologia.fimTratamento != null && current.isAfter(posologia.fimTratamento!)) break;
        doses.add(current);
        current = current.add(Duration(hours: interval));
      }

    } else if (posologia.frequenciaTipo == 'HORARIOS_FIXOS') {
      // ["08:00", "20:00"]
      if (posologia.horariosDoDia == null || posologia.horariosDoDia!.isEmpty) return [];
      
      List<TimeOfDay> times = posologia.horariosDoDia!.map((s) {
        final parts = s.split(':');
        return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }).toList();
      times.sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));

      DateTime currentDay = DateTime(fromDate.year, fromDate.month, fromDate.day);
      int found = 0;
      
      // Check today's remaining times
      for (var t in times) {
        final dt = DateTime(currentDay.year, currentDay.month, currentDay.day, t.hour, t.minute);
        if (dt.isAfter(fromDate) || dt.isAtSameMomentAs(fromDate)) {
          if (posologia.inicioTratamento.isAfter(dt)) continue;
          if (posologia.fimTratamento != null && dt.isAfter(posologia.fimTratamento!)) continue;
           
           // Check day of week if specified
           if (posologia.diasDaSemana != null && posologia.diasDaSemana!.isNotEmpty) {
             if (!posologia.diasDaSemana!.contains(dt.weekday)) continue; // 1..7 standard
           }

          doses.add(dt);
          found++;
          if (found >= limit) return doses;
        }
      }

      // Next days
      int safe = 0;
      while (found < limit && safe < 365) {
        currentDay = currentDay.add(const Duration(days: 1));
        safe++;
         
        // Check days of week
        if (posologia.diasDaSemana != null && posologia.diasDaSemana!.isNotEmpty) {
           if (!posologia.diasDaSemana!.contains(currentDay.weekday)) continue;
        }

        for (var t in times) {
          final dt = DateTime(currentDay.year, currentDay.month, currentDay.day, t.hour, t.minute);
          if (posologia.fimTratamento != null && dt.isAfter(posologia.fimTratamento!)) return doses;
          if (posologia.inicioTratamento.isAfter(dt)) continue;

          doses.add(dt);
          found++;
          if (found >= limit) return doses;
        }
      }

    } else if (posologia.frequenciaTipo == 'VEZES_DIA') {
      // "3x ao dia" -> 24/3 = 8h interval starting from start time?
      // Usually "Vezes ao dia" implies even distribution during waking hours, but simpler to treat as 24/N interval.
      int n = posologia.vezesAoDia ?? 1;
      if (n < 1) n = 1;
      int interval = (24 / n).floor(); // e.g., 3x -> 8h.
      
      // Same logic as INTERVALO
      DateTime current = base;
      while (current.isBefore(fromDate)) {
        current = current.add(Duration(hours: interval));
      }
      
      for (int i = 0; i < limit; i++) {
         if (posologia.fimTratamento != null && current.isAfter(posologia.fimTratamento!)) break;
         doses.add(current);
         current = current.add(Duration(hours: interval));
      }
    } 
    // SE_NECESSARIO has no scheduled doses
    
    return doses;
  }

  /// Converts a projected dose into an ephemeral AgendaItem for display
  AgendaItem createVirtualAgendaItem(Remedio remedio, Posologia posologia, DateTime date) {
    // Check if already taken?
    // We need to query history. inefficient for list views?
    // Let's assume this is for "Upcoming" view.
    
    final history = _db.getHistorico(posologia.id);
    final takenEntry = history.firstWhere(
      (h) => h.dataHoraProgramada.isAtSameMomentAs(date) || 
             (h.dataHoraProgramada.difference(date).inMinutes.abs() < 5), // Fuzzy match
      orElse: () => HistoricoTomada(id: '', posologiaId: '', dataHoraProgramada: DateTime(0), taken: false),
    );
    
    bool isTaken = takenEntry.id.isNotEmpty && takenEntry.taken;

    return AgendaItem(
      tipo: AgendaItemType.REMEDIO,
      titulo: "Tomar ${remedio.nome}",
      descricao: "${remedio.doseText(posologia)} - ${remedio.indicacao ?? ''}",
      dataInicio: date,
      horarioInicio: DateFormat('HH:mm').format(date),
      status: isTaken ? ItemStatus.CONCLUIDO : ItemStatus.PENDENTE,
      remedio: RemedioInfo(
        nome: remedio.nome,
        dosagem: "${posologia.quantidadePorDose} ${posologia.unidadeDose}",
        horario: DateFormat('HH:mm').format(date),
        frequenciaTipo: posologia.frequenciaTipo,
        intervalo: posologia.intervaloHoras ?? 0,
        inicioTratamento: posologia.inicioTratamento,
        quantidade: posologia.quantidadePorDose.toInt(),
        id: remedio.id,
        posologiaId: posologia.id,
      ),
      // Custom field to link back if needed (HiveObject doesn't support transient fields easily without Ignoring)
      // We can use the ID in description or title if strict? 
      // AgendaItem is TypeId 107. RemedioInfo 104.
      // We might abuse 'descricao' to store JSON or just ID?
      // Or rely on matching name/time.
      // Ideally update RemedioInfo to hold ID.
    );
  }
}

extension RemedioExtensions on Remedio {
  String doseText(Posologia p) {
    return "${p.quantidadePorDose} ${p.unidadeDose}";
  }
}
