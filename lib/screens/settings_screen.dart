import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../utils/localization.dart';

import 'sync_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
    setState(() {
      // _currentLanguage = _dbService.getLanguage();
    });
  }

  String t(String key) => AppLocalizations.t(key, _currentLanguage);

  Future<void> _changeLanguage(String? newValue) async {
    if (newValue != null) {
      await _dbService.setLanguage(newValue);
      // setState(() {
      //   _currentLanguage = newValue;
      // });
      // Show snackbar to inform restart might be needed for full effect
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
        title: Text(t('settings_title'), style: const TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 80), // Padding extra no final
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text(
            t('settings_general'),
            style: TextStyle(
              color: Colors.blue,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language, color: Colors.white),
                  title: Text(t('language_label'), style: const TextStyle(color: Colors.white)),
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
                SwitchListTile(
                  secondary: const Icon(Icons.record_voice_over, color: Colors.white),
                  title: Text(t('settings_announce_events'), style: const TextStyle(color: Colors.white)),
                  subtitle: Text(t('settings_announce_events_desc'), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  value: _dbService.getAlwaysAnnounceEvents(),
                  onChanged: (bool value) async {
                    await _dbService.setAlwaysAnnounceEvents(value);
                    setState(() {});
                  },
                  activeColor: Colors.blue,
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.mic, color: Colors.white),
                  title: Text(t('settings_enable_voice'), style: const TextStyle(color: Colors.white)),
                  subtitle: Text(t('settings_enable_voice_desc'), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  value: _dbService.getVoiceCommandsEnabled(),
                  onChanged: (bool value) async {
                    await _dbService.setVoiceCommandsEnabled(value);
                    setState(() {});
                    
                    // Show feedback
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
                  activeColor: Colors.blue,
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.lock, color: Colors.white),
                  title: const Text('Bloqueio por Biometria', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Exigir autenticação ao abrir o app', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  value: _dbService.getAppLockEnabled(),
                  onChanged: (bool value) async {
                    if (value) {
                      // Verificar se biometria está disponível antes de ativar
                      final available = await _authService.isBiometricAvailable();
                      if (!available) {
                         if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Biometria não disponível neste dispositivo.')),
                          );
                        }
                        return;
                      }
                    }
                    await _dbService.setAppLockEnabled(value);
                    setState(() {});
                  },
                  activeColor: Colors.blue,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 30),
          Text(
            'Nuvem & Sincronização',
            style: TextStyle(
              color: Colors.blue,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cloud_sync, color: Colors.blue),
                  title: const Text('Sincronização na Nuvem', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Backup e sincronização entre dispositivos', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SyncSettingsScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 30),
          Text(
            t('settings_data'),
            style: TextStyle(
              color: Colors.blue,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.restore, color: Colors.orange),
                  title: Text(t('settings_reset_categories'), style: const TextStyle(color: Colors.white)),
                  subtitle: Text(t('settings_reset_categories_desc'), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  onTap: () => _confirmResetCategories(),
                ),
                const Divider(color: Colors.grey),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: Text(t('settings_reset_app'), style: const TextStyle(color: Colors.red)),
                  subtitle: Text(t('settings_reset_app_desc'), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  onTap: () => _deleteAllData(),
                ),
              ],
            ),
          ),
          
          // Only show API section if voice commands are enabled
          if (_dbService.getVoiceCommandsEnabled()) ...[
            const SizedBox(height: 30),
            Text(
              t('settings_api_title'),
              style: TextStyle(
                color: Colors.blue,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            // Current API indicator
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _dbService.getGroqApiKey()?.isNotEmpty == true 
                  ? Colors.green.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _dbService.getGroqApiKey()?.isNotEmpty == true 
                    ? Colors.green
                    : Colors.orange,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _dbService.getGroqApiKey()?.isNotEmpty == true 
                      ? Icons.check_circle
                      : Icons.info,
                    color: _dbService.getGroqApiKey()?.isNotEmpty == true 
                      ? Colors.green
                      : Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t('settings_api_in_use'),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _dbService.getGroqApiKey()?.isNotEmpty == true 
                            ? 'Groq (${_dbService.getGroqModel()})'
                            : t('settings_no_api'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.key, color: Colors.cyan),
                    title: Text(t('groq_api_key_label'), style: const TextStyle(color: Colors.white)),
                    subtitle: Text(
                      _dbService.getGroqApiKey()?.isNotEmpty == true 
                        ? t('settings_configured') 
                        : t('settings_not_configured'),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    trailing: const Icon(Icons.edit, color: Colors.white, size: 20),
                    onTap: () => _showApiKeyDialog(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
    ),
    );
  }

  void _showApiKeyDialog() {
    final controller = TextEditingController(text: _dbService.getGroqApiKey() ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('groq_api_key_label')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t('how_to_get_key_title'),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                t('get_key_step_1'),
                style: const TextStyle(fontSize: 12, color: Colors.blue),
              ),
              const SizedBox(height: 4),
              Text(
                t('get_key_step_2'),
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                t('get_key_step_3'),
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                t('get_key_step_4'),
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                t('get_key_step_5'),
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                t('paste_key_below'),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: t('api_key_label'),
                  hintText: 'gsk_...',
                  border: const OutlineInputBorder(),
                  helperText: t('api_key_helper'),
                ),
                obscureText: true,
                maxLines: 1,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('cancel')),
          ),
          TextButton(
            onPressed: () async {
              await _dbService.setGroqApiKey(controller.text.trim());
              if (mounted) {
                Navigator.pop(context);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(t('api_key_updated'))),
                );
              }
            },
            child: Text(t('save')),
          ),
        ],
      ),
    );
  }

  void _confirmResetCategories() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('confirm_reset_categories_title')),
        content: Text(t('confirm_reset_categories_msg')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _dbService.resetDefaultCategories();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(t('categories_reset_success'))),
                );
              }
            },
            child: Text(t('reset')),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('confirm_wipe_title')),
        content: Text(t('confirm_wipe_msg')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t('wipe_all')),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Delete everything by setting cutoff date to far future
      final futureDate = DateTime.now().add(const Duration(days: 36500)); // 100 years
      final deleted = await _dbService.deleteOldData(futureDate);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              t('data_wiped_msg')
                  .replaceAll('{transactions}', deleted['transactions'].toString())
                  .replaceAll('{events}', deleted['events'].toString()),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${t('error_prefix')}$e')),
        );
      }
    }
  }
}
