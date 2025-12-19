import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../utils/localization.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/talking_clock_service.dart';
import '../utils/input_formatters.dart';

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

                    // User Name
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.person, color: Colors.blue),
                      ),
                      title: const Text(
                        "Seu Nome",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        _dbService.getUserName() ?? "Toque para definir",
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      trailing: const Icon(Icons.edit, color: Colors.white, size: 20),
                      onTap: () {
                         _showUserNameInput(context);
                      },
                    ),
                    
                    const Divider(color: Colors.grey, height: 1),

                    // Birth Date (Perfil / Horóscopo)
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.pink.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.cake, color: Colors.pink),
                      ),
                      title: const Text(
                        "Data de Nascimento",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        _dbService.getUserBirthDate() != null
                            ? "${_dbService.getUserBirthDate()!.day}/${_dbService.getUserBirthDate()!.month}/${_dbService.getUserBirthDate()!.year}"
                            : "Toque para definir (Necessário para Horóscopo)",
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      trailing: const Icon(Icons.edit, color: Colors.white, size: 20),
                      onTap: () {
                         _showBirthDateInput(context);
                      },
                    ),
                    
                    const Divider(color: Colors.grey, height: 1),

                    // Favorite Team
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.sports_soccer, color: Colors.green),
                      ),
                      title: const Text(
                        "Time do Coração",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        _dbService.getUserFavoriteTeam() ?? "Toque para definir",
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      trailing: const Icon(Icons.edit, color: Colors.white, size: 20),
                      onTap: () {
                         _showFavoriteTeamInput(context);
                      },
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

                    // Groq API Key
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.cyan.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.key, color: Colors.cyan),
                      ),
                      title: Text(
                        t('groq_api_key_label'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        (_dbService.getGroqApiKey()?.isNotEmpty == true || (dotenv.env['GROQ_API_KEY']?.isNotEmpty == true))
                          ? t('settings_configured') 
                          : t('settings_not_configured'),
                        style: TextStyle(
                          color: (_dbService.getGroqApiKey()?.isNotEmpty == true || (dotenv.env['GROQ_API_KEY']?.isNotEmpty == true)) ? Colors.green : Colors.orange,
                          fontSize: 12
                        ),
                      ),
                      trailing: const Icon(Icons.edit, color: Colors.white, size: 20),
                      onTap: () => _showApiKeyDialog(),
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
                    
                    const Divider(color: Colors.grey, height: 1),

                    // Talking Clock (Relógio Falante)
                    SwitchListTile(
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.access_time_filled, color: Colors.teal),
                      ),
                      title: const Text(
                        "Relógio Falante",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: const Text(
                        "Falar a hora a cada 15 minutos (07h às 22h)",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      value: _dbService.getTalkingClockEnabled(),
                      onChanged: (bool value) async {
                        setState(() {
                             // Update Service directly to sync state
                             if (value) {
                                TalkingClockService().start();
                             } else {
                                TalkingClockService().stop();
                             }
                        });
                        // Service updates DB internally in start/stop methods I added? 
                        // Actually in my implementation of start/stop I added _dbService calls.
                        // But good to force rebuild UI.
                      },
                      activeColor: Colors.teal,
                    ),
                    
                    if (_dbService.getTalkingClockEnabled())
                        CheckboxListTile(
                           title: const Text(
                             "Data compl. apenas na hora cheia?",
                             style: TextStyle(color: Colors.white70, fontSize: 14),
                           ),
                           subtitle: const Text(
                             "Nas frações (15, 30, 45) fala apenas o horário.",
                             style: TextStyle(color: Colors.grey, fontSize: 11),
                           ),
                           contentPadding: const EdgeInsets.only(left: 72, right: 16),
                           value: _dbService.getTalkingClockDateOnHourOnly(),
                           onChanged: (val) {
                               if (val != null) {
                                   setState(() {
                                       TalkingClockService().setPreferences(speakDateOnHourOnly: val);
                                   });
                               }
                           },
                           activeColor: Colors.teal,
                           checkColor: Colors.white,
                        ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Agenda Settings Header
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'Agenda & Notificações',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold, // Section Header
                    fontSize: 16,
                  ),
                ),
              ),

              // Agenda Settings Container
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // Compromissos
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.calendar_today, color: Colors.blue),
                      ),
                      title: const Text("Compromissos", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                      subtitle: const Text("Antecedência de aviso", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      trailing: DropdownButton<int>(
                        value: _dbService.getDefaultAgendaReminderMinutes(),
                        dropdownColor: const Color(0xFF2C2C2C),
                        style: const TextStyle(color: Colors.white),
                        underline: Container(),
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                        onChanged: (val) async {
                          if (val != null) {
                            await _dbService.setDefaultAgendaReminderMinutes(val);
                            setState(() {});
                          }
                        },
                        items: [0, 5, 10, 15, 30, 60, 120].map((m) {
                          return DropdownMenuItem<int>(
                            value: m,
                            child: Text(m == 0 ? "No horário" : "$m min"),
                          );
                        }).toList(),
                      ),
                    ),
                    const Divider(color: Colors.grey, height: 1),
                    
                    // Remédios
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.pink.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.medication, color: Colors.pink),
                      ),
                      title: const Text("Remédios", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                      subtitle: const Text("Antecedência de aviso", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      trailing: DropdownButton<int>(
                        value: _dbService.getDefaultMedicineReminderMinutes(),
                        dropdownColor: const Color(0xFF2C2C2C),
                        style: const TextStyle(color: Colors.white),
                        underline: Container(),
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                        onChanged: (val) async {
                          if (val != null) {
                            await _dbService.setDefaultMedicineReminderMinutes(val);
                            setState(() {});
                          }
                        },
                        items: [0, 5, 10, 15, 30, 60, 120].map((m) {
                          return DropdownMenuItem<int>(
                            value: m,
                            child: Text(m == 0 ? "No horário" : "$m min"),
                          );
                        }).toList(),
                      ),
                    ),
                    const Divider(color: Colors.grey, height: 1),

                    // Pagamentos
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.attach_money, color: Colors.green),
                      ),
                      title: const Text("Pagamentos", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                      subtitle: const Text("Antecedência de aviso", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      trailing: DropdownButton<int>(
                        value: _dbService.getDefaultPaymentReminderMinutes(),
                        dropdownColor: const Color(0xFF2C2C2C),
                        style: const TextStyle(color: Colors.white),
                        underline: Container(),
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                        onChanged: (val) async {
                          if (val != null) {
                            await _dbService.setDefaultPaymentReminderMinutes(val);
                            setState(() {});
                          }
                        },
                        items: [0, 5, 10, 15, 30, 60, 120].map((m) {
                          return DropdownMenuItem<int>(
                            value: m,
                            child: Text(m == 0 ? "No horário" : "$m min"),
                          );
                        }).toList(),
                      ),
                    ),
                    const Divider(color: Colors.grey, height: 1),

                    // Quantidade de Avisos (Global)
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.notifications_active, color: Colors.orange),
                      ),
                      title: const Text("Quantidade de Avisos", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                      subtitle: const Text("Repetições do lembrete", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      trailing: DropdownButton<int>(
                        value: _dbService.getDefaultWarningCount(),
                        dropdownColor: const Color(0xFF2C2C2C),
                        style: const TextStyle(color: Colors.white),
                        underline: Container(),
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                        onChanged: (val) async {
                          if (val != null) {
                            await _dbService.setDefaultWarningCount(val);
                            setState(() {});
                          }
                        },
                        items: [1, 2, 3, 4, 5, 10].map((m) {
                          return DropdownMenuItem<int>(
                            value: m,
                            child: Text("$m x"),
                          );
                        }).toList(),
                      ),
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
  void _showApiKeyDialog() {
    final dbKey = _dbService.getGroqApiKey();
    final envKey = dotenv.env['GROQ_API_KEY'];
    final effectiveKey = (dbKey != null && dbKey.isNotEmpty) ? dbKey : (envKey ?? '');
    
    final controller = TextEditingController(text: effectiveKey);
    
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
  Future<void> _showBirthDateInput(BuildContext context) async {
      final TextEditingController controller = TextEditingController();
      final currentDate = _dbService.getUserBirthDate();
      if (currentDate != null) {
          // Fill current value
          String day = currentDate.day.toString().padLeft(2, '0');
          String month = currentDate.month.toString().padLeft(2, '0');
          String year = currentDate.year.toString();
          controller.text = "$day/$month/$year";
      }

      await showDialog(
        context: context, 
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF2C2C2C),
          title: const Text("Data de Nascimento", style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               const Text("Digite sua data de nascimento:", style: TextStyle(color: Colors.grey)),
               const SizedBox(height: 10),
               TextField(
                 controller: controller,
                 keyboardType: TextInputType.number,
                 style: const TextStyle(color: Colors.white, fontSize: 18),
                 decoration: InputDecoration(
                   hintText: "DD/MM/AAAA",
                   hintStyle: const TextStyle(color: Colors.white24),
                   filled: true,
                   fillColor: Colors.black26,
                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                   prefixIcon: const Icon(Icons.calendar_today, color: Colors.teal),
                 ),
                 inputFormatters: [
                   FilteringTextInputFormatter.digitsOnly,
                   DateInputFormatter(),
                 ],
               ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx), 
              child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              onPressed: () async {
                 String text = controller.text;
                 if (text.length != 10) {
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Data incompleta! Use o formato DD/MM/AAAA")));
                     return;
                 }
                 
                 try {
                     int day = int.parse(text.substring(0, 2));
                     int month = int.parse(text.substring(3, 5));
                     int year = int.parse(text.substring(6, 10));
                     
                     // Basic validation
                     if (month < 1 || month > 12) throw Exception("Mês inválido");
                     if (day < 1 || day > 31) throw Exception("Dia inválido");
                     if (year < 1900 || year > DateTime.now().year) throw Exception("Ano inválido");
                     
                     final date = DateTime(year, month, day);
                     await _dbService.setUserBirthDate(date);
                     
                     if (mounted) setState((){});
                     Navigator.pop(ctx);
                     
                 } catch (e) {
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Data inválida! Verifique os valores.")));
                 }
              }, 
              child: const Text("Salvar", style: TextStyle(color: Colors.white)),
            ),
          ],
        )
      );
  }

  Future<void> _showFavoriteTeamInput(BuildContext context) async {
      final TextEditingController controller = TextEditingController();
      final currentTeam = _dbService.getUserFavoriteTeam();
      if (currentTeam != null) {
          controller.text = currentTeam;
      }

      await showDialog(
        context: context, 
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF2C2C2C),
          title: const Text("Time do Coração", style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               const Text("Digite o nome do seu time:", style: TextStyle(color: Colors.grey)),
               const SizedBox(height: 10),
               TextField(
                 controller: controller,
                 style: const TextStyle(color: Colors.white, fontSize: 18),
                 decoration: InputDecoration(
                   hintText: "Ex: Flamengo, Palmeiras, Corinthians...",
                   hintStyle: const TextStyle(color: Colors.white24),
                   filled: true,
                   fillColor: Colors.black26,
                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                   prefixIcon: const Icon(Icons.sports_soccer, color: Colors.green),
                 ),
               ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx), 
              child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () async {
                 String team = controller.text.trim();
                 if (team.isEmpty) {
                     ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text("Digite o nome do time!"))
                     );
                     return;
                 }
                 
                 await _dbService.setUserFavoriteTeam(team);
                 if (mounted) setState((){});
                 Navigator.pop(ctx);
              }, 
              child: const Text("Salvar", style: TextStyle(color: Colors.white)),
            ),
          ],
        )
      );
  }

  Future<void> _showUserNameInput(BuildContext context) async {
      final TextEditingController controller = TextEditingController();
      final currentName = _dbService.getUserName();
      if (currentName != null) {
          controller.text = currentName;
      }

      await showDialog(
        context: context, 
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF2C2C2C),
          title: const Text("Seu Nome", style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               const Text("Digite seu primeiro nome:", style: TextStyle(color: Colors.grey)),
               const SizedBox(height: 10),
               TextField(
                 controller: controller,
                 style: const TextStyle(color: Colors.white, fontSize: 18),
                 decoration: InputDecoration(
                   hintText: "Ex: João, Maria, Pedro...",
                   hintStyle: const TextStyle(color: Colors.white24),
                   filled: true,
                   fillColor: Colors.black26,
                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                   prefixIcon: const Icon(Icons.person, color: Colors.blue),
                 ),
               ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx), 
              child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              onPressed: () async {
                 String name = controller.text.trim();
                 if (name.isEmpty) {
                     ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text("Digite seu nome!"))
                     );
                     return;
                 }
                 
                 await _dbService.setUserName(name);
                 if (mounted) setState((){});
                 Navigator.pop(ctx);
              }, 
              child: const Text("Salvar", style: TextStyle(color: Colors.white)),
            ),
          ],
        )
      );
  }
}
