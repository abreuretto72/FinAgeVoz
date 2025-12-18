import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:io';
import 'dart:async';
import 'dart:ui';
import 'package:path_provider/path_provider.dart';
import 'l10n/app_localizations.dart';
import 'models/transaction_model.dart';
import 'models/event_model.dart';
import 'models/category_model.dart';

import 'models/medicine_model.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/sync/cloud_sync_service.dart';
import 'services/subscription/subscription_service.dart';
import 'utils/hive_setup.dart';

void main() async {
  // ═══════════════════════════════════════════════════════════════
  // 🛡️ GLOBAL ERROR BARRIER - Prevents Grey Screen of Death
  // ═══════════════════════════════════════════════════════════════
  
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // ═══════════════════════════════════════════════════════════════
    // STEP 1: Capture async errors (PlatformDispatcher)
    // ═══════════════════════════════════════════════════════════════
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('🔴 PLATFORM ERROR CAPTURED (Async Layer)');
      debugPrint('Error: $error');
      debugPrint('Stack: $stack');
      debugPrint('═══════════════════════════════════════════════════════');
      return true; // Handled - don't crash
    };
    
    // ═══════════════════════════════════════════════════════════════
    // STEP 2: Capture UI/Framework errors (FlutterError)
    // ═══════════════════════════════════════════════════════════════
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('🔴 FLUTTER ERROR CAPTURED (UI Layer)');
      debugPrint('Error: ${details.exception}');
      debugPrint('Stack: ${details.stack}');
      debugPrint('═══════════════════════════════════════════════════════');
      // Don't crash - just log it
    };
    
    // ═══════════════════════════════════════════════════════════════
    // STEP 3: Custom Error Widget - "Tela de Desculpas"
    // ═══════════════════════════════════════════════════════════════
    ErrorWidget.builder = (FlutterErrorDetails details) {
      // In debug mode, show the red error screen
      if (kDebugMode) {
        return ErrorWidget(details.exception);
      }
      
      // In release mode, show friendly error screen
      return MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF121212),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 80,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Ops, algo não saiu como esperado',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Não se preocupe, seus dados estão seguros.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Try to navigate to home
                      runApp(const FinAgeVozApp());
                    },
                    icon: const Icon(Icons.home),
                    label: const Text('Voltar para o Início'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E5FF),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    };
    
    print("DEBUG: runApp starting sequence");
  
  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(EventAdapter());
  Hive.registerAdapter(CategoryAdapter());

  Hive.registerAdapter(RemedioAdapter());
  Hive.registerAdapter(PosologiaAdapter());
  Hive.registerAdapter(HistoricoTomadaAdapter());
  
  // Initialize Agenda V2 Hive
  print("DEBUG: Initializing Agenda Hive...");
  try {
     await initAgendaHive().timeout(const Duration(seconds: 5));
     print("DEBUG: Agenda Hive initialized");
  } catch(e) {
     print("CRITICAL ERROR: Agenda Hive Init Failed: $e");
  }
  
  // Initialize Database Service (opens boxes)
  final dbService = DatabaseService();
  print("DEBUG: Initializing DatabaseService...");
  try {
    await dbService.init().timeout(const Duration(seconds: 5));
    print("DEBUG: DatabaseService initialized");
  } catch(e) {
    print("CRITICAL ERROR: DatabaseService Init Failed: $e");
  }
  
  // Migrate old data from 2024 to 2025
  try {
    print("DEBUG: Migrating transactions...");
    await dbService.migrateTransactionsTo2025();
    print("DEBUG: Migrating events...");
    await dbService.migrateEventsTo2025();
    print("DEBUG: Migration complete");
  } catch (e) {
    print("WARNING: Migration error: $e");
  }
  
  // Load Env
  try {
    await dotenv.load(fileName: ".env");
    print("DEBUG: Env loaded");
  } catch(e) { print("DEBUG: Env load failed: $e"); }
  
  // Initialize Date Formatting
  await initializeDateFormatting(null, null);
  print("DEBUG: Date formatting initialized");

  // Initialize External Services with Timeout Protection
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 5));
    print("DEBUG: Firebase initialized");
  } catch (e) {
    print("WARNING: Firebase initialization failed or timed out: $e");
  }

  try {
    await CloudSyncService().init().timeout(const Duration(seconds: 3));
    print("DEBUG: CloudSyncService initialized");
  } catch (e) {
    print("WARNING: CloudSyncService init failed: $e");
  }

  try {
    await SubscriptionService().init().timeout(const Duration(seconds: 3));
    print("DEBUG: SubscriptionService initialized");
  } catch (e) {
    print("WARNING: SubscriptionService init failed: $e");
  }

  try {
    await NotificationService().init();
    print("DEBUG: NotificationService initialized");
  } catch(e) {
    print("WARNING: NotificationService init failed: $e");
  }

  print("DEBUG: calling runApp");
  runApp(const FinAgeVozApp());
  
  }, (error, stack) {
    // Catch any errors that escape the main zone
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔴 ZONE ERROR CAPTURED (Main Zone)');
    debugPrint('Error: $error');
    debugPrint('Stack: $stack');
    debugPrint('═══════════════════════════════════════════════════════');
  });
}


class FinAgeVozApp extends StatelessWidget {
  const FinAgeVozApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: DatabaseService().languageNotifier,
      builder: (context, language, child) {
        return MaterialApp(
          title: 'FinAgeVoz',
          debugShowCheckedModeBanner: false,
          locale: Locale(language),
          supportedLocales: const [
            Locale('pt', 'BR'),
            Locale('pt', 'PT'),
            Locale('en', ''),
            Locale('es', ''),
            Locale('de', ''),
            Locale('it', ''),
            Locale('fr', ''),
            Locale('ja', ''),
            Locale('zh', ''),
            Locale('hi', ''),
            Locale('ar', ''),
            Locale('id', ''),
            Locale('ru', ''),
            Locale('bn', ''),
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF00E5FF), // Cyan Neon
              brightness: Brightness.dark,
              surface: const Color(0xFF121212),
            ),
            scaffoldBackgroundColor: const Color(0xFF121212),
            fontFamily: 'Roboto',
          ),
          // ✅ Usar SplashScreen para verificar privacidade
          home: const SplashScreen(),
        );
      },
    );
  }
}
