// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:uuid/uuid.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:device_calendar/device_calendar.dart' hide Event;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart';

import '../services/voice_service.dart';
import '../voice/voice_controller.dart';
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
import '../services/agenda_repository.dart';
import '../models/agenda_models.dart';
import 'agenda_form_screen.dart';
import 'medicines/medicine_form_screen.dart';
import '../models/medicine_model.dart';

import 'finance_screen.dart';
import 'agenda_list_page.dart';
import 'reports_screen.dart';
import 'category_screen.dart';
import 'onboarding_screen.dart';
import 'installments_report_screen.dart';
import 'data_management_screen.dart';
import 'settings_screen.dart';
import 'help_screen.dart';
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
  late final VoiceController _voiceController;

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
    _voiceController = VoiceController(
      voiceService: _voiceService,
      aiService: _aiService,
      onProcessingStart: () {
          if (mounted) {
            setState(() {
              _isProcessing = true;
              _statusText = t('status_processing');
            });
          }
      },
      onProcessingEnd: () {
          if (mounted) {
            setState(() {
              _isProcessing = false;
              if (!_isListening) _statusText = t('status_idle');
            });
          }
      },
      onNavigateToForm: (item) {
         if (mounted) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => AgendaFormScreen(item: item)));
         }
      }
    );
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

      final count = await _importService.importTransactions(_currentLanguage);
      
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
          title: Text(t('restore_data_title')),
          content: Text(t('restore_data_msg')),
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
              child: Text(t('restore_button')),
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
              title: Text(t('menu_activity_log')),
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
            onPressed: () => _navigate(const HelpScreen()),
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
                        onPressed: () => _navigate(const HelpScreen()),
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
                        onTap: () => _navigate(const AgendaListPage()),
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
      print('DEBUG: Full AI response: $result');

    if (intent == 'ADD_AGENDA_ITEM') {
        await _voiceController.handleAgendaItem(result['agenda_item']);
        return;
    } else if (intent == 'QUERY') {
        await _voiceController.handleQuery(result['query']);
        return;
    } 

    if (intent == 'ADD_TRANSACTION') {
      final data = result['transaction'];
      if (data != null) {
        final description = data['description'] ?? 'Despesa';
        final amount = (data['amount'] as num?)?.toDouble();
        
        // Fix: isExpense matches 'EXPENSE' or 'INCOME'. AI might return 'isExpense' boolean or 'type' string.
        bool isExpense = true;
        if (data['type'] != null && data['type'] is String) {
           isExpense = (data['type'] as String).toUpperCase() == 'EXPENSE';
        } else if (data['isExpense'] != null && data['isExpense'] is bool) {
           isExpense = data['isExpense'];
        }
        
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
          final now = DateTime.now();
          final isTodayOrPast = date.isBefore(now) || 
                               (date.year == now.year && date.month == now.month && date.day == now.day);

          final transaction = Transaction(
            id: const Uuid().v4(),
            description: description,
            amount: amount,
            isExpense: isExpense,
            date: date,
            category: category,
            subcategory: subcategory,
            isPaid: isTodayOrPast,
            paymentDate: isTodayOrPast ? date : null,
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
        await _voiceService.speak('Evento $title agendado para ${DateFormat.Md(_currentLanguage).add_Hm().format(date)}.');
      }
    } else if (intent == 'ADD_AGENDA_ITEM') {
      final data = result['agenda_item'];
      if (data != null) {
        final typeStr = (data['type'] as String).toUpperCase();
        final title = data['title'] as String;
        final dateStr = data['date'] as String?;
        final timeStr = data['time'] as String?;
        
        DateTime? date;
        if (dateStr != null) {
           try { date = DateTime.parse(dateStr); } catch (_) {}
        }
        
        AgendaItemType type = AgendaItemType.values.firstWhere(
           (e) => e.toString().split('.').last == typeStr, 
           orElse: () => AgendaItemType.COMPROMISSO
        );

        final item = AgendaItem(
           tipo: type,
           titulo: title,
           descricao: data['description'],
           dataInicio: date,
           horarioInicio: timeStr,
           status: ItemStatus.PENDENTE,
        );
        
        if (type == AgendaItemType.PAGAMENTO) {
           item.pagamento = PagamentoInfo(
             valor: (data['payment_value'] as num?)?.toDouble() ?? 0.0,
             status: 'PENDENTE',
             dataVencimento: date ?? DateTime.now(),
           );
        } else if (type == AgendaItemType.REMEDIO) {
           // Rule: Never auto-save medicines. Open form.
           String medName = title;
           if (medName.toLowerCase().trim() == 'remédio' || medName.toLowerCase().contains('agendar remédio')) {
               medName = ""; 
           }
           
           // Create draft
           final draft = Remedio(
              id: const Uuid().v4(),
              nome: medName, 
              criadoEm: DateTime.now(),
              atualizadoEm: DateTime.now(),
           );
           
           await _voiceService.speak("Abrindo cadastro do remédio. Por favor, configure a posologia.");
           
           if (mounted) {
              _navigate(MedicineFormScreen(remedio: draft));
           }
           return; 
        } else if (type == AgendaItemType.ANIVERSARIO) {
           item.aniversario = AniversarioInfo(
             nomePessoa: data['person_name'] ?? title,
             notificarAntes: 1,
             parentesco: null, // Mandatory
           );
           
           // Clean Name
           String name = item.aniversario!.nomePessoa;
           if (name.toLowerCase() == 'aniversário' || 
               name.toLowerCase() == 'novo aniversário' ||
               name.toLowerCase().contains('adicionar aniversário')) {
               name = "";
               item.aniversario!.nomePessoa = "";
           } else if (name.isNotEmpty) {
               name = name[0].toUpperCase() + name.substring(1);
               item.aniversario!.nomePessoa = name;
           }

           item.titulo = name.isNotEmpty ? "Aniversário de $name" : "Novo Aniversário";
           
           if (item.recorrencia == null) {
              item.recorrencia = RecorrenciaInfo(frequencia: 'ANUAL');
           }
           
           // DO NOT SAVE. NAVIGATE.
           await _voiceService.speak('Confirme o nome e a data e informe o grau de parentesco do aniversariante antes de salvar.');
           if (mounted) _navigate(AgendaFormScreen(draftItem: item));
           return;
        }
        
        await AgendaRepository().addItem(item);
        await _voiceService.speak('Adicionado à agenda: $title');
      }
    } else if (intent == 'NAVIGATE') {
      final target = result['navigation']?['target'];
      if (target == 'FINANCE') {
        _navigate(const FinanceScreen());
      } else if (target == 'AGENDA') {
        _navigate(const AgendaListPage());
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
    
    // Check medicines
    await _checkMedicines();

    // Check birthdays
    await _checkBirthdays();

    _hasAnnouncedEvents = true;
  }

  Future<void> _checkBirthdays() async {
    final service = EventNotificationService();
    final birthdays = await service.getDueBirthdays();
    
    if (birthdays.isEmpty) return;
    
    // Announce
    if (birthdays.length == 1) {
       await _voiceService.speak("Hoje é o aniversário de ${birthdays.first.aniversario!.nomePessoa}.");
    } else {
       await _voiceService.speak("Hoje há ${birthdays.length} aniversários.");
    }
    await Future.delayed(const Duration(seconds: 3));

    for (var item in birthdays) {
       if (!mounted) return;
       await _showBirthdayDialog(item);
    }
  }

  Future<void> _showBirthdayDialog(AgendaItem item) async {
      final info = item.aniversario!;
      // Determine priority channel logic
      String? channelName;
      IconData? channelIcon;
      bool canSend = false;

      // Logic: WhatsApp -> Email -> SMS
      if (info.telefone != null && info.telefone!.isNotEmpty) {
         channelName = "WhatsApp";
         channelIcon = Icons.chat;
         canSend = true;
      } else if (info.emailContato != null && info.emailContato!.isNotEmpty) {
         channelName = "E-mail";
         channelIcon = Icons.email;
         canSend = true;
      } else if (info.smsPhone != null && info.smsPhone!.isNotEmpty) {
         channelName = "SMS";
         channelIcon = Icons.sms;
         canSend = true;
      } else {
         channelName = "Nenhum canal";
         channelIcon = Icons.error;
         canSend = false;
      }

      final msgCtrl = TextEditingController(text: info.mensagemPadrao ?? "Parabéns ${info.nomePessoa}! Tudo de bom!");

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
           return StatefulBuilder(
             builder: (context, setStateUi) {
               return AlertDialog(
                 title: Text("🎉 Aniversário de ${info.nomePessoa}"),
                 content: SingleChildScrollView(
                   child: Column(
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       if (!canSend)
                          const Text("⚠️ Sem contato cadastrado! Edite o item.", style: TextStyle(color: Colors.red)),
                       if (canSend)
                          Row(children: [
                             Icon(channelIcon, color: Colors.green),
                             const SizedBox(width: 8),
                             Text("Enviar via $channelName"),
                          ]),
                       const SizedBox(height: 10),
                       TextField(
                         controller: msgCtrl,
                         maxLines: 4,
                         decoration: InputDecoration(
                           labelText: "Mensagem",
                           border: const OutlineInputBorder(),
                           suffixIcon: IconButton(
                              icon: const Icon(Icons.auto_awesome, color: Colors.purple),
                              tooltip: "Gerar nova sugestão por IA",
                              onPressed: () async {
                                 // Generate AI
                                 // Reuse logic or simple prompt here
                                 String relationship = info.parentesco ?? "alguém especial";
                                 String prompt = "Gere uma mensagem curta de feliz aniversário para ${info.nomePessoa} ($relationship). ";
                                 // Simplified tone selection for dialog re-generation
                                 prompt += "Tom: Carinhoso e adequado.";
                                 
                                 final newMsg = await _aiService.answerQuestion(prompt);
                                 setStateUi(() {
                                    msgCtrl.text = newMsg.replaceAll('"', ''); 
                                 });
                              },
                           ),
                         ),
                       ),
                     ] 
                   ),
                 ),
                 actions: [
                    TextButton(
                      child: const Text("Lembrar depois"), 
                      onPressed: () => Navigator.pop(context)
                    ),
                    TextButton(
                      child: const Text("Já parabenizei"), 
                      onPressed: () async {
                         await EventNotificationService().markBirthdayAsSent(item);
                         Navigator.pop(context);
                         await _voiceService.speak("Ok, marcado como enviado.");
                      },
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.send),
                      label: Text(canSend ? "Enviar agora" : "Editar Contato"), 
                      onPressed: () async {
                         Navigator.pop(context);

                         if (!canSend) {
                            // Navigate to edit? Or just show error
                            // Simple for now: just close. User needs to edit manually.
                            await _voiceService.speak("Por favor adicione um contato na agenda.");
                            return;
                         }

                         bool sent = false;
                         if (channelName == "WhatsApp") {
                            sent = await ContactService().sendMessageOnWhatsApp(info.telefone!, msgCtrl.text);
                         } else if (channelName == "E-mail") {
                            final Uri emailLaunchUri = Uri(
                              scheme: 'mailto',
                              path: info.emailContato!,
                              query: 'subject=Feliz Aniversário ${info.nomePessoa}!&body=${Uri.encodeComponent(msgCtrl.text)}',
                            );
                            if (await canLaunchUrl(emailLaunchUri)) {
                               await launchUrl(emailLaunchUri);
                               sent = true;
                            }
                         } else if (channelName == "SMS") {
                            final Uri smsLaunchUri = Uri(
                              scheme: 'sms',
                              path: info.smsPhone!,
                              queryParameters: <String, String>{
                                'body': msgCtrl.text,
                              },
                            );
                            if (await canLaunchUrl(smsLaunchUri)) {
                               await launchUrl(smsLaunchUri);
                               sent = true;
                            }
                         }

                         if (sent) {
                            // Update info
                            info.mensagemPadrao = msgCtrl.text; // Save used message
                            await EventNotificationService().markBirthdayAsSent(item);
                            await _voiceService.speak("Mensagem enviada!");
                         } else {
                            await _voiceService.speak("Erro ao abrir aplicativo.");
                         }
                      }
                    ),
                 ],
               );
             }
           );
        }
      );
  }

  Future<void> _checkMedicines() async {
    final service = EventNotificationService();
    final meds = await service.getDueMedicines();
    
    if (meds.isEmpty) return;
    
    // Announce
    if (meds.length == 1) {
       await _voiceService.speak("Hora de tomar o remédio: ${meds.first.remedio!.nome}.");
    } else {
       await _voiceService.speak("Você tem ${meds.length} remédios para tomar agora.");
    }
    
    for (var item in meds) {
       if (!mounted) return;
       await _showMedicineDialog(item);
    }
  }

  Future<void> _showMedicineDialog(AgendaItem item) async {
     final info = item.remedio!;
     
     await showDialog(
       context: context,
       barrierDismissible: false,
       builder: (context) {
          return AlertDialog(
            title: Row(children: [
               const Icon(Icons.medication, color: Colors.redAccent),
               const SizedBox(width: 8),
               Expanded(child: Text("Hora do Remédio: ${info.nome}")),
            ]),
            content: Text("Dosagem: ${info.dosagem}\n\nVocê já tomou?"),
            actions: [
               TextButton(
                 child: const Text("Adiar"),
                 onPressed: () {
                    // Just close for now
                    Navigator.pop(context);
                 }
               ),
               ElevatedButton(
                 child: const Text("Já tomei"),
                 onPressed: () async {
                    Navigator.pop(context);
                    await EventNotificationService().markMedicineAsTaken(item);
                    await _voiceService.speak("Registrado. Próxima dose agendada.");
                 }
               )
            ],
          );
       }
     );
  }

  Future<void> _checkInstallmentNotifications() async {
    final service = TransactionNotificationService();
    final unpaid = await service.checkUnpaidInstallments();
    
    if (unpaid.isNotEmpty && mounted) {
      if (unpaid.length > 3) {
         await _voiceService.speak("Você tem ${unpaid.length} parcelas vencendo ou atrasadas. Verifique a lista.");
         return; 
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      for (var t in unpaid) {
        if (!mounted) return;
        
        final tDate = DateTime(t.date.year, t.date.month, t.date.day);
        String message;
        
        if (tDate.isAtSameMomentAs(tomorrow)) {
           message = "Lembrete: A parcela de ${t.description} vence amanhã. Valor: ${t.amount.toStringAsFixed(2)} reais.";
        } else if (tDate.isAtSameMomentAs(today)) {
           message = "Atenção: A parcela de ${t.description} vence hoje! Valor: ${t.amount.toStringAsFixed(2)} reais.";
        } else {
           final daysLate = today.difference(tDate).inDays;
           message = "A parcela de ${t.description} está atrasada há $daysLate dias.";
        }
        
        await _voiceService.speak(message);
        await Future.delayed(const Duration(seconds: 1));
        
        if (!mounted) return;
        
        final result = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Confirmar Pagamento'),
            content: Text('${t.description}\nValor: ${NumberFormat.simpleCurrency(locale: _currentLanguage).format(t.amount)}\nVencimento: ${DateFormat.yMd(_currentLanguage).format(t.date)}\n\nJá efetuou este pagamento?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Lembrar depois'),
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
