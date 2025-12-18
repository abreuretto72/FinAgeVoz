import 'package:hive/hive.dart';
import '../models/agenda_models.dart';
import '../utils/hive_setup.dart';
import 'notification_service.dart';
import 'database_service.dart';

class AgendaRepository {
  Box<AgendaItem> get _box => agendaBox;

  List<AgendaItem> getAllItems() => getAll();


  Future<AgendaItem> addItem(AgendaItem item) async {
    final key = await _box.add(item);
    final saved = _box.get(key)!;
    await _scheduleNotification(saved);
    return saved;
  }

  Future<void> updateItem(AgendaItem item) async {
    item.atualizadoEm = DateTime.now();
    await item.save();
    await _scheduleNotification(item);
  }

  Future<void> deleteItem(AgendaItem item) async {
    await _cancelNotification(item);
    await item.delete();
  }
  
  // Notification Helpers
  Future<void> _scheduleNotification(AgendaItem item) async {
     print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
     print("📌 AGENDA REPOSITORY: Scheduling notification");
     print("   Item ID: ${item.key}");
     print("   Tipo: ${item.tipo}");
     print("   Título: ${item.titulo}");
     print("   Data Início: ${item.dataInicio}");
     print("   Horário Início: ${item.horarioInicio}");
     print("   Avisar antes: ${item.avisoMinutosAntes} min");
     print("   Quantidade avisos: ${item.quantidadeAvisos}");
     
     // Cancel old first to be safe
     await _cancelNotification(item);
     
     // 1. Determine DateTime
     final date = item.dataInicio;
     if (date == null) {
       print("⚠️  SKIPPED: No dataInicio");
       print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
       return;
     }
     
     DateTime scheduledTime;
     if (item.horarioInicio != null && item.horarioInicio!.contains(':')) {
         final parts = item.horarioInicio!.split(':');
         scheduledTime = DateTime(date.year, date.month, date.day, int.parse(parts[0]), int.parse(parts[1]));
         print("   ✅ Scheduled time calculated: $scheduledTime");
     } else if (item.tipo == AgendaItemType.ANIVERSARIO) {
         // Birthdays don't have time - use 9:00 AM as default
         scheduledTime = DateTime(date.year, date.month, date.day, 9, 0);
         print("   ✅ Birthday scheduled for 9:00 AM: $scheduledTime");
     } else {
         print("⚠️  SKIPPED: No valid horarioInicio");
         print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
         return; 
     }

     // Apply reminder offset
     DateTime notificationTime = scheduledTime;
     
     int minutesToSubtract = 0;
     if (item.avisoMinutosAntes != null) {
         minutesToSubtract = item.avisoMinutosAntes!;
     } else {
         // Fallback defaults
         if (item.tipo == AgendaItemType.COMPROMISSO ||
             item.tipo == AgendaItemType.TAREFA ||
             item.tipo == AgendaItemType.LEMBRETE ||
             item.tipo == AgendaItemType.PROJETO ||
             item.tipo == AgendaItemType.PRAZO) {
             minutesToSubtract = DatabaseService().getDefaultAgendaReminderMinutes();
         } else if (item.tipo == AgendaItemType.REMEDIO) {
             minutesToSubtract = DatabaseService().getDefaultMedicineReminderMinutes();
         } else if (item.tipo == AgendaItemType.PAGAMENTO) {
             minutesToSubtract = DatabaseService().getDefaultPaymentReminderMinutes();
         }
     }
     
     print("   Minutes to subtract: $minutesToSubtract");
     
     // 1. Calculate Base Notification Time (First Warning) or Range
     // Logic: "Calculo será minutos do campo avisar antes div quantidade de avisos"
     // Case A: Warning > 0 minutes before.
     // Case B: Warning == 0 (At time). 2 mins before, 1 min before, at time.
     
     int warningsCount = item.quantidadeAvisos ?? 3; // Default 3
     if (warningsCount < 1) warningsCount = 1;

     // USER REQUEST: For birthdays, only send message ONCE ("uma única vez").
     if (item.tipo == AgendaItemType.ANIVERSARIO) {
        warningsCount = 1;
     }
     
     print("   Warnings count: $warningsCount");
     
     int totalReminderMinutes = minutesToSubtract; // This is the "Avisar antes" value (e.g. 15)
     
     List<DateTime> notificationTimes = [];
     
     if (totalReminderMinutes == 0) {
        // Case B: "No horário" (0 min antes)
        // User requested: "um aviso 2 min antes, um 1 min antes, e o último no horário."
        // Check if user set warningsCount. If default 3, we do exactly this.
        // If count is different, we adjust logic? User specific request was strict.
        // Assuming strict logic for "No Horário" + "3 Avisos".
        // If count is 1: Just on time.
        // If count is 2: 1 min before + on time.
        
        notificationTimes.add(scheduledTime); // On Time
        if (warningsCount >= 2) notificationTimes.add(scheduledTime.subtract(const Duration(minutes: 1)));
        if (warningsCount >= 3) notificationTimes.add(scheduledTime.subtract(const Duration(minutes: 2)));
        
        // If even more warnings? e.g. 5? Maybe 3, 4 mins before?
        // Let's iterate.
        for (int i = 3; i < warningsCount; i++) {
            notificationTimes.add(scheduledTime.subtract(Duration(minutes: i)));
        }
     } else {
        // Case A: With Reminder Time (e.g. 15 mins) and Quantity (e.g. 3)
        // Interval = 15 / 3 = 5 mins.
        // Warnings at: T-15, T-10, T-5? Or T-15, T-10, T-5?
        // Usually, the "Avisar Antes" is the START of warnings or the singular warning.
        // User said: "Calculo será minutos ... dividido pela quantidade".
        // Implies intervals.
        // If 15 mins, 3 warnings. Interval = 5.
        // Warnings at: 15 min before, 10 min before, 5 min before? 
        // Or 10, 5, 0?
        // Usually "Avisar antes X" means X is the earliest or latest?
        // "Avisar 15 min antes". If I get 3 warnings, I expect one at 15m.
        // So: T-15, T-10, T-5. (And maybe T-0 is implicit event time? No, that's "No horário").
        
        int interval = (totalReminderMinutes / warningsCount).floor();
        if (interval < 1) interval = 1;

        for (int i = 0; i < warningsCount; i++) {
            // Logic: i=0 -> T - (interval * warningsCount)? No.
            // i=0 -> T - 15.
            // i=1 -> T - 10.
            // i=2 -> T - 5.
            // Math: minutesToSubtract - (interval * i)
            
            // Wait, if 15 mins, 3 warnings. Interval 5.
            // 1st: 15 min before.
            // 2nd: 10 min before.
            // 3rd: 5 min before.
            
            int minsBefore = totalReminderMinutes - (interval * i);
            if (minsBefore <= 0) minsBefore = 0; // Don't go past event time yet?
            
            notificationTimes.add(scheduledTime.subtract(Duration(minutes: minsBefore)));
        }
     }

     // 2. Schedule ALL calculated times
     // Use item.key (int) as base ID.
     // We need unique IDs for multiple notifications.
     // Formula: hash(itemId + index).
     
     // Cancel old notifications for this item (Base ID and variations)
     await _cancelNotification(item); 
     // We need a robust cancelAllForId? _cancelNotification uses item.key.
     // We need to loop cancel too to be safe?
     // NotificationService doesn't support regex cancel.
     // We will cancel range item.key * 1000 + i ?
     // Better strategy: Use a deterministic ID generation.
     // int baseId = item.key (usually < 100000).
     // Warning: item.key is auto-increment.
     // Let's assume max 100 warnings.
     
     int baseId = item.key as int;
     // Cancel loop
     for (int i = 0; i < 20; i++) {
        await NotificationService().cancel(baseId * 100 + i);
     }
     
     int index = 0;
     for (var notifyTime in notificationTimes) {
         // FIX: Past check
         if (notifyTime.isBefore(DateTime.now())) {
             if (scheduledTime.isAfter(DateTime.now())) {
                 // Too late for this specific warning, but if it's the LAST warning or close to event, maybe notify?
                 // To avoid spamming 3 missed warnings at once, let's only notify if close to now (< 1 min diff) or just SKIP past warnings.
                 // User wants warnings BEFORE. If passed, skip.
                 // Exception: If ALL passed, maybe notify once "Running late"?
                 // Let's stick to "Skip past".
                 // BUT apply the "Event is future" safety from previous step ONLY to the latest/closest one?
                 
                 // Logic: If notifyTime is past, ignore it.
                 continue;
             } else {
                 return;
             }
         }
         
         final notifId = baseId * 100 + index;
         
         String body = item.descricao ?? 'Agenda FinAgeVoz';
         
         if (item.tipo == AgendaItemType.PAGAMENTO && item.pagamento != null) {
               body = "Vencimento: R\$ ${item.pagamento!.valor.toStringAsFixed(2)}";
         } else if (item.tipo == AgendaItemType.REMEDIO && item.remedio != null) {
               body = "Horário de Remédio: ${item.remedio!.nome} (Dosagem: ${item.remedio!.dosagem})";
         } else if (item.tipo == AgendaItemType.ANIVERSARIO) {
               body = "Aniversário: ${item.titulo}. Não esqueça de parabenizar!";
         }
         
         // Format Body: "Aviso 1/3: Em 15 min..."
         int minsDiff = scheduledTime.difference(notifyTime).inMinutes;
         String prefix = "Lembrete: ";
         if (minsDiff > 0) prefix = "Em $minsDiff min: ";
         if (minsDiff == 0) prefix = "Agora: ";
         
         await NotificationService().scheduleEvent(notifId, item.titulo, prefix + body, notifyTime);
         index++;
     }
  }
  
  Future<void> _cancelNotification(AgendaItem item) async {
      final id = item.key as int;
      await NotificationService().cancel(id);
  }

  List<AgendaItem> getAll() {
    return _box.values.toList()
      ..sort((a, b) {
        final da = a.dataInicio ?? a.criadoEm;
        final db = b.dataInicio ?? b.criadoEm;
        return da.compareTo(db);
      });
  }

  List<AgendaItem> getByTipo(AgendaItemType tipo) {
    return _box.values.where((e) => e.tipo == tipo).toList();
  }

  List<AgendaItem> search({
    String? texto,
    AgendaItemType? tipo,
    DateTime? data,
  }) {
    return _box.values.where((item) {
      bool ok = true;

      if (texto != null && texto.trim().isNotEmpty) {
        final t = texto.toLowerCase();
        ok = ok &&
            ((item.titulo.toLowerCase().contains(t)) ||
                ((item.descricao ?? '').toLowerCase().contains(t)));
      }

      if (tipo != null) {
        ok = ok && item.tipo == tipo;
      }

      if (data != null) {
        final di = item.dataInicio;
        if (di == null) return false;
        ok = ok &&
            di.year == data.year &&
            di.month == data.month &&
            di.day == data.day;
      }

      return ok;
    }).toList();
  }
}
