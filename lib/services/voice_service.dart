import 'dart:io';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

import 'package:permission_handler/permission_handler.dart';

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  
  bool _isAvailable = false;
  Function(String)? onResult;
  Function(bool)? onListeningStateChanged;

  String _currentLocaleId = Platform.localeName;

  Future<void> init() async {
    print("VoiceService: Requesting permission...");
    var status = await Permission.microphone.request();
    print("VoiceService: Permission status: $status");
    
    if (status != PermissionStatus.granted) {
      print('VoiceService: Microphone permission denied');
      return;
    }
    
    print("VoiceService: Initializing speech_to_text...");
    try {
      _isAvailable = await _speech.initialize(
        onStatus: (status) {
          print("VoiceService: Status changed: $status");
          if (status == 'listening') {
            onListeningStateChanged?.call(true);
          } else if (status == 'notListening' || status == 'done') {
            onListeningStateChanged?.call(false);
          }
        },
        onError: (errorNotification) {
          print('VoiceService: Error: $errorNotification');
          onListeningStateChanged?.call(false);
        },
        debugLogging: true,
      );
      print("VoiceService: Initialization result: $_isAvailable");
    } catch (e) {
      print("VoiceService: Exception during init: $e");
    }
    
    // Default config
    await _flutterTts.setIosAudioCategory(IosTextToSpeechAudioCategory.playAndRecord, [
       IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
       IosTextToSpeechAudioCategoryOptions.allowBluetooth,
       IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
    ]);
    await _flutterTts.setLanguage("pt-BR");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.awaitSpeakCompletion(true);
  }

  Future<void> setLanguage(String languageCode) async {
    // Map internal codes to TTS/STT locales
    // STT usually expects underscores (en_US), TTS often accepts both but dashes are standard (en-US)
    switch (languageCode) {
      case 'pt_BR': _currentLocaleId = 'pt_BR'; await _flutterTts.setLanguage("pt-BR"); break;
      case 'pt_PT': _currentLocaleId = 'pt_PT'; await _flutterTts.setLanguage("pt-PT"); break;
      case 'es': _currentLocaleId = 'es_ES'; await _flutterTts.setLanguage("es-ES"); break;
      case 'en': _currentLocaleId = 'en_US'; await _flutterTts.setLanguage("en-US"); break;
      case 'hi': _currentLocaleId = 'hi_IN'; await _flutterTts.setLanguage("hi-IN"); break;
      case 'zh': _currentLocaleId = 'zh_CN'; await _flutterTts.setLanguage("zh-CN"); break;
      case 'de': _currentLocaleId = 'de_DE'; await _flutterTts.setLanguage("de-DE"); break;
      case 'it': _currentLocaleId = 'it_IT'; await _flutterTts.setLanguage("it-IT"); break;
      case 'fr': _currentLocaleId = 'fr_FR'; await _flutterTts.setLanguage("fr-FR"); break;
      case 'ja': _currentLocaleId = 'ja_JP'; await _flutterTts.setLanguage("ja-JP"); break;
      case 'ar': _currentLocaleId = 'ar_SA'; await _flutterTts.setLanguage("ar-SA"); break;
      case 'bn': _currentLocaleId = 'bn_IN'; await _flutterTts.setLanguage("bn-IN"); break;
      case 'ru': _currentLocaleId = 'ru_RU'; await _flutterTts.setLanguage("ru-RU"); break;
      case 'id': _currentLocaleId = 'id_ID'; await _flutterTts.setLanguage("id-ID"); break;
      default: _currentLocaleId = 'pt_BR'; await _flutterTts.setLanguage("pt-BR");
    }
    print("VoiceService: Language set to $_currentLocaleId");
    
    // Configure TTS settings
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setVolume(1.0); // Volume máximo
    await _flutterTts.setSpeechRate(0.5); // Velocidade normal (0.5 é padrão)
  }

  Future<void> startListening() async {
    if (!_isAvailable) {
      await init();
    }
    
    if (_isAvailable) {
      _speech.listen(
        onResult: (result) {
          // Check for "OK" command to stop listening immediately
          if (result.recognizedWords.toLowerCase().endsWith('ok') || 
              result.recognizedWords.toLowerCase().endsWith('ok.') ||
              result.recognizedWords.toLowerCase().endsWith('ok!') ||
              result.recognizedWords.toLowerCase().trim() == 'ok') {
            _speech.stop();
          }

          if (result.finalResult) {
            onResult?.call(result.recognizedWords);
          }
        },
        localeId: _currentLocaleId,
        pauseFor: const Duration(seconds: 10), // Generous pause handling
        listenFor: const Duration(seconds: 60), 
        partialResults: true, // Enable partials to keep connection alive
        cancelOnError: false,
      );
    }
  }

  Future<void> stop() async {
    await _speech.stop();
  }

  Future<void> speak(String text) async {
    print("VoiceService: Speaking: '$text'");
    // Configure TTS to wait for completion
    await _flutterTts.awaitSpeakCompletion(true);
    await _flutterTts.speak(text);
    print("VoiceService: Finished speaking");
  }
}
