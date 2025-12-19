import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'voice_service.dart';
import 'database_service.dart'; // To save settings? Or just keep in memory/Check existing settings?
// Assuming we might need settings persistence, but for now implementing logic.

class TalkingClockService {
  static final TalkingClockService _instance = TalkingClockService._internal();
  factory TalkingClockService() => _instance;
  TalkingClockService._internal();

  Timer? _timer;
  final VoiceService _voiceService = VoiceService();
  final DatabaseService _dbService = DatabaseService();
  
  // Settings loaded from DB
  bool _isEnabled = false;
  bool _speakDateOnHourOnly = false; 
  
  // Quiet Hours (Hardcoded or Configurable)
  final int _quietStartHour = 22;
  final int _quietEndHour = 7;

  bool get isEnabled => _isEnabled;

  Future<void> init() async {
     await _dbService.init();
     reloadSettings();
     if (_isEnabled) {
         start();
     }
  }

  void reloadSettings() {
      _isEnabled = _dbService.getTalkingClockEnabled();
      _speakDateOnHourOnly = _dbService.getTalkingClockDateOnHourOnly();
      // Quiet hours are read directly in loop or we can cache them
      // Let's rely on DB for quiet hours to allow hot updates without variable sync issues if we want to be simple
      // or cache them here.
  }

  void start() {
    if (_timer != null) return;
    _isEnabled = true;
    _dbService.setTalkingClockEnabled(true);
    print("TalkingClock: Started");

    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkTime();
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _isEnabled = false;
    _dbService.setTalkingClockEnabled(false);
    print("TalkingClock: Stopped");
  }
  
  void setPreferences({required bool speakDateOnHourOnly}) {
      _speakDateOnHourOnly = speakDateOnHourOnly;
      _dbService.setTalkingClockDateOnHourOnly(speakDateOnHourOnly);
  }

  void _checkTime() async {
    final now = DateTime.now();
    
    // Reload quiet hours from DB to ensure fresh
    int startQ = _dbService.getTalkingClockQuietStart();
    int endQ = _dbService.getTalkingClockQuietEnd(); // e.g. 22 and 7
    
    // Check Quiet Hours Logic
    // If start < end (e.g. 01 to 05), simply check range.
    // If start > end (e.g. 22 to 07), check OR.
    
    bool isQuiet = false;
    if (startQ < endQ) {
        if (now.hour >= startQ && now.hour < endQ) isQuiet = true;
    } else {
        // Crosses midnight
        if (now.hour >= startQ || now.hour < endQ) isQuiet = true;
    }

    if (isQuiet) {
      return; // Shhh...
    }

    // Check 15 minute intervals
    if (now.minute % 15 != 0) {
        return; 
    }
    
    // It's time to speak!
    
    // Determine content
    bool speakDate = true;
    
    if (_speakDateOnHourOnly) {
        // Only speak date if minute is 0
        if (now.minute != 0) {
            speakDate = false;
        }
    }
    
    String message = "";
    
    // Getting locale from VoiceService
    String locale = _voiceService.currentTtsLocale; 
    // Format: pt-BR -> pt_BR for DateFormat usually requires underscore or standard locale
    // DateFormat handles 'pt_BR' better usually.
    String dateLocale = locale.replaceAll('-', '_');
    
    if (speakDate) {
        // Ex: "Quinta-feira, 18 de Dezembro"
        String datePart = DateFormat('EEEE, d \u0027de\u0027 MMMM', dateLocale).format(now);
        message += "$datePart. ";
    }
    
    // Time: "São 20 horas e 45 minutos"
    String timePart = DateFormat('HH:mm', dateLocale).format(now);
    // TTS usually reads "20:45" well, but to be strictly "São X horas...", we can format explicitly.
    // Let's rely on standard reading or format natural text.
    // "São 20 horas e 45 minutos" is better.
    
    int hour = now.hour;
    int minute = now.minute;
    
    String hourStr = (hour == 1) ? "uma hora" : "$hour horas";
    if (hour == 0) hourStr = "meia noite"; // Optional polish
    else if (hour == 12) hourStr = "meio dia";
    
    String minuteStr = (minute == 0) ? "em ponto" : "e $minute minutos";
    // if minute is 0, commonly just "hours".
    
    // Simple TTS friendly string:
    // "São 20 e 45" is usually enough, but prompt asked for "São [Horas] e [Minutos]"
    
    message += "São ${now.hour} horas e ${now.minute} minutos.";
    
    // Improve naturalness if minute is 0
    if (now.minute == 0) {
        message = message.replaceAll(" e 0 minutos.", " em ponto.");
    }

    print("TalkingClock: Speaking -> $message");
    await _voiceService.speak(message);
  }
}
