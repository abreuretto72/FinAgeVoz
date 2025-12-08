import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'models/transaction_model.dart';
import 'models/event_model.dart';
import 'models/category_model.dart';
import 'models/operation_history.dart';
import 'models/medicine_model.dart';
import 'services/database_service.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/sync/cloud_sync_service.dart';
import 'services/subscription/subscription_service.dart';
import 'utils/hive_setup.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print("DEBUG: runApp starting sequence");
  
  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(EventAdapter());
  Hive.registerAdapter(CategoryAdapter());
  Hive.registerAdapter(OperationHistoryAdapter());
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
  await initializeDateFormatting('pt_BR', null);
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

  print("DEBUG: calling runApp");
  runApp(const FinAgeVozApp());
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
          home: DatabaseService().getAppLockEnabled() 
              ? const AuthScreen() 
              : const HomeScreen(),
        );
      },
    );
  }
}
