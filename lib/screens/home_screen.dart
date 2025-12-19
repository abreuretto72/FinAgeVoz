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
import 'dart:async';

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

import '../utils/localization.dart';
import '../utils/installment_helper.dart';
import '../utils/currency_formatter.dart';
import '../services/agenda_repository.dart';
import '../widgets/ai_disclaimer_banner.dart';
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


import '../services/query_service.dart';
import '../services/sync/cloud_sync_service.dart';
import '../services/talking_clock_service.dart';
import 'sync_settings_screen.dart';
import '../services/subscription/feature_gate.dart';
import '../services/subscription/subscription_service.dart';
import '../widgets/app_drawer.dart';
import 'import_export_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final VoiceService _voiceService = VoiceService();
  final AIService _aiService = AIService();
  final DatabaseService _dbService = DatabaseService();
  final AgendaRepository _agendaRepo = AgendaRepository();

  Timer? _checkTimer;
  DateTime? _lastBirthdayCheck;
  final Set<dynamic> _notifiedAgendaItems = {};

  final ImportService _importService = ImportService();
  late final VoiceController _voiceController;

  bool _isListening = false;
  bool _isProcessing = false;
  String _statusText = "";
  
  // State for multi-turn conversations (missing amount)
  bool _isWaitingForAmount = false;
  Map<String, dynamic>? _pendingTransactionData;
  Map<String, dynamic>? _pendingAgendaData; // State for missing agenda details (person_name)
  String? _missingField;
  
  
  String get _currentLanguage {
    final locale = Localizations.localeOf(context);
    // Normalizar o locale para o formato esperado
    if (locale.countryCode != null && locale.countryCode!.isNotEmpty) {
      return '${locale.languageCode}_${locale.countryCode}';
    }
    return locale.languageCode;
  }
  
  // Static flag to ensure events are announced only once per app session


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
    // Init Talking Clock
    TalkingClockService().init();
    
    _initVoice();
    _checkTimer = Timer.periodic(const Duration(minutes: 1), (_) => _checkTodayEvents());
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

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
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
      drawer: AppDrawer(
        navigate: _navigate,
        onImportExportTap: () => _navigate(const ImportExportScreen()),
        currentLanguage: _currentLanguage,
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
            
            // ⚠️ AI Disclaimer - Google Play Compliance
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: AIDisclaimerBanner(),
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

  // Slot Filling Check (New)
  if (_missingField != null && (_pendingTransactionData != null || _pendingAgendaData != null)) {
      await _handleMissingInput(text);
      return;
  }

  setState(() {
    _isProcessing = true;
    _statusText = t('status_processing');
  });

  try {
    final lowerText = text.toLowerCase();
    final cleanText = lowerText.replaceAll(RegExp(r'[!.,?]'), '').trim();

    // GREETING DETECTION (Priority check before AI)
    final greetings = ['bom dia', 'boa tarde', 'boa noite', 'olá', 'oi', 'hey'];
    if (greetings.any((g) => cleanText == g || cleanText.startsWith('$g '))) {
      await _handleGreeting(cleanText);
      setState(() {
        _isProcessing = false;
        _statusText = t('status_idle');
      });
      return;
    }

    // NEWS REQUEST DETECTION (Priority check before AI)
    final newsKeywords = ['notícias', 'noticias', 'manchetes', 'novidades', 'acontecendo'];
    if (newsKeywords.any((k) => cleanText.contains(k))) {
      await _handleNewsRequest();
      setState(() {
        _isProcessing = false;
        _statusText = t('status_idle');
      });
      return;
    }

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
        // await _voiceController.handleAgendaItem(result['agenda_item']);
        await _initiateAgendaItem(result['agenda_item']);
        return;
    } else if (intent == 'QUERY') {
        // Delegate AGENDA queries to controller for Search functionality
        final domain = result['query']?['domain'];
        if (domain == 'AGENDA') {
            await _voiceController.handleQuery(result['query']);
            return;
        }
        // Fall through for FINANCE queries to be handled by AI answer logic below
    } else if (intent == 'CHAT') {
        // Handle conversational/emotional responses
        final message = result['message'];
        if (message != null && message.isNotEmpty) {
            await _voiceService.speak(message);
        } else {
            await _voiceService.speak('Estou aqui para ajudar. Como posso te auxiliar?');
        }
        setState(() {
          _isProcessing = false;
          _statusText = t('status_idle');
        });
        return;
    } 

    if (intent == 'ADD_TRANSACTION') {
      await _initiateTransaction(result['transaction']);
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

  // SLOT FILLING LOGIC ----------------------------------------------------------------
  Future<void> _initiateTransaction(Map<String, dynamic>? data) async {
    if (data == null) return;
    
    // Normalize data structure for storage
    bool isExpense = true;
    if (data['type'] != null && data['type'] is String) {
       isExpense = (data['type'] as String).toUpperCase() == 'EXPENSE';
    } else if (data['isExpense'] != null && data['isExpense'] is bool) {
       isExpense = data['isExpense'];
    }
    data['isExpense'] = isExpense;

    _pendingTransactionData = data; // Store as pending
    
    await _validateAndFinalizeTransaction();
  }

  // AGENDA SLOT FILLING
  Future<void> _initiateAgendaItem(Map<String, dynamic>? data) async {
      if (data == null) return;
      _pendingAgendaData = data;
      await _validateAndFinalizeAgendaItem();
  }

  Future<void> _validateAndFinalizeAgendaItem() async {
      if (_pendingAgendaData == null) return;
      final data = _pendingAgendaData!;

      // Check if it's a meeting (COMPROMISSO)
      final typeStr = (data['type'] as String?)?.toUpperCase();
      final isCompromisso = typeStr == 'COMPROMISSO'; // Only enforce for Compromisso if needed? 
      // Rule 4: "Se o usuário disser 'Registrar uma reunião...'" -> Missing person
      
      // Check for explicit "missing_person" flag from AI
      bool missingPerson = data['missing_person'] == true;
      
      // Fallback: If title is exactly "Reunião" or "Encontro" or "Consulta" without "com"
      String title = (data['title'] as String?) ?? "";
      if (!title.toLowerCase().contains(" com ")) {
          // Check if it is a social event type
          if (['reunião', 'encontro', 'consulta', 'almoço', 'jantar', 'café'].contains(title.toLowerCase())) {
             missingPerson = true;
          }
      }

      if (missingPerson) {
          _missingField = 'person_name';
          setState(() { _statusText = "Com quem?"; });
          await _voiceService.speak("Com quem é essa reunião?");
          _startListeningAfterSpeech();
          return;
      }

      // All good
      _missingField = null;
      _pendingAgendaData = null;
      await _voiceController.handleAgendaItem(data);
  }

  Future<void> _validateAndFinalizeTransaction() async {
     if (_pendingTransactionData == null) return;
     final data = _pendingTransactionData!;
     
     // 1. Check Description (ITEM)
     if (data['description'] == null || (data['description'] as String).isEmpty) {
        _missingField = 'description';
        setState(() { _statusText = "Aguardando item..."; });
        await _voiceService.speak("Você não informou o que foi. Qual é o item ou descrição da transação?");
        _startListeningAfterSpeech();
        return;
     }
     
     // 2. Check Amount (VALOR)
     final amount = (data['amount'] as num?)?.toDouble();
     final installments = data['installments'] as int? ?? 1;
     final installmentAmount = (data['installmentAmount'] as num?)?.toDouble();

     // Rule: Simple transactions MUST have amount.
     // Installments MUST have Total OR (Down + Chunk).
     bool hasValidAmount = (amount != null && amount > 0);
     
     if (installments > 1) {
         // Case C: User provided explicit Installment Value (e.g. "5 parcelas de 100").
         // TRUST THIS. Ignore 'amount' (Total) calculation nuances.
         if (installmentAmount != null && installmentAmount > 0) {
             // We have enough info. Proceed.
         } else {
             // Case A/B: User provided Total and Count (and maybe Entry).
             // We need valid Total ('amount') to calculate splits.
             if (!hasValidAmount) {
                 _missingField = 'amount';
                 setState(() { _statusText = "Aguardando valor..."; });
                 await _voiceService.speak("Você não informou o valor total ou das parcelas. Qual o valor?");
                 _startListeningAfterSpeech();
                 return; 
             }
             
             // Sanity Check
             final downPayment = (data['downPayment'] as num?)?.toDouble() ?? 0.0;
             if (amount! <= downPayment) {
                  _missingField = 'amount';
                  setState(() { _statusText = "Valor inconsistente"; });
                  await _voiceService.speak("O valor total é menor que a entrada. Por favor, diga o valor total da compra.");
                  _startListeningAfterSpeech();
                  return;
             }
         }
     } else {
         if (!hasValidAmount) {
             _missingField = 'amount';
             setState(() { _statusText = "Aguardando valor..."; });
             await _voiceService.speak("Você não informou o valor. Qual o valor da transação?");
             _startListeningAfterSpeech();
             return;
         }
     }

     // All good!
     _missingField = null;
     _pendingTransactionData = null; // Clear state
     await _finalizeTransaction(data);
  }

  Future<void> _handleMissingInput(String text) async {
     // Transaction Logic
     if (_pendingTransactionData != null) {
         await _handleMissingTransactionInput(text);
         return;
     }

     // Agenda Logic
     if (_pendingAgendaData != null && _missingField == 'person_name') {
         // Update title
         String name = text.trim();
         // Capitalize
         if (name.isNotEmpty) name = name[0].toUpperCase() + name.substring(1);
         
         // If user says "Com João", remove "Com "
         if (name.toLowerCase().startsWith("com ")) {
             name = name.substring(4).trim();
              if (name.isNotEmpty) name = name[0].toUpperCase() + name.substring(1);
         }

         // Construct title
         String currentTitle = _pendingAgendaData!['title'] ?? 'Reunião';
         
         // If generic "Reunião" or "Encontro", strip it if needed, or just append
         // Actually, let's just append "com $name" to the type if the current title is generic
         // Or just ensure the Format "Title com Person".
         
         if (!currentTitle.toLowerCase().contains("com ")) {
            _pendingAgendaData!['title'] = "$currentTitle com $name";
         } else {
             // Already has "com", maybe replaced placeholder?
             _pendingAgendaData!['title'] = "$currentTitle $name";
         }
         
         // Update description for context
         String currentDesc = _pendingAgendaData!['description'] ?? '';
         _pendingAgendaData!['description'] = "$currentDesc (com $name)".trim();

         _pendingAgendaData!['missing_person'] = false; // clear flag
         
         _missingField = null;
         final data = _pendingAgendaData;
         _pendingAgendaData = null;
         
         await _voiceController.handleAgendaItem(data);
         return;
     }
  }

  Future<void> _handleMissingTransactionInput(String text) async {
     if (_pendingTransactionData == null) return;
     
     bool handled = false;
     
     if (_missingField == 'description') {
         // User provided description directly
         _pendingTransactionData!['description'] = text.trim();
         handled = true;
     } else if (_missingField == 'amount') {
         // Extract number
         double? val;
         String clean = text.replaceAll(RegExp(r'[^\d.,]'), '').replaceAll(',', '.');
         try { val = double.parse(clean); } catch(_) {}
         
         if (val == null) {
            // Ask AI to extract amount from text
            final json = await _aiService.processCommand("O valor é $text");
             if (json['transaction'] != null) {
                val = (json['transaction']['amount'] as num?)?.toDouble();
             }
         }
         
         if (val != null && val > 0) {
            _pendingTransactionData!['amount'] = val;
            handled = true;
         } else {
            await _voiceService.speak("Não entendi o valor. Diga apenas o número, por exemplo, 50.");
            _startListeningAfterSpeech();
            return;
         }
     }
     
     if (handled) {
        await _validateAndFinalizeTransaction();
     }
  }

  void _startListeningAfterSpeech() {
     Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _voiceService.startListening();
     });
  }

  Future<void> _finalizeTransaction(Map<String, dynamic> data) async {
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
          for (final t in transactions) {
            await _dbService.addTransaction(t);
          }

          double totalFeedback = amount ?? 0.0;
          if (installmentAmount != null) {
            totalFeedback = downPayment + (installmentAmount * installments);
          } else if (amount != null) totalFeedback = amount;
          
          final installmentVal = installmentAmount ?? ((totalFeedback - downPayment) / installments);
          await _voiceService.speak(
            isExpense
                ? 'Compra de $description registrada. ${downPayment > 0 ? 'Entrada de ${CurrencyFormatter.format(context, downPayment)} e ' : ''}$installments parcelas de ${CurrencyFormatter.format(context, installmentVal)}.'
                : 'Receita de $description registrada. ${downPayment > 0 ? 'Entrada de ${CurrencyFormatter.format(context, downPayment)} e ' : ''}$installments parcelas de ${CurrencyFormatter.format(context, installmentVal)}.',
          );
        } else {
          final now = DateTime.now();
          final isTodayOrPast = date.isBefore(now) || 
                               (date.year == now.year && date.month == now.month && date.day == now.day);
          
          bool finalIsPaid = isTodayOrPast;
          if (data['isPaid'] != null) {
             bool aiSaysPaid = data['isPaid'];
             if (!aiSaysPaid && isTodayOrPast) {
                 final descLower = description.toLowerCase();
                 final obligationKeywords = ['boleto', 'conta', 'fatura', 'aluguel', 'condominio', 'pagar', 'vence', 'cartão', 'ipva', 'iptu', 'darf', 'agendar'];
                 bool isObligation = obligationKeywords.any((k) => descLower.contains(k));
                 if (isObligation) finalIsPaid = false; 
                 else finalIsPaid = true;
             } else {
                 finalIsPaid = aiSaysPaid;
             }
          }

          final transaction = Transaction(
            id: const Uuid().v4(),
            description: description,
            amount: amount ?? 0.0,
            isExpense: isExpense,
            date: date,
            category: category,
            subcategory: subcategory,
            isPaid: finalIsPaid,
            paymentDate: finalIsPaid ? date : null,
          );
          await _dbService.addTransaction(transaction);

          // Force update UI state if needed
          setState(() { _statusText = t('status_idle'); _isProcessing = false; });

          await _voiceService.speak(
            isExpense
                ? 'Gasto de $description de ${CurrencyFormatter.format(context, amount!)} registrado como ${finalIsPaid ? "PAGO" : "PENDENTE"}.'
                : 'Receita de $description de ${CurrencyFormatter.format(context, amount!)} registrada como ${finalIsPaid ? "RECEBIDO" : "PENDENTE"}.',
          );
        }
  }

  Future<void> _verifyGroqModel() async {
    await _aiService.verifyAndUpdateModel();
  }

  Future<void> _checkTodayEvents() async {
    // 1. Calendar Events (Google/System)
    final notificationService = EventNotificationService();
    await notificationService.checkAndNotifyTodayEvents();
    
    // 2. Agenda Items (Internal)
    await _checkAgendaItems();
    
    // 3. Medicines
    await _checkMedicines();

    // 4. Birthdays (Once per day)
    final now = DateTime.now();
    if (_lastBirthdayCheck == null || _lastBirthdayCheck!.day != now.day) {
         await _checkBirthdays();
         _lastBirthdayCheck = now;
    }
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

      String initialText = info.mensagemPadrao ?? "Parabéns ${info.nomePessoa}! Tudo de bom!";
      if (!initialText.contains("FinAgeVoz")) {
         initialText = "🎂 Enviado pelo app FinAgeVoz: " + initialText;
      }
      final msgCtrl = TextEditingController(text: initialText);

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
                                    msgCtrl.text = "🎂 Enviado pelo app FinAgeVoz: " + newMsg.replaceAll('"', ''); 
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

  Future<void> _checkAgendaItems() async {
     if (!mounted) return;
     final now = DateTime.now();
     
     // Include ALL agenda types
     final items = _agendaRepo.getAll().where((i) => 
        !i.status.toString().contains('CONCLUIDO')
     ).toList();

     for (var item in items) {
        if (item.dataInicio == null) continue;
        final d = item.dataInicio!;
        if (d.year != now.year || d.month != now.month || d.day != now.day) continue;
        
        DateTime time;
        if (item.horarioInicio != null && item.horarioInicio!.contains(':')) {
          try {
            final parts = item.horarioInicio!.split(':');
            time = DateTime(d.year, d.month, d.day, int.parse(parts[0]), int.parse(parts[1]));
          } catch (_) {
            continue;
          }
        } else if (item.tipo == AgendaItemType.ANIVERSARIO) {
          // Birthdays use 9:00 AM as default
          time = DateTime(d.year, d.month, d.day, 9, 0);
        } else {
          continue;
        }
        
        final diff = time.difference(now).inMinutes;

        int reminderMins = 15;
        if (item.tipo == AgendaItemType.COMPROMISSO || item.tipo == AgendaItemType.TAREFA) {
             reminderMins = item.avisoMinutosAntes ?? DatabaseService().getDefaultAgendaReminderMinutes();
        } else if (item.tipo == AgendaItemType.REMEDIO) {
             reminderMins = item.avisoMinutosAntes ?? DatabaseService().getDefaultMedicineReminderMinutes();
        } else if (item.tipo == AgendaItemType.PAGAMENTO) {
             reminderMins = item.avisoMinutosAntes ?? DatabaseService().getDefaultPaymentReminderMinutes();
        } else if (item.tipo == AgendaItemType.ANIVERSARIO) {
             reminderMins = 0; // Birthday alerts at the time
        }
        
        // Notify if within configurable range
        if (diff >= -1 && diff <= reminderMins && !_notifiedAgendaItems.contains(item.key)) {
            String message;
            
            switch (item.tipo) {
              case AgendaItemType.ANIVERSARIO:
                message = "Hoje é aniversário de ${item.titulo}! Não esqueça de parabenizar!";
                break;
              
              case AgendaItemType.REMEDIO:
                if (item.remedio != null) {
                  message = "Lembrete de remédio: ${item.remedio!.nome}, dosagem ${item.remedio!.dosagem}";
                } else {
                  message = "Lembrete de remédio: ${item.titulo}";
                }
                break;
              
              case AgendaItemType.PAGAMENTO:
                if (item.pagamento != null) {
                  message = "Lembrete de pagamento: ${item.titulo}, valor ${CurrencyFormatter.format(context, item.pagamento!.valor)}";
                } else {
                  message = "Lembrete de pagamento: ${item.titulo}";
                }
                break;
              
              case AgendaItemType.COMPROMISSO:
              case AgendaItemType.TAREFA:
              case AgendaItemType.LEMBRETE:
              case AgendaItemType.PROJETO:
              case AgendaItemType.PRAZO:
                if (diff > 0) {
                  message = "Lembrete: ${item.titulo} em $diff minutos.";
                } else {
                  message = "Lembrete: ${item.titulo} agora!";
                }
                break;
              
              default:
                message = "Lembrete: ${item.titulo}";
            }
            
            await _voiceService.speak(message);
            _notifiedAgendaItems.add(item.key);
        }
     }
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
           message = "Lembrete: A parcela de ${t.description} vence amanhã. Valor: ${CurrencyFormatter.format(context, t.amount)}.";
        } else if (tDate.isAtSameMomentAs(today)) {
           message = "Atenção: A parcela de ${t.description} vence hoje! Valor: ${CurrencyFormatter.format(context, t.amount)}.";
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

  Future<void> _handleNewsRequest() async {
    String response = "Aqui estão as principais manchetes de hoje: ";
    
    // Simulated news (since we don't have real-time internet)
    final newsItems = [
      "Mercado financeiro apresenta estabilidade com leve alta no índice Bovespa.",
      "Novas tecnologias em inteligência artificial prometem revolucionar o setor de saúde.",
      "Economia global mostra sinais de recuperação segundo relatório do FMI.",
      "Investimentos em energias renováveis batem recorde histórico.",
    ];
    
    // Pick 2-3 random news items
    final selectedNews = <String>[];
    final seed = DateTime.now().millisecondsSinceEpoch;
    var rng = seed;
    
    while (selectedNews.length < 3 && selectedNews.length < newsItems.length) {
      rng = (rng * 1103515245 + 12345) & 0x7fffffff;
      final index = rng % newsItems.length;
      final news = newsItems[index];
      if (!selectedNews.contains(news)) {
        selectedNews.add(news);
      }
    }
    
    for (int i = 0; i < selectedNews.length; i++) {
      response += "${i + 1}. ${selectedNews[i]} ";
    }
    
    // Add team news if user has a favorite team
    final favoriteTeam = _dbService.getUserFavoriteTeam();
    if (favoriteTeam != null && favoriteTeam.isNotEmpty) {
      response += "E sobre o $favoriteTeam: ";
      
      // Simulated tournament standings
      rng = (rng * 1103515245 + 12345) & 0x7fffffff;
      final position = (rng % 10) + 1; // Position 1-10
      final points = 45 - (position * 3); // Points decrease with position
      
      final tournaments = ["Brasileirão", "Copa do Brasil", "Libertadores", "Campeonato Estadual"];
      rng = (rng * 1103515245 + 12345) & 0x7fffffff;
      final tournamentIndex = rng % tournaments.length;
      final tournament = tournaments[tournamentIndex];
      
      response += "O time está na ${position}ª posição do $tournament com $points pontos. ";
      
      // Simulated recent match result
      final opponents = ["Palmeiras", "Corinthians", "São Paulo", "Santos", "Internacional", "Grêmio", "Atlético-MG", "Fluminense"];
      rng = (rng * 1103515245 + 12345) & 0x7fffffff;
      final opponentIndex = rng % opponents.length;
      final opponent = opponents[opponentIndex];
      
      rng = (rng * 1103515245 + 12345) & 0x7fffffff;
      final resultType = rng % 3; // 0=win, 1=draw, 2=loss
      
      int teamGoals;
      int opponentGoals;
      
      if (resultType == 0) {
        // Win: team scored more
        rng = (rng * 1103515245 + 12345) & 0x7fffffff;
        teamGoals = (rng % 3) + 1; // 1-3 goals
        rng = (rng * 1103515245 + 12345) & 0x7fffffff;
        opponentGoals = rng % teamGoals; // 0 to (teamGoals-1)
        response += "Na última rodada, venceu o $opponent por $teamGoals a $opponentGoals. ";
      } else if (resultType == 1) {
        // Draw: same score
        rng = (rng * 1103515245 + 12345) & 0x7fffffff;
        teamGoals = rng % 4; // 0-3 goals
        opponentGoals = teamGoals;
        response += "Na última rodada, empatou com o $opponent em $teamGoals a $teamGoals. ";
      } else {
        // Loss: opponent scored more
        rng = (rng * 1103515245 + 12345) & 0x7fffffff;
        opponentGoals = (rng % 3) + 1; // 1-3 goals
        rng = (rng * 1103515245 + 12345) & 0x7fffffff;
        teamGoals = rng % opponentGoals; // 0 to (opponentGoals-1)
        response += "Na última rodada, perdeu para o $opponent por $opponentGoals a $teamGoals. ";
      }
      
      // Add one general news item
      final teamNewsOptions = [
        "O elenco se prepara para o próximo confronto com foco total.",
        "A diretoria trabalha em reforços para a próxima janela de transferências.",
        "Torcida organizada planeja grande festa para o próximo jogo em casa.",
        "Comissão técnica analisa adversários e define estratégia.",
      ];
      
      rng = (rng * 1103515245 + 12345) & 0x7fffffff;
      final teamNewsIndex = rng % teamNewsOptions.length;
      response += teamNewsOptions[teamNewsIndex] + " ";
    }
    
    // Add stock market highlights
    response += "No mercado de ações: ";
    
    // Simulated Bovespa index (random variation between -2% and +2%)
    rng = (rng * 1103515245 + 12345) & 0x7fffffff;
    final bovespaVariation = ((rng % 400) - 200) / 100.0; // -2.00 to +2.00
    final bovespaPoints = 120000 + (bovespaVariation * 1000).toInt(); // ~120k points
    
    if (bovespaVariation >= 0) {
      response += "O índice Bovespa fechou em alta de ${bovespaVariation.toStringAsFixed(2)}%, aos ${bovespaPoints} pontos. ";
    } else {
      response += "O índice Bovespa fechou em queda de ${bovespaVariation.abs().toStringAsFixed(2)}%, aos ${bovespaPoints} pontos. ";
    }
    
    // Simulated stock data (top gainers and losers)
    final stockGainers = [
      "Petrobras subiu 3,5%",
      "Vale teve alta de 2,8%",
      "Itaú avançou 2,1%",
      "Ambev registrou ganho de 1,9%",
      "Magazine Luiza subiu 4,2%",
    ];
    
    final stockLosers = [
      "Eletrobras caiu 2,3%",
      "Gol recuou 1,8%",
      "Azul teve queda de 2,1%",
      "CVC perdeu 1,5%",
      "Lojas Americanas caiu 3,1%",
    ];
    
    // Pick one gainer and one loser
    rng = (rng * 1103515245 + 12345) & 0x7fffffff;
    final gainerIndex = rng % stockGainers.length;
    rng = (rng * 1103515245 + 12345) & 0x7fffffff;
    final loserIndex = rng % stockLosers.length;
    
    response += "Entre as maiores altas, ${stockGainers[gainerIndex]}. ";
    response += "Já entre as baixas, ${stockLosers[loserIndex]}. ";
    
    response += "Essas são as principais notícias do momento.";
    await _voiceService.speak(response);
  }

  Future<void> _handleGreeting(String greeting) async {
    final userName = _dbService.getUserName();
    final nameGreeting = userName != null ? ", $userName" : "";
    
    String response = "";
    if (greeting.contains('bom dia')) response = "Bom dia$nameGreeting! ";
    else if (greeting.contains('boa tarde')) response = "Boa tarde$nameGreeting! ";
    else if (greeting.contains('boa noite')) response = "Boa noite$nameGreeting! ";
    else response = "Olá$nameGreeting! ";
    
    final briefingEnabled = _dbService.getAiMorningBriefingEnabled();
    if (briefingEnabled && greeting.contains('bom dia')) {
      // Build Cultural Almanac using AI
      final now = DateTime.now();
      final dayOfMonth = now.day;
      final monthName = _getMonthName(now.month);
      
      // Build dynamic prompt based on user preferences
      String almanacPrompt = "Hoje é dia $dayOfMonth de $monthName. O usuário deseja um briefing cultural rápido. ";
      
      List<String> topics = [];
      
      if (_dbService.getAiIncludeHistory()) {
        topics.add("Fatos Históricos: Cite 1 ou 2 eventos interessantes que ocorreram nesta data (foco em Ciência, Cultura ou Inovação). Evite política polêmica ou tragédias.");
      }
      
      if (_dbService.getAiIncludeReligious()) {
        topics.add("Santo do Dia: Identifique o principal Santo Católico celebrado hoje e, em meia frase, diga do que ele é padroeiro.");
      }
      
      if (_dbService.getAiIncludeCommemorative()) {
        topics.add("Efemérides: Cite qual profissão ou causa é celebrada hoje (foco no calendário do Brasil e Portugal).");
      }
      
      if (topics.isNotEmpty) {
        almanacPrompt += "Inclua os seguintes tópicos na sua resposta:\n";
        for (var topic in topics) {
          almanacPrompt += "- $topic\n";
        }
        almanacPrompt += "\nDiretriz de Estilo: Não faça listas com bullet points. Escreva um texto corrido, narrativo e natural, como um apresentador de rádio. ";
        almanacPrompt += "Se você não tiver certeza absoluta sobre um fato histórico ou santo específico para esta data, não invente. Pule esse tópico e vá para o próximo. ";
        almanacPrompt += "Mantenha a resposta curta (máximo 3 frases).";
        
        // Call AI to generate almanac
        try {
          final almanacResponse = await _aiService.answerQuestion(almanacPrompt);
          response += almanacResponse + " ";
        } catch (e) {
          print("Error generating almanac: $e");
          // Fallback to simple greeting
          response += "Espero que tenha descansado bem. ";
        }
      } else {
        response += "Espero que tenha descansado bem. ";
      }
      
      // Add weather if enabled
      if (_dbService.getAiIncludeWeather()) {
        response += "A previsão para hoje é de sol com algumas nuvens. ";
      }
      
      // Add horoscope if enabled
      if (_dbService.getAiIncludeHoroscope()) {
        final birthDate = _dbService.getUserBirthDate();
        if (birthDate != null) {
          final sign = _getZodiacSign(birthDate);
          final luckyNumbers = _generateLuckyNumbers();
          response += "Para $sign, o dia promete oportunidades. Seus números da sorte: $luckyNumbers. ";
        }
      }
    } else {
      response += "Como posso ajudar?";
    }
    await _voiceService.speak(response);
  }

  String _getMonthName(int month) {
    const months = ['Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho', 
                    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'];
    return months[month - 1];
  }

  String _getZodiacSign(DateTime d) {
    int day = d.day, month = d.month;
    if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) return "Áries";
    if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) return "Touro";
    if ((month == 5 && day >= 21) || (month == 6 && day <= 20)) return "Gêmeos";
    if ((month == 6 && day >= 21) || (month == 7 && day <= 22)) return "Câncer";
    if ((month == 7 && day >= 23) || (month == 8 && day <= 22)) return "Leão";
    if ((month == 8 && day >= 23) || (month == 9 && day <= 22)) return "Virgem";
    if ((month == 9 && day >= 23) || (month == 10 && day <= 22)) return "Libra";
    if ((month == 10 && day >= 23) || (month == 11 && day <= 21)) return "Escorpião";
    if ((month == 11 && day >= 22) || (month == 12 && day <= 21)) return "Sagitário";
    if ((month == 12 && day >= 22) || (month == 1 && day <= 19)) return "Capricórnio";
    if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) return "Aquário";
    return "Peixes";
  }

  String _generateLuckyNumbers() {
    final numbers = <int>{};
    var seed = DateTime.now().millisecondsSinceEpoch;
    while (numbers.length < 6) {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      numbers.add((seed % 60) + 1);
    }
    final sorted = numbers.toList()..sort();
    return sorted.map((n) => n.toString().padLeft(2, '0')).join(', ');
  }
}
