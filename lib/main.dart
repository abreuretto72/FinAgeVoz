import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'models/transaction_model.dart';
import 'models/event_model.dart';
import 'models/category_model.dart';
import 'models/operation_history.dart';
import 'services/database_service.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/sync/cloud_sync_service.dart';
import 'services/subscription/subscription_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print("DEBUG: WidgetsFlutterBinding initialized");
  
  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(EventAdapter());
  Hive.registerAdapter(CategoryAdapter());
  Hive.registerAdapter(OperationHistoryAdapter());
  print("DEBUG: Hive initialized and adapters registered");
  
  // Initialize Database Service (opens boxes)
  final dbService = DatabaseService();
  print("DEBUG: Initializing DatabaseService...");
  await dbService.init();
  print("DEBUG: DatabaseService initialized");
  
  // Migrate old data from 2024 to 2025
  print("DEBUG: Migrating transactions...");
  await dbService.migrateTransactionsTo2025();
  print("DEBUG: Migrating events...");
  await dbService.migrateEventsTo2025();
  print("DEBUG: Migration complete");
  
  // Load Env
  await dotenv.load(fileName: ".env");
  print("DEBUG: Env loaded");
  
  // Initialize Date Formatting
  await initializeDateFormatting('pt_BR', null);
  print("DEBUG: Date formatting initialized");

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("DEBUG: Firebase initialized");
    
    // Initialize Sync Service
    await CloudSyncService().init();
    print("DEBUG: CloudSyncService initialized");

    // Initialize Subscription Service
    await SubscriptionService().init();
    print("DEBUG: SubscriptionService initialized");
  } catch (e) {
    print("WARNING: Firebase initialization failed: $e");
    // Continue app execution even if Firebase fails (offline mode)
  }

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
            Locale('pt', 'BR'),  // Português (Brasil)
            Locale('pt', 'PT'),  // Português (Portugal)
            Locale('en', ''),    // English
            Locale('es', ''),    // Español
            Locale('de', ''),    // Deutsch (Alemão)
            Locale('it', ''),    // Italiano
            Locale('fr', ''),    // Français
            Locale('ja', ''),    // 日本語 (Japonês)
            Locale('zh', ''),    // 中文 (Chinês)
            Locale('hi', ''),    // हिन्दी (Hindi/Indiano)
            Locale('ar', ''),    // العربية (Árabe)
            Locale('id', ''),    // Bahasa Indonesia
            Locale('ru', ''),    // Русский (Russo)
            Locale('bn', ''),    // বাংলা (Bengali)
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
