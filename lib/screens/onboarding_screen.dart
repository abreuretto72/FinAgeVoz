import 'dart:io';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/database_service.dart';
import '../services/voice_service.dart';
import 'home_screen.dart';
import '../utils/localization.dart';
import '../widgets/permission_rationale_dialog.dart';

class OnboardingScreen extends StatefulWidget {
  final bool isSettings;
  const OnboardingScreen({super.key, this.isSettings = false});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final DatabaseService _dbService = DatabaseService();
  final VoiceService _voiceService = VoiceService();
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _groqKeyController = TextEditingController();
  
  bool _isListening = false;
  String _statusText = "Toque no microfone e diga sua senha de voz (ex: 'Jarvis')";
  String _selectedLanguage = 'en';

  String _getSystemLanguage() {
    try {
      final systemLocale = Platform.localeName;
      if (systemLocale.startsWith('pt_PT')) return 'pt_PT';
      if (systemLocale.startsWith('pt')) return 'pt_BR';
      if (systemLocale.startsWith('es')) return 'es';
      if (systemLocale.startsWith('de')) return 'de';
      if (systemLocale.startsWith('it')) return 'it';
      if (systemLocale.startsWith('fr')) return 'fr';
      if (systemLocale.startsWith('ja')) return 'ja';
      if (systemLocale.startsWith('hi')) return 'hi';
      if (systemLocale.startsWith('zh')) return 'zh';
      if (systemLocale.startsWith('ar')) return 'ar';
      if (systemLocale.startsWith('bn')) return 'bn';
      if (systemLocale.startsWith('ru')) return 'ru';
      if (systemLocale.startsWith('id')) return 'id';
    } catch (e) {
      print("Error getting system locale: $e");
    }
    return 'en';
  }

  @override
  void initState() {
    super.initState();
    _selectedLanguage = _getSystemLanguage();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _dbService.init();
    final wakeWord = _dbService.getWakeWord();
    final groqKey = _dbService.getGroqApiKey();
    final language = _dbService.getLanguage();
    
    setState(() {
      _selectedLanguage = language;
    });

    if (wakeWord != null) _controller.text = wakeWord;
    if (groqKey != null) {
      _groqKeyController.text = groqKey;
    } else {
      // _groqKeyController.text = ""; // Key removed for security
    }
    
    // Initialize voice with loaded language
    await _voiceService.init();
    await _voiceService.setLanguage(_selectedLanguage);
    
    _voiceService.onResult = (text) {
      setState(() {
        _controller.text = text;
        _statusText = "Senha reconhecida: $text";
      });
    };
    _voiceService.onListeningStateChanged = (isListening) {
      if (mounted) {
        setState(() {
          _isListening = isListening;
        });
      }
    };
  }

  String t(String key) => AppLocalizations.t(key, _selectedLanguage);

  Future<void> _saveAndContinue() async {
    if (_controller.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('error_password'))),
      );
      return;
    }

    await _dbService.init(); // Ensure DB is ready
    await _dbService.setWakeWord(_controller.text.trim());
    await _dbService.setGroqApiKey(_groqKeyController.text.trim());
    await _dbService.setLanguage(_selectedLanguage);
    await _voiceService.setLanguage(_selectedLanguage);
    
    if (mounted) {
      if (widget.isSettings) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t('saved_settings'))),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    }
  }

  Future<void> _openGroqConsole() async {
    final url = Uri.parse('https://console.groq.com/keys');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(t('get_groq_key_title')),
            content: const SelectableText(
              "Acesse o site abaixo para criar sua chave gratuita:\n\n"
              "https://console.groq.com/keys"
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(t('close')),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.isSettings ? AppBar(title: Text(t('settings_title'))) : null,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!widget.isSettings)
                  FadeInDown(
                    child: Text(
                      t('onboarding_title'),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                const SizedBox(height: 40),
                
                // Wake Word Section
                FadeIn(
                  child: Text(
                    _statusText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () async {
                    FocusScope.of(context).unfocus(); // Close keyboard
                    
                    // ✅ CORREÇÃO: Usar rationale dialog conforme Google Play Policy
                    var status = await PermissionRationaleDialog.requestMicrophoneWithRationale(context);
                    
                    if (status.isGranted) {
                      if (_isListening) {
                        await _voiceService.stop();
                      } else {
                        await _voiceService.startListening();
                        // Check if it actually started (give it a moment)
                        await Future.delayed(const Duration(milliseconds: 500));
                        if (!_isListening) {
                           if (context.mounted) {
                             ScaffoldMessenger.of(context).showSnackBar(
                               SnackBar(content: Text(t('mic_init_error'))),
                             );
                           }
                        }
                      }
                    }
                    // Não precisa mais do else com openAppSettings - o dialog já trata isso
                  },
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: _isListening ? Colors.redAccent : Theme.of(context).colorScheme.primary,
                    child: Icon(
                      _isListening ? Icons.stop : Icons.mic,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _controller,
                  obscureText: true,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                  decoration: InputDecoration(
                    labelText: t('wake_word_label'),
                    hintText: t('wake_word_hint'),
                    hintStyle: const TextStyle(color: Colors.white30),
                    border: const OutlineInputBorder(),
                  ),
                ),
                
                const SizedBox(height: 40),
                const Divider(color: Colors.white24),
                const SizedBox(height: 20),

                // Language Selector
                DropdownButtonFormField<String>(
                  value: _selectedLanguage,
                  decoration: InputDecoration(
                    labelText: t('language_label'),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.language, color: Colors.white70),
                    labelStyle: const TextStyle(color: Colors.white70),
                  ),
                  dropdownColor: Colors.grey[900],
                  style: const TextStyle(color: Colors.white),
                  items: const [
                    DropdownMenuItem(value: 'pt_BR', child: Text("Português (Brasil)")),
                    DropdownMenuItem(value: 'pt_PT', child: Text("Português (Portugal)")),
                    DropdownMenuItem(value: 'es', child: Text("Español")),
                    DropdownMenuItem(value: 'en', child: Text("English")),
                    DropdownMenuItem(value: 'de', child: Text("Deutsch")),
                    DropdownMenuItem(value: 'it', child: Text("Italiano")),
                    DropdownMenuItem(value: 'fr', child: Text("Français")),
                    DropdownMenuItem(value: 'ja', child: Text("日本語 (Japanese)")),
                    DropdownMenuItem(value: 'hi', child: Text("हिन्दी (Hindi)")),
                    DropdownMenuItem(value: 'zh', child: Text("中文 (Chinese)")),
                    DropdownMenuItem(value: 'ar', child: Text("العربية (Arabic)")),
                    DropdownMenuItem(value: 'bn', child: Text("বাংলা (Bengali)")),
                    DropdownMenuItem(value: 'ru', child: Text("Русский (Russian)")),
                    DropdownMenuItem(value: 'id', child: Text("Bahasa Indonesia")),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedLanguage = value!;
                    });
                    _voiceService.setLanguage(_selectedLanguage);
                  },
                ),
                const SizedBox(height: 20),

                // Groq API Key Section
                FadeInLeft(
                  child: Text(
                    t('groq_label'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  t('groq_desc'),
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _groqKeyController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: t('groq_api_key_label'),
                    hintText: t('groq_hint'),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.help_outline),
                      onPressed: _openGroqConsole,
                      tooltip: t('how_to_get_key_tooltip'),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _openGroqConsole,
                  child: Text(t('no_key_link')),
                ),

                const SizedBox(height: 40),
                FadeInUp(
                  child: ElevatedButton(
                    onPressed: _saveAndContinue,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    ),
                    child: Text(widget.isSettings ? t('save_btn') : t('save_continue')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
