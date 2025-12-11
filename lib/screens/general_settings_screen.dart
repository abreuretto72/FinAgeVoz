import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../utils/localization.dart';

class GeneralSettingsScreen extends StatefulWidget {
  const GeneralSettingsScreen({super.key});

  @override
  State<GeneralSettingsScreen> createState() => _GeneralSettingsScreenState();
}

class _GeneralSettingsScreenState extends State<GeneralSettingsScreen> {
  final DatabaseService _dbService = DatabaseService();
  final AuthService _authService = AuthService();
  
  String get _currentLanguage => Localizations.localeOf(context).toString();

  final Map<String, String> _languages = {
    'pt_BR': 'Português (Brasil)',
    'pt_PT': 'Português (Portugal)',
    'en': 'English',
    'es': 'Español',
    'de': 'Deutsch',
    'it': 'Italiano',
    'fr': 'Français',
    'ja': '日本語',
    'hi': 'हिन्दी',
    'zh': '中文',
    'ar': 'العربية',
    'bn': 'বাংলা',
    'ru': 'Русский',
    'id': 'Bahasa Indonesia',
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _dbService.init();
    setState(() {});
  }

  String t(String key) => AppLocalizations.t(key, _currentLanguage);

  Future<void> _changeLanguage(String? newValue) async {
    if (newValue != null) {
      await _dbService.setLanguage(newValue);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t('language_changed_msg'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Configurações Gerais',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade700, Colors.blue.shade900],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.tune, color: Colors.white, size: 32),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Preferências Gerais',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Personalize a experiência do aplicativo',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Settings Container
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // Language
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.language, color: Colors.blue),
                      ),
                      title: Text(
                        t('language_label'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        _languages[_currentLanguage] ?? _currentLanguage,
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      trailing: DropdownButton<String>(
                        value: _currentLanguage,
                        dropdownColor: const Color(0xFF2C2C2C),
                        style: const TextStyle(color: Colors.white),
                        underline: Container(),
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                        onChanged: _changeLanguage,
                        items: _languages.entries.map((entry) {
                          return DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text(entry.value),
                          );
                        }).toList(),
                      ),
                    ),

                    const Divider(color: Colors.grey, height: 1),

                    // Always Announce Events
                    SwitchListTile(
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.record_voice_over, color: Colors.purple),
                      ),
                      title: Text(
                        t('settings_announce_events'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        t('settings_announce_events_desc'),
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      value: _dbService.getAlwaysAnnounceEvents(),
                      onChanged: (bool value) async {
                        await _dbService.setAlwaysAnnounceEvents(value);
                        setState(() {});
                      },
                      activeColor: Colors.purple,
                    ),

                    const Divider(color: Colors.grey, height: 1),

                    // Voice Commands
                    SwitchListTile(
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.mic, color: Colors.green),
                      ),
                      title: Text(
                        t('settings_enable_voice'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        t('settings_enable_voice_desc'),
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      value: _dbService.getVoiceCommandsEnabled(),
                      onChanged: (bool value) async {
                        await _dbService.setVoiceCommandsEnabled(value);
                        setState(() {});
                        
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(value 
                                ? t('voice_enabled_msg') 
                                : t('voice_disabled_msg')),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      },
                      activeColor: Colors.green,
                    ),

                    const Divider(color: Colors.grey, height: 1),

                    // Biometric Lock
                    SwitchListTile(
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.fingerprint, color: Colors.orange),
                      ),
                      title: Text(
                        t('settings_biometrics'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        t('settings_biometrics_desc'),
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      value: _dbService.getAppLockEnabled(),
                      onChanged: (bool value) async {
                        if (value) {
                          final available = await _authService.isBiometricAvailable();
                          if (!available) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(t('biometrics_unavailable'))),
                              );
                            }
                            return;
                          }
                        }
                        await _dbService.setAppLockEnabled(value);
                        setState(() {});
                      },
                      activeColor: Colors.orange,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Info Footer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade900.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade700.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade300, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Estas configurações afetam o comportamento geral do aplicativo',
                        style: TextStyle(
                          color: Colors.blue.shade100,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
