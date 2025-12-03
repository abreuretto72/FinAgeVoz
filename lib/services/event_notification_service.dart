import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../services/database_service.dart';
import '../services/voice_service.dart';

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
        
        // Verificar se já foi notificado hoje (apenas para notificação automática)
        // Se a configuração 'always_announce_events' for false, respeitamos o lastNotifiedDate
        final alwaysAnnounce = _dbService.getAlwaysAnnounceEvents();
        
        if (!alwaysAnnounce && event.lastNotifiedDate != null) {
          final lastNotified = DateTime(
            event.lastNotifiedDate!.year,
            event.lastNotifiedDate!.month,
            event.lastNotifiedDate!.day,
          );
          
          // Se já foi notificado hoje, pular
          if (lastNotified.isAtSameMomentAs(today)) {
            print('EventNotificationService: Event "${event.title}" already notified today');
            return false;
          }
        }
        print('EventNotificationService: Found today event: "${event.title}"');
        return true;
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
        'Você tem um evento hoje: ${event.title} às $timeStr. Confirme dizendo OK.'
      );
      
      // Aguardar confirmação do usuário
      await _waitForConfirmation();
    } else {
      // Anunciar quantidade total primeiro
      await _voiceService.speak(
        'Você tem ${events.length} eventos hoje. Vou listar cada um.'
      );
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Listar cada evento individualmente
      for (int i = 0; i < events.length; i++) {
        final event = events[i];
        final timeStr = '${event.date.hour.toString().padLeft(2, '0')}:${event.date.minute.toString().padLeft(2, '0')}';
        
        await _voiceService.speak(
          'Evento ${i + 1}: ${event.title} às $timeStr. Confirme dizendo OK.'
        );
        
        // Aguardar confirmação antes de continuar para o próximo
        await _waitForConfirmation();
        
        // Pequena pausa entre eventos
        if (i < events.length - 1) {
          await Future.delayed(const Duration(milliseconds: 300));
        }
      }
      
      // Mensagem final
      await _voiceService.speak('Esses são todos os eventos de hoje.');
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
}
