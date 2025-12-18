import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'dart:io';
import '../models/medicine_model.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  
  // Cache calculated intervals to avoid redundant math if needed, but for now direct calc.

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true);

    final InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin);

    await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (details) {
            print("Notification clicked: ${details.payload}");
        }
    );
    
    if (Platform.isAndroid) {
        await _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    }

    _initialized = true;
    print("DEBUG: NotificationService Initialized");
  }

  /// Schedule a one-time event (Compromissos)
  Future<void> scheduleEvent(int id, String title, String body, DateTime scheduledDate) async {
    try {
        await _notificationsPlugin.zonedSchedule(
            id,
            title,
            body,
            tz.TZDateTime.from(scheduledDate, tz.local),
            const NotificationDetails(
                android: AndroidNotificationDetails(
                    'agenda_channel_id',
                    'Agenda',
                    channelDescription: 'Notificações de Compromissos',
                    importance: Importance.max,
                    priority: Priority.high,
                ),
                iOS: DarwinNotificationDetails(),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
            payload: 'EVENT_$id'
        );
        print("DEBUG: Scheduled Event $id for $scheduledDate");
    } catch (e) {
        print("ERROR: Failed to schedule event: $e");
    }
  }

  /// Schedule a daily repeated event (Medicines - Horarios Fixos)
  Future<void> scheduleDaily(int id, String title, String body, TimeOfDay time) async {
      try {
          await _notificationsPlugin.zonedSchedule(
             id,
             title,
             body,
             _nextInstanceOfTime(time),
             const NotificationDetails(
                 android: AndroidNotificationDetails(
                     'med_channel_id', 
                     'Medicamentos', 
                     channelDescription: 'Lembretes de Medicamentos', 
                     importance: Importance.max, 
                     priority: Priority.high
                 ),
                 iOS: DarwinNotificationDetails(),
             ),
             androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
             uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
             matchDateTimeComponents: DateTimeComponents.time, // Triggers every day at this time
             payload: 'MED_$id'
         );
         print("DEBUG: Scheduled Daily Med $id for ${time.hour}:${time.minute}"); 
      } catch (e) {
         print("ERROR: Failed to schedule daily: $e");
      }
  }

  /// Schedule explicit future doses (For Intervals)
  Future<void> scheduleDose(int id, String title, String body, DateTime date) async {
       try {
        await _notificationsPlugin.zonedSchedule(
            id,
            title,
            body,
            tz.TZDateTime.from(date, tz.local),
            const NotificationDetails(
                android: AndroidNotificationDetails(
                    'med_channel_id',
                    'Medicamentos',
                    channelDescription: 'Lembretes de Medicamentos',
                    importance: Importance.max,
                    priority: Priority.high,
                ),
                iOS: DarwinNotificationDetails(),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
            payload: 'DOSE_$id'
        );
        print("DEBUG: Scheduled Dose $id for $date");
    } catch (e) {
        print("ERROR: Failed to schedule dose: $e");
    }
  }
  
  Future<void> schedulePosology(Posologia p, Remedio? r) async {
      if (r == null) return;
      final title = "Hora do Remédio: ${r.nome}";
      final body = "${p.quantidadePorDose} ${p.unidadeDose}";
      
      // Cancel previous notifications for this posology
      // Strategy: We can't easily know ALL previous IDs without storage.
      // Ideally, we cancel based on a range or stored list.
      // Optimization: The 'id' for Posology is stable.
      // For HorariosFixos, we use hash(posologyId + index).
      // For Intervalo, we usage hash(posologyId + index_of_dose).
      
      // Let's implement a robust cancel for this posology ID.
      // Since we don't track notification IDs in DB, we'll brute-force cancel likely IDs 
      // or just assume we overwrite if ID matches (which it will if deterministic).
      
      if (p.frequenciaTipo == 'HORARIOS_FIXOS') {
          if (p.horariosDoDia == null) return;
          int index = 0;
          for (var tStr in p.horariosDoDia!) {
              final parts = tStr.split(':');
              final time = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
              
              // Unique ID per time slot
              final notifId = (p.id + "_$index").hashCode;
              await scheduleDaily(notifId, title, body, time);
              index++;
          }
      } else if (p.frequenciaTipo == 'INTERVALO') {
          // Schedule next 10 doses? 24h?
          // Let's schedule for the next 48 hours to be safe.
          // Logic: Next dose starting from now or 'next scheduled'?
          // We don't track 'next scheduled' here cleanly.
          // We'll trust the user wants to start/continue from NOW/TreatmentStart.
          
          DateTime base = p.inicioTratamento;
          final now = DateTime.now();
          if (base.isBefore(now)) {
             // Calculate effective start (catch up)
             int interval = p.intervaloHoras ?? 8;
             if (interval < 1) interval = 1;
             
             // Jump close to now
             int jumps = (now.difference(base).inHours / interval).ceil();
             base = base.add(Duration(hours: jumps * interval));
          }
          
          int interval = p.intervaloHoras ?? 8;
          for (int i = 0; i < 10; i++) { // Next 10 doses
              final doseDate = base.add(Duration(hours: interval * i));
              final notifId = (p.id + "_dose_$i").hashCode;
              await scheduleDose(notifId, title, body, doseDate);
          }
      }
  }
  
  // Cancel logic for a Posology
  Future<void> cancelPosologyNotifications(String posologyId) async {
     // We need to guess the IDs we created.
     // Heuristic: Check Horarios Fixos (up to 10 indices) and Doses (up to 20 indices).
     for (int i = 0; i < 20; i++) {
        await cancel((posologyId + "_$i").hashCode);
        await cancel((posologyId + "_dose_$i").hashCode);
     }
  }

  Future<void> cancel(int id) async {
    await _notificationsPlugin.cancel(id);
    print("DEBUG: Cancelled Notification $id");
  }

  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, time.hour, time.minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
