// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:uuid/uuid.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:device_calendar/device_calendar.dart' hide Event;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart';

import '../services/voice_service.dart';
import '../services/ai_service.dart';
import '../services/database_service.dart';
import '../services/event_notification_service.dart';
import '../services/import_service.dart';
import '../services/import_service.dart';
import '../services/contact_service.dart';
import '../services/transaction_notification_service.dart';

import '../models/transaction_model.dart';
import '../models/event_model.dart';
import '../models/category_model.dart';
import '../models/operation_history.dart';
import '../utils/localization.dart';
import '../utils/installment_helper.dart';

import 'finance_screen.dart';
import 'agenda_screen.dart';
import 'reports_screen.dart';
import 'category_screen.dart';
import 'onboarding_screen.dart';
import 'installments_report_screen.dart';
import 'data_management_screen.dart';
import 'settings_screen.dart';
import 'activity_log_screen.dart';
import '../services/query_service.dart';
import '../services/sync/cloud_sync_service.dart';
import 'sync_settings_screen.dart';
import '../services/subscription/feature_gate.dart';
import '../services/subscription/subscription_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final VoiceService _voiceService = VoiceService();
  final AIService _aiService = AIService();
  final DatabaseService _dbService = DatabaseService();
  final ImportService _importService = ImportService();

  bool _isListening = false;
  bool _isProcessing = false;
  String _statusText = "";
  
  
  String get _currentLanguage {
    final locale = Localizations.localeOf(context);
    // Normalizar o locale para o formato esperado
    if (locale.countryCode != null && locale.countryCode!.isNotEmpty) {
      return '${locale.languageCode}_${locale.countryCode}';
    }
    return locale.languageCode;
  }
  
  // Static flag to ensure events are announced only once per app session
  static bool _hasAnnouncedEvents = false;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _initVoice();
    // Check for events on startup as requested
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 2), () async {
        try {
          await _checkTodayEvents();
          await _checkInstallmentNotifications();
        } catch (e) {
          print("Error in startup checks: $e");
        }
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_statusText.isEmpty) {
      _statusText = t('status_tap_to_speak');
    }
  }

  String t(String key) => AppLocalizations.t(key, _currentLanguage);

  // ---------------------------------------------------------------------
  // Helper methods
  // ---------------------------------------------------------------------
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t('help_title')),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(t('help_transactions'), style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(t('help_trans_1')),
              Text(t('help_trans_2')),
              Text(t('help_trans_3')),
              const SizedBox(height: 10),
              Text(t('help_agenda'), style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(t('help_agenda_1')),
              Text(t('help_agenda_2')),
              const SizedBox(height: 10),
              Text(t('help_attachments'), style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(t('help_attach_1')),
              Text(t('help_attach_2')),
              const SizedBox(height: 10),
              Text(t('help_settings'), style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(t('help_settings_1')),
              Text(t('help_settings_2')),
              const SizedBox(height: 10),
              Text(t('help_navigation'), style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(t('help_nav_1')),
              Text(t('help_nav_2')),
              Text(t('help_nav_3')),
              const SizedBox(height: 10),
              Text(t('help_tips'), style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(t('help_tip_1')),
              Text(t('help_tip_2')),
              const SizedBox(height: 10),
              Text(t('help_important'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
              Text(t('help_imp_1')),
              Text(t('help_imp_2')),
              const SizedBox(height: 10),
              Text(t('help_api_limit'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              Text(t('help_api_1')),
              Text(t('help_api_2')),
              Text(t('help_api_3')),
              Text(t('help_api_4')),
              const SizedBox(height: 10),
              Text(t('help_recommendation'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              Text(t('help_rec_1')),
              Text(t('help_rec_2')),
              Text(t('help_rec_3')),
              Text(t('help_rec_4')),
            ],
          ),
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

  Future<void> _navigate(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    if (mounted) {
      _initVoice();
    }
  }

  Future<void> _importTransactions() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      final count = await _importService.importTransactions();
      
      // Close loading indicator
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(count > 0 
              ? '$count${t('transactions_imported_success')}' 
              : t('no_transactions_imported')),
            backgroundColor: count > 0 ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      // Close loading indicator if open
      if (mounted) Navigator.pop(context);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${t('error_import')}$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _importCalendarEvents() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      final calendars = await _importService.retrieveDeviceCalendars();
      
      // Close loading indicator
      if (mounted) Navigator.pop(context);

      if (calendars.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t('calendar_error_not_found')),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(t('select_calendar')),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: calendars.length,
                  itemBuilder: (context, index) {
                    final calendar = calendars[index];
                    return ListTile(
                      title: Text(calendar.name ?? t('no_name')),
                      subtitle: Text(calendar.accountName ?? ''),
                      onTap: () async {
                        Navigator.pop(context); // Close selection dialog
                        await _processCalendarImport(calendar.id!);
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(t('cancel')),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      // Close loading indicator if open (though we popped it earlier, this is for safety if error happened before pop)
      // But we already popped. So just show error.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${t('error_fetch_calendars')}$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _processCalendarImport(String calendarId) async {
    try {
       showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      final count = await _importService.importFromDeviceCalendar(calendarId);

      if (mounted) Navigator.pop(context); // Close loading

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(count > 0 
              ? '$count${t('events_imported_success')}' 
              : t('no_new_events')),
            backgroundColor: count > 0 ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${t('error_import_events')}$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportTransactions() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      await _importService.exportTransactionsToCsv();
      
      if (mounted) Navigator.pop(context); // Close loading

    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${t('error_export')}$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportCalendarEvents() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      final calendars = await _importService.retrieveDeviceCalendars();
      
      if (mounted) Navigator.pop(context); // Close loading

      if (calendars.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t('no_calendars_found')),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(t('select_calendar_dest')),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: calendars.length,
                  itemBuilder: (context, index) {
                    final calendar = calendars[index];
                    // Filter out read-only calendars if possible, but device_calendar doesn't explicitly expose isReadOnly easily in all versions, 
                    // though usually we can write to most.
                    return ListTile(
                      title: Text(calendar.name ?? t('no_name')),
                      subtitle: Text(calendar.accountName ?? ''),
                      onTap: () async {
                        Navigator.pop(context); // Close selection dialog
                        await _processCalendarExport(calendar.id!);
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(t('cancel')),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${t('calendar_fetch_error')}$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _processCalendarExport(String calendarId) async {
    try {
       showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      final count = await _importService.exportEventsToDeviceCalendar(calendarId);

      if (mounted) Navigator.pop(context); // Close loading

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(count > 0 
              ? '$count${t('events_exported_success_suffix')}' 
              : t('no_events_to_export')),
            backgroundColor: count > 0 ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${t('event_export_error')}$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _initVoice() async {
    await _dbService.init();
    await _dbService.init();
    // final language = _dbService.getLanguage(); // No longer needed
    // setState(() {
    //   _currentLanguage = language;
    // });
    
    // Check if voice commands are enabled in settings
    final voiceEnabled = _dbService.getVoiceCommandsEnabled();
    
    if (!voiceEnabled) {
      // Voice commands disabled by user - show info
      setState(() {
        _statusText = t('mic_disabled');
      });
      
      // Show info dialog
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(t('voice_commands_disabled_title')),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t('voice_commands_disabled_msg')),
                    SizedBox(height: 10),
                    Text(t('you_can_label'), style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(t('manual_usage_option')),
                    Text(t('enable_voice_option')),
                    Text(t('enable_voice_path')),
                    SizedBox(height: 10),
                    Text(t('voice_commands_note'), 
                      style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12, color: Colors.grey)),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(t('understood')),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _navigate(const SettingsScreen());
                    },
                    child: Text(t('go_to_settings')),
                  ),
                ],
              ),
            );
          }
        });
      }
      return; // Don't initialize voice service
    }
    
    // Voice commands enabled - check API key
    final userGroqKey = _dbService.getGroqApiKey();
    final envGroqKey = dotenv.env['GROQ_API_KEY'];
    final hasApiKey = (userGroqKey != null && userGroqKey.isNotEmpty) || 
                      (envGroqKey != null && envGroqKey.isNotEmpty);
    
    if (!hasApiKey) {
      // No API key configured - show warning
      setState(() {
        _statusText = t('api_key_not_configured');
      });
      
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(t('api_key_warning_title')),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t('voice_commands_setup_msg')),
                    SizedBox(height: 10),
                    Text(t('options_label'), style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(t('configure_api_option')),
                    Text(t('disable_voice_option')),
                    SizedBox(height: 10),
                    Text(t('get_key_at'), 
                      style: TextStyle(fontStyle: FontStyle.italic, color: Colors.blue)),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(t('later')),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _navigate(const SettingsScreen());
                    },
                    child: Text(t('configure')),
                  ),
                ],
              ),
            );
          }
        });
      }
      return; // Don't initialize voice service
    }
    
    // Voice enabled and API key configured - initialize voice normally
    setState(() {
      _statusText = t('status_tap_to_speak');
    });
    await _voiceService.init();
    print("DEBUG HomeScreen: Setting language to: $_currentLanguage");
    await _voiceService.setLanguage(_currentLanguage);
    _voiceService.onResult = (text) => _processCommand(text);
    _voiceService.onListeningStateChanged = (isListening) {
      if (mounted) {
        setState(() {
          _isListening = isListening;
          if (!isListening && !_isProcessing) {
            _statusText = t('status_tap_to_speak');
          } else if (isListening) {
            _statusText = t('status_listening');
          }
        });
      }
    };
    _verifyGroqModel();
    _checkTodayEvents();
    _checkInstallmentNotifications();
    _checkCloudRestore();
  }

  Future<void> _checkCloudRestore() async {
    // Check if we should prompt for restore
    final hasCloudData = await CloudSyncService().hasCloudDataToRestore();
    if (hasCloudData && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Restaurar Dados?'),
          content: const Text('Detectamos dados na nuvem. Deseja restaurá-los neste aparelho?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t('cancel')),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                // Navigate to Sync Settings to handle the sync
                _navigate(const SyncSettingsScreen());
                // Or trigger sync directly:
                // await CloudSyncService().sync();
              },
              child: const Text('Restaurar'),
            ),
          ],
        ),
      );
    }
  }





  // ---------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF121212),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.blue),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: Colors.blue),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'FinAgeVoz',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text(t('menu_settings')),
              onTap: () {
                Navigator.pop(context);
                _navigate(const SettingsScreen());
              },
            ),
            ListTile(
              leading: const Icon(Icons.storage),
              title: Text(t('menu_manage_data')),
              onTap: () {
                Navigator.pop(context);
                _navigate(const DataManagementScreen());
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Histórico de Atividades'),
              onTap: () {
                Navigator.pop(context);
                _navigate(const ActivityLogScreen());
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_upload),
              title: Text(t('menu_import_transactions')),
              onTap: () {
                Navigator.pop(context);
                _importTransactions();
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: Text(t('menu_import_calendar')),
              onTap: () {
                Navigator.pop(context);
                _importCalendarEvents();
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_download),
              title: Text(t('menu_export_transactions')),
              onTap: () {
                Navigator.pop(context);
                _exportTransactions();
              },
            ),
            ListTile(
              leading: const Icon(Icons.event_available),
              title: Text(t('menu_export_calendar')),
              onTap: () {
                Navigator.pop(context);
                _exportCalendarEvents();
              },
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: Text(t('nav_categories')),
              onTap: () {
                Navigator.pop(context);
                _navigate(const CategoryScreen());
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: Text(t('menu_about')),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(t('about_title')),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t('about_version')),
                        const SizedBox(height: 10),
                        Text(t('about_description')),
                        const SizedBox(height: 20),
                        Text(t('about_developed_by'), style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(t('about_company')),
                        const SizedBox(height: 5),
                        Text(t('about_email_label'), style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(t('about_email')),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(t('close')),
                      ),
                    ],
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red),
              title: Text(t('menu_exit'), style: const TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                SystemNavigator.pop();
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text('FinAgeVoz', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: _showHelpDialog,
          ),
          IconButton(
            icon: const Icon(Icons.category, color: Colors.white),
            onPressed: () => _navigate(const CategoryScreen()),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF121212), Color(0xFF1E1E1E)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Card
            Padding(
              padding: EdgeInsets.only(top: 20.0),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.account_balance_wallet, color: Colors.blue, size: 30),
                    ),
                    const SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'FinAgeVoz',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                        Text(
                          t('subtitle'),
                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Center Section (Status + Mic)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          _statusText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.cyanAccent, fontSize: 20, fontWeight: FontWeight.w500),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.help_outline, color: Colors.cyanAccent),
                        tooltip: t('menu_help'),
                        onPressed: _showHelpDialog,
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  GestureDetector(
                    onTap: () async {
                      // Feature Gate Check
                      final allowed = await FeatureGate(SubscriptionService()).canUseFeature(context, AppFeature.voiceCommands);
                      if (!allowed) return;

                      // Check if voice commands are enabled
                      final voiceEnabled = _dbService.getVoiceCommandsEnabled();
                      
                      if (!voiceEnabled) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(t('msg_enable_voice')),
                            duration: Duration(seconds: 3),
                          ),
                        );
                        return;
                      }
                      
                      // Check if API key is configured
                      final userGroqKey = _dbService.getGroqApiKey();
                      final envGroqKey = dotenv.env['GROQ_API_KEY'];
                      final hasApiKey = (userGroqKey != null && userGroqKey.isNotEmpty) || 
                                        (envGroqKey != null && envGroqKey.isNotEmpty);
                      
                      if (!hasApiKey) {
                        // Show warning that API key is needed
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(t('msg_configure_api')),
                            duration: Duration(seconds: 3),
                          ),
                        );
                        return;
                      }
                      
                      // Voice enabled and API key configured - proceed with voice
                      if (!_isListening) {
                        await _voiceService.startListening();
                      } else {
                        await _voiceService.stop();
                      }
                    },
                    child: AvatarGlow(
                      animate: _isListening,
                      glowColor: Colors.cyan,
                      duration: const Duration(milliseconds: 2000),
                      repeat: true,
                      child: CircleAvatar(
                        backgroundColor: Colors.cyan,
                        radius: 48,
                        child: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Bottom Section (Quick Access)
            Padding(
              padding: const EdgeInsets.only(bottom: 80.0),
              child: Column(
                children: [
                  Text(
                    t('quick_access'),
                    style: const TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildQuickAccessButton(
                        icon: Icons.attach_money,
                        label: t('nav_finance'),
                        color: Colors.green,
                        onTap: () => _navigate(const FinanceScreen()),
                      ),
                      _buildQuickAccessButton(
                        icon: Icons.calendar_today,
                        label: t('nav_agenda'),
                        color: Colors.blue,
                        onTap: () => _navigate(const AgendaScreen()),
                      ),
                      _buildQuickAccessButton(
                        icon: Icons.bar_chart,
                        label: t('nav_reports'),
                        color: Colors.purple,
                        onTap: () => _navigate(const ReportsScreen()),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // Placeholder methods referenced elsewhere (implementations exist elsewhere)
  Future<void> _processCommand(String text) async {
  if (text.isEmpty) return;

  setState(() {
    _isProcessing = true;
    _statusText = t('status_processing');
  });

  try {
    final lowerText = text.toLowerCase();
    final cleanText = lowerText.replaceAll(RegExp(r'[!.,?]'), '').trim();

    // Confirmation / acknowledgment commands
    if (['ok', 'tá bom', 'ta bom', 'certo', 'entendido', 'sim', 'pode ir', 'confirmado', 'confirmar']
        .contains(cleanText)) {
      await _voiceService.speak('Entendido.');
      setState(() {
        _isProcessing = false;
        _statusText = t('status_idle');
      });
      return;
    }

    // Simple query pre‑filter (example: gasolina)
    if (cleanText.contains('gasolina') && cleanText.contains('gastei')) {
      final answer = await QueryService(_dbService).answerSimpleQuestion(text, _currentLanguage);
      await _voiceService.speak(answer);
      setState(() {
        _isProcessing = false;
        _statusText = t('status_idle');
      });
      return;
    }

    // Process with AI
    final result = await _aiService.processCommand(text);
    print('AI Result: $result');
    final intent = result['intent'];

    // Debug unknown intents
    if (intent == 'UNKNOWN' || intent == null) {
      print("DEBUG: AI returned UNKNOWN intent for command: '$text'");
      print('DEBUG: Full AI response: $result');
    }

    if (intent == 'ADD_TRANSACTION') {
      final data = result['transaction'];
      if (data != null) {
        final description = data['description'] ?? 'Despesa';
        final amount = (data['amount'] as num?)?.toDouble();
        final isExpense = data['isExpense'] ?? true;
        final dateStr = data['date'];
        final date = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();
        final category = data['category'] ?? 'Outras Despesas';
        final subcategory = data['subcategory'];
        final installments = data['installments'] as int? ?? 1;
        final downPayment = (data['downPayment'] as num?)?.toDouble() ?? 0.0;
        final installmentAmount = (data['installmentAmount'] as num?)?.toDouble();

        if (installments > 1) {
          if (amount == null && installmentAmount == null) {
            await _voiceService.speak('Não entendi os valores do parcelamento.');
            return;
          }
          DateTime firstInstallmentDate = date;
          if (downPayment > 0) {
            firstInstallmentDate = DateTime(date.year, date.month + 1, date.day, date.hour, date.minute);
          }
          final transactions = InstallmentHelper.createInstallments(
            description: description,
            totalAmount: amount,
            installments: installments,
            firstInstallmentDate: firstInstallmentDate,
            category: category,
            subcategory: subcategory,
            isExpense: isExpense,
            downPayment: downPayment,
            downPaymentDate: date,
            installmentValue: installmentAmount,
          );
          final transactionIds = <String>[];
          for (final t in transactions) {
            await _dbService.addTransaction(t);
            transactionIds.add(t.id);
          }
          await _dbService.addOperationToHistory(OperationHistory(
            id: const Uuid().v4(),
            type: 'transaction',
            description: isExpense
                ? "Compra parcelada: $description ($installments x)"
                : "Receita parcelada: $description ($installments x)",
            timestamp: DateTime.now(),
            transactionIds: transactionIds,
          ));
          double totalFeedback = amount ?? 0.0;
          if (installmentAmount != null) {
            totalFeedback = downPayment + (installmentAmount * installments);
          } else if (amount != null) {
            totalFeedback = amount;
          }
          final installmentVal = installmentAmount ?? ((totalFeedback - downPayment) / installments);
          await _voiceService.speak(
            isExpense
                ? 'Compra de $description registrada. ${downPayment > 0 ? 'Entrada de ${downPayment.toStringAsFixed(2)} e ' : ''}$installments parcelas de ${installmentVal.toStringAsFixed(2)} reais.'
                : 'Receita de $description registrada. ${downPayment > 0 ? 'Entrada de ${downPayment.toStringAsFixed(2)} e ' : ''}$installments parcelas de ${installmentVal.toStringAsFixed(2)} reais.',
          );
        } else {
          if (amount == null) {
            await _voiceService.speak('Não entendi o valor da transação.');
            return;
          }
          final transaction = Transaction(
            id: const Uuid().v4(),
            description: description,
            amount: amount,
            isExpense: isExpense,
            date: date,
            category: category,
            subcategory: subcategory,
          );
          await _dbService.addTransaction(transaction);
          await _dbService.addOperationToHistory(OperationHistory(
            id: const Uuid().v4(),
            type: 'transaction',
            description: isExpense ? "Gasto de $description" : "Receita de $description",
            timestamp: DateTime.now(),
            transactionIds: [transaction.id],
          ));
          await _voiceService.speak(
            isExpense
                ? 'Gasto de $description no valor de ${amount.toStringAsFixed(2)} reais registrado.'
                : 'Receita de $description no valor de ${amount.toStringAsFixed(2)} reais registrada.',
          );
        }
      }
    } else if (intent == 'ADD_EVENT') {
      final data = result['event'];
      if (data != null) {
        final title = data['title'] ?? 'Evento';
        final dateStr = data['date'];
        final date = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();
        final recurrence = data['recurrence'];
        final reminderMinutes = data['reminderMinutes'] as int? ?? 30; // Capture reminder minutes
        
        final event = Event(
          id: const Uuid().v4(),
          title: title,
          date: date,
          description: data['description'] ?? '',
          recurrence: recurrence,
          reminderMinutes: reminderMinutes,
        );
        await _dbService.addEvent(event);
        await _dbService.addOperationToHistory(OperationHistory(
          id: const Uuid().v4(),
          type: 'event',
          description: title,
          timestamp: DateTime.now(),
          transactionIds: [],
          eventId: event.id,
        ));
        await _voiceService.speak('Evento $title agendado para ${DateFormat('dd/MM HH:mm').format(date)}.');
      }
    } else if (intent == 'NAVIGATE') {
      final target = result['navigation']?['target'];
      if (target == 'FINANCE') {
        _navigate(const FinanceScreen());
      } else if (target == 'AGENDA') {
        _navigate(const AgendaScreen());
      } else if (target == 'REPORTS') {
        _navigate(const ReportsScreen());
      } else if (target == 'INSTALLMENTS') {
        _navigate(const InstallmentsReportScreen());
      } else if (target == 'CATEGORIES') {
        _navigate(const CategoryScreen());
      } else if (target == 'CLOSE') {
        await _voiceService.speak('Até logo.');
      }
    } else if (intent == 'CALL_CONTACT') {
      final name = result['contact']?['name'];
      if (name != null) {
        await _voiceService.speak('Buscando contato $name...');
        final phoneNumber = await ContactService().findContactPhoneNumber(name);
        
        if (phoneNumber != null) {
          await _voiceService.speak('Abrindo WhatsApp para $name.');
          final success = await ContactService().callOnWhatsApp(phoneNumber);
          if (success) {
             await _dbService.addOperationToHistory(OperationHistory(
              id: const Uuid().v4(),
              type: 'call',
              description: "Ligação para $name",
              timestamp: DateTime.now(),
              transactionIds: [],
            ));
          } else {
            await _voiceService.speak('Não foi possível abrir o WhatsApp.');
          }
        } else {
          await _voiceService.speak('Não encontrei o contato $name na sua agenda.');
        }
      } else {
        await _voiceService.speak('Não entendi qual contato você quer chamar.');
      }
    } else if (intent == 'QUERY') {
      // Handle financial/event questions
      print('DEBUG: Processing QUERY intent');
      try {
        final queryService = QueryService(_dbService);
        final questionPrompt = await queryService.answerFinancialQuestion(text, _currentLanguage);
        final answer = await _aiService.answerQuestion(questionPrompt);
        print('DEBUG: AI Answer: $answer');
        await _voiceService.speak(answer);
      } catch (e) {
        print('DEBUG: Error processing query: $e');
        await _voiceService.speak('Desculpe, não consegui processar sua pergunta no momento.');
      }
    } else if (intent == 'RATE_LIMIT_ERROR') {
      print('DEBUG: Rate limit error detected');
      await _voiceService.speak('Limite diário de uso da inteligência artificial atingido. Aguarde alguns minutos ou configure uma nova chave API nas configurações.');
    } else {
      print('DEBUG: Command not understood. Intent: $intent, Command: \'$text\'');
      await _voiceService.speak('Desculpe, não entendi o comando.');
    }
  } catch (e) {
    print('Error processing command: $e');
    String errorMessage = 'Ocorreu um erro ao processar seu comando.';
    if (e.toString().contains('timeout') || e.toString().contains('conexão')) {
      errorMessage = 'A conexão está lenta ou instável. Tente novamente.';
    }
    await _voiceService.speak(errorMessage);
  } finally {
    if (mounted) {
      setState(() {
        _isProcessing = false;
        _statusText = t('status_tap_to_speak');
      });
    }
  }
}

  Future<void> _verifyGroqModel() async {
    await _aiService.verifyAndUpdateModel();
  }

  Future<void> _checkTodayEvents() async {
    if (_hasAnnouncedEvents) return;
    
    final notificationService = EventNotificationService();
    await notificationService.checkAndNotifyTodayEvents();
    
    _hasAnnouncedEvents = true;
  }

  Future<void> _checkInstallmentNotifications() async {
    final service = TransactionNotificationService();
    final upcoming = await service.checkUpcomingInstallments();
    
    if (upcoming.isNotEmpty && mounted) {
      for (var t in upcoming) {
        if (!mounted) return;
        
        final dateStr = DateFormat('dd/MM').format(t.date);
        final message = "A parcela de ${t.description} vence amanhã, dia $dateStr. Valor: ${t.amount.toStringAsFixed(2)} reais.";
        
        await _voiceService.speak(message);
        await Future.delayed(const Duration(seconds: 1));
        await _voiceService.speak("Você já efetuou o pagamento?");
        
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Lembrete de Pagamento'),
            content: Text('A parcela de ${t.description} vence amanhã.\nValor: R\$ ${t.amount.toStringAsFixed(2)}\n\nVocê já pagou?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Não'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Sim, já paguei'),
              ),
            ],
          ),
        );
        
        if (result == true) {
          await _dbService.markTransactionAsPaid(t.id, DateTime.now());
          await _voiceService.speak("Marcado como pago.");
        } else {
          await _voiceService.speak("Ok, vou lembrar depois.");
        }
        
        await Future.delayed(const Duration(seconds: 1));
      }
    }
  }
}
