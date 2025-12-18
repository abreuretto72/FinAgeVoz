import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'dart:io';
import '../models/medicine_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  
  // Cache calculated intervals to avoid redundant math if needed, but for now direct calc.

  Future<void> init() async {
    if (_initialized) return;

    // 1. Initialize Timezones (Device Local)
    tz.initializeTimeZones();
    try {
      final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
      final String timeZoneName = timeZoneInfo.identifier;
      print("DEBUG: Device Timezone found: $timeZoneName");
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      print("WARNING: Could not get device timezone, using default/UTC. Error: $e");
      try { tz.setLocalLocation(tz.getLocation('America/Sao_Paulo')); } catch(_) {}
    }

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
    
    // 2. Request Permissions (Strict)
    if (Platform.isAndroid) {
        final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        await androidPlugin?.requestNotificationsPermission();
        await androidPlugin?.requestExactAlarmsPermission(); // Required for exact scheduling
        
        if (await Permission.notification.isDenied) {
           await Permission.notification.request();
        }
        if (await Permission.scheduleExactAlarm.isDenied) {
            await Permission.scheduleExactAlarm.request();
        }
    }

    _initialized = true;
    print("DEBUG: NotificationService Initialized with Location: ${tz.local.name}");
    
    // TEST NOTIFICATION (Remove in production if annoying, but vital for debug now)
    // await _notificationsPlugin.show(
    //    99999, 
    //    'FinAgeVoz Ativo', 
    //    'O sistema de notificações está funcionando.', 
    //    const NotificationDetails(
    //      android: AndroidNotificationDetails('test_channel', 'Testes', importance: Importance.max)
    //    )
    // );
  }

  /// Schedule a one-time event (Compromissos)
  Future<void> scheduleEvent(int id, String title, String body, DateTime scheduledDate) async {
    print("DEBUG: Attempting to schedule EVENT $id for $scheduledDate");
    try {
        // Ensure future
        if (scheduledDate.isBefore(DateTime.now())) {
             print("DEBUG: Skipping past event $id");
             return;
        }

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
                    fullScreenIntent: true, // Force attention
                ),
                iOS: DarwinNotificationDetails(),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
            payload: 'EVENT_$id'
        );
        print("DEBUG: SUCCESS Scheduled Event $id");
    } catch (e, stack) {
        print("ERROR: Failed to schedule event: $e\n$stack");
    }
  }

  /// Schedule a daily repeated event (Medicines - Horarios Fixos)
  Future<void> scheduleDaily(int id, String title, String body, TimeOfDay time) async {
      print("DEBUG: Attempting to schedule DAILY $id at ${time.hour}:${time.minute}");
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
                     priority: Priority.high,
                     fullScreenIntent: true,
                 ),
                 iOS: DarwinNotificationDetails(),
             ),
             androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
             uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
             matchDateTimeComponents: DateTimeComponents.time, 
             payload: 'MED_$id'
         );
         print("DEBUG: SUCCESS Scheduled Daily Med $id"); 
      } catch (e, stack) {
         print("ERROR: Failed to schedule daily: $e\n$stack");
      }
  }

  /// Schedule explicit future doses
  Future<void> scheduleDose(int id, String title, String body, DateTime date) async {
       if (date.isBefore(DateTime.now())) return;
       print("DEBUG: Attempting to schedule DOSE $id at $date");
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
                    fullScreenIntent: true,
                ),
                iOS: DarwinNotificationDetails(),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
            payload: 'DOSE_$id'
        );
        print("DEBUG: SUCCESS Scheduled Dose $id");
    } catch (e, stack) {
        print("ERROR: Failed to schedule dose: $e\n$stack");
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
