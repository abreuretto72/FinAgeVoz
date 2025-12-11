import 'dart:io';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

/// Serviço de Voz Multilíngue (STT + TTS)
/// 
/// Gerencia reconhecimento de voz e síntese de fala com suporte
/// a troca dinâmica de idioma baseada nas preferências do usuário.
class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  
  bool _isAvailable = false;
  Function(String)? onResult;
  Function(bool)? onListeningStateChanged;

  /// Locale atual para STT (formato: pt_BR, en_US, etc.)
  String _currentSttLocale = 'pt_BR';
  
  /// Locale atual para TTS (formato: pt-BR, en-US, etc.)
  String _currentTtsLocale = 'pt-BR';

  /// Inicializa o serviço de voz
  /// 
  /// ⚠️ IMPORTANTE: Não força idioma específico na inicialização.
  /// O idioma será definido via setLanguage() baseado nas preferências do usuário.
  Future<void> init() async {
    print("VoiceService: Requesting microphone permission...");
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
    
    // Configuração iOS
    await _flutterTts.setIosAudioCategory(
      IosTextToSpeechAudioCategory.playAndRecord, 
      [
        IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
        IosTextToSpeechAudioCategoryOptions.allowBluetooth,
        IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
      ]
    );
    
    // ✅ CORREÇÃO: Inicializar com locale do dispositivo
    final deviceLocale = Platform.localeName;
    await setLanguage(_normalizeLocaleCode(deviceLocale));
  }

  /// Normaliza código de locale para formato interno (pt_BR, en_US, etc.)
  String _normalizeLocaleCode(String locale) {
    // Remove país se presente (pt_BR -> pt_BR, pt-BR -> pt_BR)
    locale = locale.replaceAll('-', '_');
    
    // Se já tem país, retorna
    if (locale.contains('_')) return locale;
    
    // Adiciona país padrão baseado no idioma
    switch (locale.toLowerCase()) {
      case 'pt': return 'pt_BR';
      case 'en': return 'en_US';
      case 'es': return 'es_ES';
      case 'de': return 'de_DE';
      case 'it': return 'it_IT';
      case 'fr': return 'fr_FR';
      case 'ja': return 'ja_JP';
      case 'zh': return 'zh_CN';
      case 'hi': return 'hi_IN';
      case 'ar': return 'ar_SA';
      case 'id': return 'id_ID';
      case 'ru': return 'ru_RU';
      case 'bn': return 'bn_IN';
      default: return 'pt_BR';
    }
  }

  /// Alterna o idioma do reconhecimento de voz (STT) e síntese (TTS)
  /// 
  /// Este método deve ser chamado sempre que o usuário trocar o idioma
  /// nas configurações do app.
  /// 
  /// [languageCode] Código do idioma (pt_BR, en, es, etc.)
  /// 
  /// ✅ CORREÇÃO CRÍTICA: Agora atualiza AMBOS STT e TTS dinamicamente
  Future<void> setLanguage(String languageCode) async {
    print("VoiceService: Setting language to $languageCode");
    
    // Normalizar código de entrada
    final normalizedCode = _normalizeLocaleCode(languageCode);
    
    // Mapear para formatos específicos de STT (underscore) e TTS (dash)
    switch (normalizedCode) {
      case 'pt_BR':
        _currentSttLocale = 'pt_BR';
        _currentTtsLocale = 'pt-BR';
        break;
      case 'pt_PT':
        _currentSttLocale = 'pt_PT';
        _currentTtsLocale = 'pt-PT';
        break;
      case 'es_ES':
      case 'es':
        _currentSttLocale = 'es_ES';
        _currentTtsLocale = 'es-ES';
        break;
      case 'en_US':
      case 'en':
        _currentSttLocale = 'en_US';
        _currentTtsLocale = 'en-US';
        break;
      case 'hi_IN':
      case 'hi':
        _currentSttLocale = 'hi_IN';
        _currentTtsLocale = 'hi-IN';
        break;
      case 'zh_CN':
      case 'zh':
        _currentSttLocale = 'zh_CN';
        _currentTtsLocale = 'zh-CN';
        break;
      case 'de_DE':
      case 'de':
        _currentSttLocale = 'de_DE';
        _currentTtsLocale = 'de-DE';
        break;
      case 'it_IT':
      case 'it':
        _currentSttLocale = 'it_IT';
        _currentTtsLocale = 'it-IT';
        break;
      case 'fr_FR':
      case 'fr':
        _currentSttLocale = 'fr_FR';
        _currentTtsLocale = 'fr-FR';
        break;
      case 'ja_JP':
      case 'ja':
        _currentSttLocale = 'ja_JP';
        _currentTtsLocale = 'ja-JP';
        break;
      case 'ar_SA':
      case 'ar':
        _currentSttLocale = 'ar_SA';
        _currentTtsLocale = 'ar-SA';
        break;
      case 'bn_IN':
      case 'bn':
        _currentSttLocale = 'bn_IN';
        _currentTtsLocale = 'bn-IN';
        break;
      case 'ru_RU':
      case 'ru':
        _currentSttLocale = 'ru_RU';
        _currentTtsLocale = 'ru-RU';
        break;
      case 'id_ID':
      case 'id':
        _currentSttLocale = 'id_ID';
        _currentTtsLocale = 'id-ID';
        break;
      default:
        _currentSttLocale = 'pt_BR';
        _currentTtsLocale = 'pt-BR';
    }
    
    // Configurar TTS
    await _flutterTts.setLanguage(_currentTtsLocale);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.awaitSpeakCompletion(true);
    
    print("VoiceService: Language configured - STT: $_currentSttLocale, TTS: $_currentTtsLocale");
  }

  /// Retorna comandos de parada baseados no idioma atual
  /// 
  /// ✅ CORREÇÃO: Comandos agora são multilíngues
  List<String> _getStopCommands() {
    final langCode = _currentSttLocale.split('_')[0];
    
    switch (langCode) {
      case 'pt':
        return ['ok', 'ok.', 'ok!', 'parar', 'pare', 'pronto'];
      case 'en':
        return ['ok', 'ok.', 'ok!', 'stop', 'done', 'finish'];
      case 'es':
        return ['ok', 'ok.', 'ok!', 'parar', 'detener', 'listo'];
      case 'fr':
        return ['ok', 'ok.', 'ok!', 'arrêter', 'stop', 'fini'];
      case 'de':
        return ['ok', 'ok.', 'ok!', 'stopp', 'halt', 'fertig'];
      case 'it':
        return ['ok', 'ok.', 'ok!', 'fermare', 'stop', 'fatto'];
      case 'ja':
        return ['ok', 'ok.', 'ok!', '停止', 'ストップ'];
      case 'zh':
        return ['ok', 'ok.', 'ok!', '停止', '好的'];
      case 'hi':
        return ['ok', 'ok.', 'ok!', 'रुको', 'बंद करो'];
      case 'ar':
        return ['ok', 'ok.', 'ok!', 'توقف', 'انتهى'];
      case 'ru':
        return ['ok', 'ok.', 'ok!', 'стоп', 'хватит'];
      case 'id':
        return ['ok', 'ok.', 'ok!', 'berhenti', 'selesai'];
      default:
        return ['ok', 'ok.', 'ok!'];
    }
  }

  /// Inicia escuta de voz com locale correto
  /// 
  /// ✅ CORREÇÃO: Usa _currentSttLocale em vez de Platform.localeName
  Future<void> startListening() async {
    if (!_isAvailable) {
      await init();
    }
    
    if (_isAvailable) {
      print("VoiceService: Starting to listen in $_currentSttLocale");
      
      _speech.listen(
        onResult: (result) {
          // Verificar comandos de parada multilíngues
          final stopCommands = _getStopCommands();
          final recognizedLower = result.recognizedWords.toLowerCase().trim();
          
          if (stopCommands.any((cmd) => recognizedLower.endsWith(cmd))) {
            print("VoiceService: Stop command detected: $recognizedLower");
            _speech.stop();
          }

          if (result.finalResult) {
            print("VoiceService: Final result: ${result.recognizedWords}");
            onResult?.call(result.recognizedWords);
          }
        },
        localeId: _currentSttLocale,  // ✅ Usa locale dinâmico
        pauseFor: const Duration(seconds: 5), // Adjusted to 5s to prevent premature cutoff
        listenFor: const Duration(seconds: 30), // Max 30s conversation window
        partialResults: true,
        cancelOnError: false,
      );
    }
  }

  /// Para a escuta de voz
  Future<void> stop() async {
    await _speech.stop();
  }

  /// Sintetiza fala no idioma configurado
  /// 
  /// [text] Texto a ser falado (já deve estar traduzido)
  Future<void> speak(String text) async {
    print("VoiceService: Speaking in $_currentTtsLocale: '$text'");
    // Garantir idioma antes de falar (defensivo)
    await _flutterTts.setLanguage(_currentTtsLocale); 
    await _flutterTts.awaitSpeakCompletion(true);
    await _flutterTts.speak(text);
    print("VoiceService: Finished speaking");
  }

  /// Retorna o locale atual de STT
  String get currentSttLocale => _currentSttLocale;
  
  /// Retorna o locale atual de TTS
  String get currentTtsLocale => _currentTtsLocale;
  
  /// Retorna se o serviço está disponível
  bool get isAvailable => _isAvailable;
}
