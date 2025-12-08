import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../services/database_service.dart';
import '../services/voice_service.dart';
import '../services/agenda_repository.dart';
import '../models/agenda_models.dart';
import '../services/contact_service.dart';
import '../services/ai_service.dart';
import '../services/medicine_service.dart';
import '../models/medicine_model.dart';
import 'package:uuid/uuid.dart';

class EventNotificationService {
  final DatabaseService _dbService = DatabaseService();
  final VoiceService _voiceService = VoiceService();

  /// Verifica eventos do dia e notifica o usuário se necessário
  /// Retorna true se houve notificação
  /// [markAsNotified] - Se true, marca os eventos como notificados (padrão: true)
  Future<bool> checkAndNotifyTodayEvents({bool markAsNotified = true}) async {
    await _dbService.init();
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    
    // Buscar todos os eventos
    final allEvents = _dbService.getEvents();
    print('EventNotificationService: Total events: ${allEvents.length}');
    
    // Filtrar eventos de hoje que não foram cancelados
    final todayEvents = allEvents.where((event) {
      if (event.isCancelled) return false;
      
      // Verificar se ocorre hoje (considerando recorrência)
      if (_occursToday(event, today)) {
        // Verificar se o horário do evento já passou
        final eventTimeToday = DateTime(
          today.year,
          today.month,
          today.day,
          event.date.hour,
          event.date.minute,
        );
        
        if (eventTimeToday.isBefore(now)) {
          print('EventNotificationService: Event "${event.title}" passed at $eventTimeToday');
          return false;
        }

        // Se não estamos marcando como notificado (repetição manual),
        // incluir todos os eventos de hoje
        if (!markAsNotified) {
          print('EventNotificationService: Found today event (repeat): "${event.title}"');
          return true;
        }
        // Check for notification logic
        // 1. Daily Summary (First time app opens today)
        // 2. Urgent Reminder (At reminder time)
        
        final reminderMinutes = event.reminderMinutes > 0 ? event.reminderMinutes : 30;
        final alwaysAnnounce = _dbService.getAlwaysAnnounceEvents();
        bool shouldNotify = false;

        if (alwaysAnnounce || event.lastNotifiedDate == null) {
           shouldNotify = true;
        } else {
           final last = event.lastNotifiedDate!;
           final isToday = last.year == today.year && last.month == today.month && last.day == today.day;
           
           if (!isToday) {
              // Not yet notified today -> Daily Summary
              shouldNotify = true;
           } else {
              // Already notified today. Check for Urgent Reminder.
              final timeUntilEvent = eventTimeToday.difference(now);
              final timeSinceLastNotify = now.difference(last);
              
              // Trigger if within reminder window AND enough time passed since last notification
              // We use a 20 minute buffer to prevent immediate loops if the user acknowledges.
              if (timeUntilEvent.inMinutes <= reminderMinutes && 
                  timeUntilEvent.inMinutes >= 0 && 
                  timeSinceLastNotify.inMinutes > 15) {
                  
                  shouldNotify = true;
                  print('EventNotificationService: Triggering URGENT reminder ($reminderMinutes min) for "${event.title}"');
              }
           }
        }
        
        if (shouldNotify) {
           print('EventNotificationService: Found event to notify: "${event.title}"');
           return true; 
        }
        
        return false;
      }
      return false;
    }).toList();
    
    print('EventNotificationService: Today events to notify: ${todayEvents.length}');
    
    // Se não há eventos para notificar, retornar
    if (todayEvents.isEmpty) {
      return false;
    }
    
    // Notificar o usuário
    await _notifyUser(todayEvents);
    
    // Marcar eventos como notificados apenas se solicitado
    if (markAsNotified) {
      await _markEventsAsNotified(todayEvents, now);
    }
    
    return true;
  }

  /// Notifica o usuário sobre os eventos do dia
  Future<void> _notifyUser(List<Event> events) async {
    // Ordenar eventos do mais cedo ao mais tarde
    events.sort((a, b) => a.date.compareTo(b.date));
    
    if (events.length == 1) {
      final event = events.first;
      final timeStr = '${event.date.hour.toString().padLeft(2, '0')}:${event.date.minute.toString().padLeft(2, '0')}';
      await _voiceService.speak(
        'Você tem um evento hoje: ${event.title} às $timeStr. Confirme dizendo OK. Eu te avisarei novamente 10 minutos antes.'
      );
      
      // Aguardar confirmação do usuário
      await _waitForConfirmation();
    } else {
      // Anunciar quantidade total primeiro
      await _voiceService.speak(
        'Você tem ${events.length} eventos hoje. Vou listar cada um. Confirme com OK e te lembrarei 10 minutos antes de cada um.'
      );
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Listar cada evento individualmente
      for (int i = 0; i < events.length; i++) {
        final event = events[i];
        final timeStr = '${event.date.hour.toString().padLeft(2, '0')}:${event.date.minute.toString().padLeft(2, '0')}';
        
        await _voiceService.speak(
          'Evento ${i + 1}: ${event.title} às $timeStr.'
        );
        
        // Aguardar confirmação antes de continuar para o próximo
        await _waitForConfirmation();
        
        // Pequena pausa entre eventos
        if (i < events.length - 1) {
          await Future.delayed(const Duration(milliseconds: 300));
        }
      }
      
      // Mensagem final
      await _voiceService.speak('Tudo certo. Te avisarei 10 minutos antes dos horários.');
    }
  }

  /// Aguarda confirmação do usuário
  /// Usa um delay para dar tempo ao usuário processar a informação
  Future<void> _waitForConfirmation() async {
    // Aguardar 4 segundos para o usuário processar e confirmar mentalmente
    // Isso dá tempo suficiente para o usuário ouvir e assimilar a informação
    await Future.delayed(const Duration(seconds: 4));
  }

  /// Marca os eventos como notificados
  Future<void> _markEventsAsNotified(List<Event> events, DateTime notificationTime) async {
    final allEvents = _dbService.getEvents();
    
    for (var event in events) {
      // Encontrar o índice do evento
      final index = allEvents.indexWhere((e) => e.id == event.id);
      
      if (index >= 0) {
        // Criar evento atualizado com a data de notificação
        final updatedEvent = Event(
          id: event.id,
          title: event.title,
          date: event.date,
          description: event.description,
          isCancelled: event.isCancelled,
          recurrence: event.recurrence,
          lastNotifiedDate: notificationTime,
        );
        
        // Atualizar no banco
        await _dbService.updateEvent(index, updatedEvent);
      }
    }
  }

  /// Limpa notificações antigas (opcional - para manutenção)
  Future<void> cleanOldNotifications() async {
    await _dbService.init();
    
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    
    final allEvents = _dbService.getEvents();
    
    for (int i = 0; i < allEvents.length; i++) {
      final event = allEvents[i];
      
      // Se tem data de notificação e é muito antiga, limpar
      if (event.lastNotifiedDate != null && 
          event.lastNotifiedDate!.isBefore(thirtyDaysAgo)) {
        
        final updatedEvent = Event(
          id: event.id,
          title: event.title,
          date: event.date,
          description: event.description,
          isCancelled: event.isCancelled,
          recurrence: event.recurrence,
          lastNotifiedDate: null, // Limpar
        );
        
        await _dbService.updateEvent(i, updatedEvent);
      }
    }
  }

  /// Verifica se o evento ocorre na data especificada (considerando recorrência)
  bool _occursToday(Event event, DateTime today) {
    final eventDate = DateTime(
      event.date.year,
      event.date.month,
      event.date.day,
    );

    // Se a data original é hoje, retorna true
    if (eventDate.isAtSameMomentAs(today)) {
      return true;
    }

    // Se não tem recorrência e não é hoje, retorna false
    if (event.recurrence == null || event.recurrence == 'NONE') {
      return false;
    }

    // Se a data original é depois de hoje, não ocorre hoje
    if (eventDate.isAfter(today)) {
      return false;
    }

    // Verificar recorrência
    DateTime current = event.date;
    // Definir um limite razoável para evitar loops infinitos (ex: 5 anos)
    final limit = today.add(const Duration(days: 1));

    while (current.isBefore(limit)) {
      final currentDate = DateTime(current.year, current.month, current.day);
      
      if (currentDate.isAtSameMomentAs(today)) {
        return true;
      }

      // Avançar para a próxima ocorrência
      switch (event.recurrence) {
        case 'DAILY':
          current = current.add(const Duration(days: 1));
          break;
        case 'WEEKLY':
          current = current.add(const Duration(days: 7));
          break;
        case 'MONTHLY':
          var nextMonth = current.month + 1;
          var nextYear = current.year;
          if (nextMonth > 12) {
            nextMonth = 1;
            nextYear++;
          }
          var maxDays = DateTime(nextYear, nextMonth + 1, 0).day;
          var nextDay = current.day > maxDays ? maxDays : current.day;
          current = DateTime(nextYear, nextMonth, nextDay, current.hour, current.minute);
          break;
        case 'YEARLY':
          current = DateTime(current.year + 1, current.month, current.day, current.hour, current.minute);
          break;
        default:
          return false;
      }
    }

    return false;
  }

  /// Verifica aniversários do dia que ainda não foram enviados
  Future<List<AgendaItem>> getDueBirthdays() async {
    final repo = AgendaRepository();
    final allItems = repo.getAllItems();
    final now = DateTime.now();
    final due = <AgendaItem>[];
    
    for (var item in allItems) {
      if (item.tipo == AgendaItemType.ANIVERSARIO && item.aniversario != null) {
        final bday = item.aniversario!;
        DateTime? targetDate = bday.dataNascimento ?? item.dataInicio;
        
        if (targetDate != null && targetDate.month == now.month && targetDate.day == now.day) {
           if (bday.ultimoAnoEnviado != now.year) {
             due.add(item);
           }
        }
      }
    }
    return due;
  }

  Future<void> markBirthdayAsSent(AgendaItem item) async {
    if (item.aniversario != null) {
       item.aniversario!.ultimoAnoEnviado = DateTime.now().year;
       await AgendaRepository().updateItem(item);
    }
  }

  /// Verifica remédios que precisam ser tomados (Sistema Novo + Legado)
  Future<List<AgendaItem>> getDueMedicines() async {
    final medService = MedicineService();
    final db = DatabaseService();
    final now = DateTime.now();
    final due = <AgendaItem>[];
    
    // 1. Check Legacy Items
    final repo = AgendaRepository();
    final allItems = repo.getAllItems();
    for (var item in allItems) {
      if (item.tipo == AgendaItemType.REMEDIO && item.remedio != null) {
         // Legacy logic: check target time vs now
         // Only if it doesn't look like a "virtual" item (db persisted)
         // Assuming legacy items are persisted.
         DateTime target = item.remedio!.proximaDose ?? item.remedio!.inicioTratamento;
         if (target.isBefore(now.add(const Duration(minutes: 1))) && item.status == 'PENDENTE') {
             due.add(item);
         }
      }
    }
    
    // 2. Check New System (Remedio/Posologia)
    final remedios = db.getRemedios();
    for (var r in remedios) {
       for (var pid in r.posologiaIds) {
          final p = db.getPosologia(pid);
          if (p == null) continue;
          
          if (!p.exigirConfirmacao) continue; // Skip if no confirmation needed (auto-taken?)

          // Check last 24 hours to catch missed doses
          final checkStart = now.subtract(const Duration(hours: 24));
          final doses = medService.calculateNextDoses(p, checkStart, limit: 10);
          
          for (var d in doses) {
             // If dose is too far in future, stop
             if (d.isAfter(now.add(const Duration(minutes: 1)))) break;
             
             // Check history
             final history = db.getHistorico(p.id);
             final taken = history.any((h) => 
               h.dataHoraProgramada.isAtSameMomentAs(d) || 
               (h.dataHoraProgramada.difference(d).inMinutes.abs() < 10 && h.taken)
             );
             
             if (!taken) {
               // Found a due/missed dose
               final virtualItem = await medService.createVirtualAgendaItem(r, p, d);
               due.add(virtualItem);
             }
          }
       }
    }
    return due;
  }

  /// Marca remédio como tomado
  Future<void> markMedicineAsTaken(AgendaItem item) async {
    final db = DatabaseService();
    // Case 1: Legacy Item
    if (item.isInBox) {
        if (item.remedio == null) return;
        final med = item.remedio!;
        final now = DateTime.now();
        med.ultimaDoseTomada = now;
        
        // Calculate next dose (Legacy logic)
        if (med.frequenciaTipo == 'HORAS') {
           med.proximaDose = now.add(Duration(hours: med.intervalo));
        } else {
           med.proximaDose = now.add(const Duration(hours: 24));
        }
        med.status = 'PENDENTE'; // Keep passing it forward
        await AgendaRepository().updateItem(item);
        return;
    }

    // Case 2: New System (Virtual Item)
    if (item.remedio != null) {
       final remedios = db.getRemedios();
       final r = remedios.where((e) => e.nome == item.remedio!.nome).firstOrNull;
       if (r != null) {
          final scheduledTime = item.dataInicio!;
          // Find matching posology
          // We don't have exact ID, try to find one that aligns or just the first valid one
          for (var pid in r.posologiaIds) {
             final p = db.getPosologia(pid);
             if (p != null) {
                // Register history
                final h = HistoricoTomada(
                  id: const Uuid().v4(),
                  posologiaId: p.id,
                  dataHoraProgramada: scheduledTime,
                  dataHoraReal: DateTime.now(),
                  taken: true,
                  observacao: "Marcado via voz/notificação",
                );
                await db.addHistoricoTomada(h);
                // We don't "update next dose" because calculateNextDoses checks history.
                return;
             }
          }
       }
    }
  }
}
