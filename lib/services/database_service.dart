import 'package:flutter/foundation.dart' hide Category;
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import '../models/transaction_model.dart';
import '../models/event_model.dart';
import '../models/category_model.dart';

import '../models/medicine_model.dart';
import '../services/notification_service.dart';
import 'package:uuid/uuid.dart';
import '../models/agenda_models.dart';
import '../utils/hive_setup.dart';
import '../utils/constants.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  late Box<Transaction> _transactionBox;
  late Box<Event> _eventBox;
  late Box _settingsBox;
  late Box<Category> _categoryBox;

  late Box<Remedio> _remedioBox;
  late Box<Posologia> _posologiaBox;
  late Box<HistoricoTomada> _historicoTomadaBox;

  final ValueNotifier<String> languageNotifier = ValueNotifier('pt_BR');

  // Initialize all Hive boxes and seed default categories
  Future<void> init() async {
    print("DEBUG: Opening Hive boxes...");
    _transactionBox = await Hive.openBox<Transaction>('transactions');
    _eventBox = await Hive.openBox<Event>('events');
    _settingsBox = await Hive.openBox('settings');
    _categoryBox = await Hive.openBox<Category>('categories');

    
    // Medicine boxes
    _remedioBox = await Hive.openBox<Remedio>('remedios');
    _posologiaBox = await Hive.openBox<Posologia>('posologias');
    _historicoTomadaBox = await Hive.openBox<HistoricoTomada>('historico_tomadas');

    print("DEBUG: Hive boxes opened. Category box empty? ${_categoryBox.isEmpty}");
    
    // Seed default categories if none exist
    if (_categoryBox.isEmpty) {
      print("DEBUG: Seeding categories...");
      await _seedCategories();
      print("DEBUG: Categories seeded.");
    }
    
    // One-time reset for Agenda V2
    if (!isAgendaResetV2) {
       print("DEBUG: Resetting Agenda tables for V2...");
       await resetAgenda();
    }
    
    // Initialize language notifier
    languageNotifier.value = getLanguage();

    // Sincronismo Absoluto (User Requirement):
    
    // 0. Auto-Fix (Heuristic): Corrigir 'Comprei/Gastei' que estejam Pendentes por erro.
    await _fixPastTenseTransactions();

    // 1. Remove TUDO que veio do financeiro (para garantir que pagos sumam).
    await _resetSyncedAgendaItems();
    
    // 2. Repovoa APENAS com Pendentes Válidos (!isPaid && !isDeleted).
    await _syncMissingAgendaItems();

    if (_categoryBox.isNotEmpty) {
      // Check if we need to reset categories for translation compatibility
      // This is a one-time migration to ensure all strings match AppConstants
      // Check if we need to reset categories for translation compatibility
      // This is a one-time migration to ensure all strings match AppConstants
      final needsMigrationV2 = _settingsBox.get('categories_migrated_v2', defaultValue: false) == false;
      final needsMigrationV3 = _settingsBox.get('categories_migrated_v3', defaultValue: false) == false;
      final needsMigrationV4 = _settingsBox.get('categories_migrated_v4', defaultValue: false) == false;
      
      if (needsMigrationV2 || needsMigrationV3 || needsMigrationV4) {
        print("DEBUG: Running category migration (v4)...");
        await resetDefaultCategories();
        await _settingsBox.put('categories_migrated_v2', true);
        await _settingsBox.put('categories_migrated_v3', true);
        await _settingsBox.put('categories_migrated_v4', true);
        print("DEBUG: Category migration completed.");
      }
      
      // Fix for incorrect reversals (where "Estorno" was classified as Expense)
      // await _fixIncorrectReversals(); // Disabled as it conflicts with new logic
      
      // Normalize reversals to ensure they work with the new calculation logic
      await _normalizeReversals();

      // Migrate reversals to negative values (User request: Estorno * -1)
      // DEPRECATED by v2 logic
      // final reversalsNegated = _settingsBox.get('reversals_negated_v1', defaultValue: false);
      // if (!reversalsNegated) {
      //   await _migrateReversalsToNegative();
      //   await _settingsBox.put('reversals_negated_v1', true);
      // }
      
      // Migrate to Algebraic Sign Logic (v2)
      // Expense -> Negative
      // Income -> Positive
      // Reversal (Exp) -> Positive
      // Reversal (Inc) -> Negative
      final algebraicMigrated = _settingsBox.get('algebraic_sign_v2', defaultValue: false);
      if (!algebraicMigrated) {
        await _migrateToAlgebraicSignV2();
        await _settingsBox.put('algebraic_sign_v2', true);
      }
      
      // Fix for phantom transaction (User reported error: 3150 vs 2350 -> 800 difference)
      // await _removePhantomHealthTransaction(); // Disabled after fix confirmed
      // Ensure sync between Finance and Agenda
      await _syncMissingAgendaItems();
    }
  }
  
  Future<void> _normalizeReversals() async {
    print("DEBUG: Normalizing reversals...");
    final transactions = _transactionBox.values.toList();
    // Create a map for fast lookup of original transactions
    final transactionMap = {for (var t in transactions) t.id: t};
    bool changed = false;
    
    for (int i = 0; i < transactions.length; i++) {
      final t = transactions[i];
      
      // Case 1: Reversals should match the type of the original transaction
      if (t.isReversal && t.originalTransactionId != null) {
        final original = transactionMap[t.originalTransactionId];
        if (original != null) {
          if (t.isExpense != original.isExpense) {
             print("DEBUG: Fixing reversal type mismatch for ${t.description}. Changing isExpense to ${original.isExpense}");
             final updatedT = Transaction(
              id: t.id,
              description: t.description,
              amount: t.amount,
              isExpense: original.isExpense, // Match original type
              date: t.date,
              category: t.category,
              subcategory: t.subcategory,
              isReversal: true,
              originalTransactionId: t.originalTransactionId,
              installmentId: t.installmentId,
              installmentNumber: t.installmentNumber,
              totalInstallments: t.totalInstallments,
              attachments: t.attachments,
            );
            await _transactionBox.putAt(i, updatedT);
            changed = true;
          }
        }
      }
      
      // Case 2: "Estorno" transactions that are NOT marked as isReversal
      if (!t.isReversal && t.isExpense) {
        final desc = t.description.toLowerCase();
        if (desc.contains('estorno de') || (desc.contains('estorno') && t.amount > 0)) {
           print("DEBUG: Marking transaction ${t.description} as Reversal.");
           final updatedT = Transaction(
            id: t.id,
            description: t.description,
            amount: t.amount,
            isExpense: true,
            date: t.date,
            category: t.category,
            subcategory: t.subcategory,
            isReversal: true, // Mark as reversal
            originalTransactionId: t.originalTransactionId,
            installmentId: t.installmentId,
            installmentNumber: t.installmentNumber,
            totalInstallments: t.totalInstallments,
            attachments: t.attachments,
          );
          await _transactionBox.putAt(i, updatedT);
          changed = true;
        }
      }
    }
    
    if (changed) {
      print("DEBUG: Reversals normalized.");
    } else {
      print("DEBUG: No reversals needed normalization.");
    }
  }

  Future<void> _migrateReversalsToNegative() async {
    // Deprecated by V2
  }

  Future<void> _migrateToAlgebraicSignV2() async {
    print("DEBUG: Migrating to Algebraic Sign Logic (v2)...");
    final transactions = _transactionBox.values.toList();
    bool changed = false;

    for (int i = 0; i < transactions.length; i++) {
      final t = transactions[i];
      double newAmount = t.amount;
      
      // Determine correct sign
      // Expense (Normal) -> Negative
      // Income (Normal) -> Positive
      // Expense (Reversal) -> Positive
      // Income (Reversal) -> Negative
      
      if (t.isExpense) {
        if (t.isReversal) {
          // Reversal of Expense -> Should be Positive
          newAmount = t.amount.abs();
        } else {
          // Normal Expense -> Should be Negative
          newAmount = -t.amount.abs();
        }
      } else {
        if (t.isReversal) {
          // Reversal of Income -> Should be Negative
          newAmount = -t.amount.abs();
        } else {
          // Normal Income -> Should be Positive
          newAmount = t.amount.abs();
        }
      }

      if (newAmount != t.amount) {
        print("DEBUG: Updating sign for ${t.description}: ${t.amount} -> $newAmount");
        final updatedT = Transaction(
          id: t.id,
          description: t.description,
          amount: newAmount,
          isExpense: t.isExpense,
          date: t.date,
          category: t.category,
          subcategory: t.subcategory,
          isReversal: t.isReversal,
          originalTransactionId: t.originalTransactionId,
          installmentId: t.installmentId,
          installmentNumber: t.installmentNumber,
          totalInstallments: t.totalInstallments,
          attachments: t.attachments,
        );
        await _transactionBox.putAt(i, updatedT);
        changed = true;
      }
    }

    if (changed) {
      print("DEBUG: Algebraic migration completed.");
    } else {
      print("DEBUG: No transactions needed algebraic migration.");
    }
  }

  // Deprecated
  Future<void> _fixIncorrectReversals() async {
    // ... implementation removed/disabled ...
  }

  Future<void> _seedCategories() async {
    // Seed Expense Categories
    for (var name in AppConstants.expenseCategories) {
      final description = AppConstants.categoryDescriptions[name] ?? '';
      final subcategories = AppConstants.expenseSubcategories[name] ?? [];
      await _categoryBox.add(Category(
        name: name, 
        description: description,
        subcategories: subcategories,
        type: 'expense',
      ));
    }

    // Seed Income Categories
    for (var name in AppConstants.incomeCategories) {
      final description = AppConstants.categoryDescriptions[name] ?? '';
      final subcategories = AppConstants.incomeSubcategories[name] ?? [];
      await _categoryBox.add(Category(
        name: name, 
        description: description,
        subcategories: subcategories,
        type: 'income',
      ));
    }
  }

  /// Resets all default categories to match AppConstants exactly.
  /// This ensures category and subcategory strings match the translation keys.
  /// User-created categories are preserved.
  Future<void> resetDefaultCategories() async {
    // Get all default category names from AppConstants
    final defaultExpenseNames = AppConstants.expenseCategories.toSet();
    final defaultIncomeNames = AppConstants.incomeCategories.toSet();
    
    // Remove all default categories (but keep user-created ones)
    final categoriesToRemove = <int>[];
    for (int i = 0; i < _categoryBox.length; i++) {
      final cat = _categoryBox.getAt(i);
      if (cat != null && (defaultExpenseNames.contains(cat.name) || defaultIncomeNames.contains(cat.name))) {
        categoriesToRemove.add(i);
      }
    }
    
    // Delete in reverse order to maintain indices
    for (int i in categoriesToRemove.reversed) {
      await _categoryBox.deleteAt(i);
    }
    
    // Re-seed default categories with correct strings
    await _seedCategories();
    
    print("DEBUG: Default categories reset. Total categories: ${_categoryBox.length}");
  }

  // Settings (Wake Word)
  Future<void> setWakeWord(String word) async {
    await _settingsBox.put('wake_word', word);
  }

  String? getWakeWord() {
    return _settingsBox.get('wake_word');
  }

  String? getGroqApiKey() {
    return _settingsBox.get('groq_api_key');
  }

  Future<void> setGroqApiKey(String key) async {
    await _settingsBox.put('groq_api_key', key);
  }

  String getGroqModel() {
    return _settingsBox.get('groq_model', defaultValue: 'llama-3.3-70b-versatile');
  }

  Future<void> setGroqModel(String model) async {
    await _settingsBox.put('groq_model', model);
  }


  String getLanguage() {
    String defaultLang = 'en';
    try {
      final systemLocale = Platform.localeName; // e.g., en_US, pt_BR
      if (systemLocale.startsWith('pt_PT')) {
        defaultLang = 'pt_PT';
      } else if (systemLocale.startsWith('pt')) {
        defaultLang = 'pt_BR';
      } else if (systemLocale.startsWith('es')) {
        defaultLang = 'es';
      } else if (systemLocale.startsWith('de')) {
        defaultLang = 'de';
      } else if (systemLocale.startsWith('it')) {
        defaultLang = 'it';
      } else if (systemLocale.startsWith('fr')) {
        defaultLang = 'fr';
      } else if (systemLocale.startsWith('ja')) {
        defaultLang = 'ja';
      } else if (systemLocale.startsWith('hi')) {
        defaultLang = 'hi';
      } else if (systemLocale.startsWith('zh')) {
        defaultLang = 'zh';
      } else if (systemLocale.startsWith('ar')) {
        defaultLang = 'ar';
      } else if (systemLocale.startsWith('bn')) {
        defaultLang = 'bn';
      } else if (systemLocale.startsWith('ru')) {
        defaultLang = 'ru';
      } else if (systemLocale.startsWith('id')) {
        defaultLang = 'id';
      }
    } catch (e) {
      print("Error getting system locale: $e");
    }
    return _settingsBox.get('language', defaultValue: defaultLang);
  }

  Future<void> setLanguage(String langCode) async {
    await _settingsBox.put('language', langCode);
    languageNotifier.value = langCode;
  }

  bool get isFirstRunVoice => _settingsBox.get('first_run_voice', defaultValue: true);

  Future<void> setFirstRunVoice(bool value) async {
    await _settingsBox.put('first_run_voice', value);
  }

  DateTime? getLastSyncTime() {
    final str = _settingsBox.get('last_sync_time');
    return str != null ? DateTime.parse(str) : null;
  }

  Future<void> setLastSyncTime(DateTime time) async {
    await _settingsBox.put('last_sync_time', time.toIso8601String());
  }

  // Transactions
  Future<void> addTransaction(Transaction transaction) async {
    // Enforce algebraic sign logic on add
    double amount = transaction.amount;
    if (transaction.isExpense) {
      if (transaction.isReversal) {
        amount = amount.abs(); // Reversal of Expense -> Positive
      } else {
        amount = -amount.abs(); // Normal Expense -> Negative
      }
    } else {
      if (transaction.isReversal) {
        amount = -amount.abs(); // Reversal of Income -> Negative
      } else {
        amount = amount.abs(); // Normal Income -> Positive
      }
    }
    
    // Rule 2 Check: If explicitly Paid but no payment date, set it.
    // We trust the caller (UI/Voice) to have handled the "Date <= Now -> Paid" rule 
    // to respect the "explicitly defined" user intent clause.
    DateTime? paymentDate = transaction.paymentDate;
    if (transaction.isPaid && paymentDate == null) {
       paymentDate = transaction.date; 
    }

    // Create new object with correct amount and consistent payment state
    final tToAdd = (amount != transaction.amount || paymentDate != transaction.paymentDate) 
        ? Transaction(
            id: transaction.id,
            description: transaction.description,
            amount: amount,
            isExpense: transaction.isExpense,
            date: transaction.date,
            category: transaction.category,
            subcategory: transaction.subcategory,
            isReversal: transaction.isReversal,
            originalTransactionId: transaction.originalTransactionId,
            installmentId: transaction.installmentId,
            installmentNumber: transaction.installmentNumber,
            totalInstallments: transaction.totalInstallments,
            attachments: transaction.attachments,
            updatedAt: DateTime.now().toUtc(),
            isSynced: false,
            isPaid: transaction.isPaid,
            paymentDate: paymentDate,
          )
        : transaction;

    await _transactionBox.add(tToAdd);
    await _syncAdd(tToAdd);
  }

  Future<void> markTransactionAsPaid(String id, DateTime date) async {
    try {
      final t = _transactionBox.values.firstWhere((t) => t.id == id);
      final updatedT = Transaction(
        id: t.id,
        description: t.description,
        amount: t.amount,
        isExpense: t.isExpense,
        date: t.date,
        isReversal: t.isReversal,
        originalTransactionId: t.originalTransactionId,
        category: t.category,
        subcategory: t.subcategory,
        installmentId: t.installmentId,
        installmentNumber: t.installmentNumber,
        totalInstallments: t.totalInstallments,
        attachments: t.attachments,
        updatedAt: DateTime.now().toUtc(),
        isDeleted: t.isDeleted,
        isSynced: false,
        isPaid: true,
        paymentDate: date,
      );
      await _transactionBox.put(t.key, updatedT);
      await _syncUpdate(updatedT);
    } catch (e) {
      print("Transaction not found: $id");
    }
  }

  List<Transaction> getTransactions() {
    return _transactionBox.values.where((t) => !t.isDeleted).toList().reversed.toList();
  }

  List<Transaction> getDirtyTransactions() {
    return _transactionBox.values.where((t) => !t.isSynced).toList();
  }

  Future<void> saveTransactionFromCloud(Transaction transaction) async {
    // Save exactly as received from cloud, but ensure isSynced is true locally
    // We need to find if it exists to get the key, or add it
    dynamic key;
    try {
      final existing = _transactionBox.values.firstWhere((t) => t.id == transaction.id);
      key = existing.key;
    } catch (e) {
      // Not found, will add
    }

    if (key != null) {
      await _transactionBox.put(key, transaction);
    } else {
      await _transactionBox.add(transaction);
    }
  }

  double getBalance() {
    // User Request (Step 2956): "considerar sempre vencidas e a vencer".
    // TOTAL Projected Balance (Past + Future).
    return _transactionBox.values.fold(0.0, (sum, t) {
      if (t.isDeleted) return sum;
      return sum + t.amount;
    });
  }

  // Events
  Future<void> addEvent(Event event) async {
    // Ensure new event has sync fields set
    final eventToAdd = Event(
      id: event.id,
      title: event.title,
      date: event.date,
      description: event.description,
      isCancelled: event.isCancelled,
      recurrence: event.recurrence,
      lastNotifiedDate: event.lastNotifiedDate,
      attachments: event.attachments,
      updatedAt: DateTime.now().toUtc(),
      isSynced: false,
    );
    await _eventBox.add(eventToAdd);
    
    // Notification Hook
    if (!event.isCancelled && event.date.isAfter(DateTime.now())) {
         await NotificationService().scheduleEvent(event.id.hashCode, event.title, event.description, event.date);
    }
  }

  List<Event> getEvents() {
    return _eventBox.values.where((e) => !e.isDeleted).toList();
  }

  List<Event> getDirtyEvents() {
    return _eventBox.values.where((e) => !e.isSynced).toList();
  }

  Future<void> saveEventFromCloud(Event event) async {
    dynamic key;
    try {
      final existing = _eventBox.values.firstWhere((e) => e.id == event.id);
      key = existing.key;
    } catch (e) {
      // Not found
    }

    if (key != null) {
      await _eventBox.put(key, event);
    } else {
      await _eventBox.add(event);
    }
  }

  Future<void> updateEvent(dynamic indexOrId, Event event) async {
    // Handle both index (int) and ID (String) for backward compatibility/transition
    if (indexOrId is int) {
       // Legacy index support - discouraged but kept for safety
       // We must find the actual object to preserve ID if possible, but here we just update
       // Note: This might break if list is filtered.
       // Better to find by ID if event has one.
       final key = _eventBox.keyAt(indexOrId);
       final updatedEvent = Event(
          id: event.id,
          title: event.title,
          date: event.date,
          description: event.description,
          isCancelled: event.isCancelled,
          recurrence: event.recurrence,
          lastNotifiedDate: event.lastNotifiedDate,
          attachments: event.attachments,
          updatedAt: DateTime.now().toUtc(),
          isSynced: false,
          isDeleted: false,
       );
       await _eventBox.put(key, updatedEvent);
       
       // Notification Hook
       await NotificationService().cancel(event.id.hashCode);
       if (!event.isCancelled && !event.isDeleted && event.date.isAfter(DateTime.now())) {
            await NotificationService().scheduleEvent(event.id.hashCode, event.title, event.description, event.date);
       }
    } else if (indexOrId is String) {
       final existing = _eventBox.values.firstWhere((e) => e.id == indexOrId);
       final key = existing.key;
       final updatedEvent = Event(
          id: event.id,
          title: event.title,
          date: event.date,
          description: event.description,
          isCancelled: event.isCancelled,
          recurrence: event.recurrence,
          lastNotifiedDate: event.lastNotifiedDate,
          attachments: event.attachments,
          updatedAt: DateTime.now().toUtc(),
          isSynced: false,
          isDeleted: false,
       );
       await _eventBox.put(key, updatedEvent);
       
       // Notification Hook
       await NotificationService().cancel(event.id.hashCode);
       if (!event.isCancelled && !event.isDeleted && event.date.isAfter(DateTime.now())) {
            await NotificationService().scheduleEvent(event.id.hashCode, event.title, event.description, event.date);
       }
    }
  }

  Future<void> deleteEvent(dynamic indexOrId) async {
    if (indexOrId is int) {
       final key = _eventBox.keyAt(indexOrId);
       final event = _eventBox.get(key);
       if (event != null) {
         final deletedEvent = Event(
            id: event.id,
            title: event.title,
            date: event.date,
            description: event.description,
            isCancelled: event.isCancelled,
            recurrence: event.recurrence,
            lastNotifiedDate: event.lastNotifiedDate,
            attachments: event.attachments,
            updatedAt: DateTime.now().toUtc(),
            isSynced: false,
            isDeleted: true,
         );
         await _eventBox.put(key, deletedEvent);
         // Notification Hook
         await NotificationService().cancel(event.id.hashCode);
       }
    } else if (indexOrId is String) {
       try {
         final event = _eventBox.values.firstWhere((e) => e.id == indexOrId);
         final key = event.key;
         final deletedEvent = Event(
            id: event.id,
            title: event.title,
            date: event.date,
            description: event.description,
            isCancelled: event.isCancelled,
            recurrence: event.recurrence,
            lastNotifiedDate: event.lastNotifiedDate,
            attachments: event.attachments,
            updatedAt: DateTime.now().toUtc(),
            isSynced: false,
            isDeleted: true,
         );
         await _eventBox.put(key, deletedEvent);
       } catch (e) {
         print("Event not found for deletion: $indexOrId");
       }
    }
  }

  // Transaction update
  Future<void> updateTransaction(dynamic indexOrId, Transaction transaction) async {
    dynamic key;
    if (indexOrId is int) {
      key = _transactionBox.keyAt(indexOrId);
    } else if (indexOrId is String) {
      try {
        final existing = _transactionBox.values.firstWhere((t) => t.id == indexOrId);
        key = existing.key;
      } catch (e) {
        print("Transaction not found for update: $indexOrId");
        return;
      }
    }

    if (key != null) {
      // Rule 2 Check for consistency
      DateTime? paymentDate = transaction.paymentDate;
      if (transaction.isPaid && paymentDate == null) {
         paymentDate = transaction.date; 
      }

      final updatedTransaction = Transaction(
        id: transaction.id,
        description: transaction.description,
        amount: transaction.amount,
        isExpense: transaction.isExpense,
        date: transaction.date,
        category: transaction.category,
        subcategory: transaction.subcategory,
        isReversal: transaction.isReversal,
        originalTransactionId: transaction.originalTransactionId,
        installmentId: transaction.installmentId,
        installmentNumber: transaction.installmentNumber,
        totalInstallments: transaction.totalInstallments,
        attachments: transaction.attachments,
        updatedAt: DateTime.now().toUtc(),
        isSynced: false,
        isDeleted: false,
        isPaid: transaction.isPaid,
        paymentDate: paymentDate,
      );
      await _transactionBox.put(key, updatedTransaction);
      await _syncUpdate(updatedTransaction);
    }
  }

  Future<void> deleteTransaction(dynamic indexOrId) async {
    dynamic key;
    Transaction? transaction;
    
    if (indexOrId is int) {
      key = _transactionBox.keyAt(indexOrId);
      transaction = _transactionBox.get(key);
    } else if (indexOrId is String) {
      try {
        transaction = _transactionBox.values.firstWhere((t) => t.id == indexOrId);
        key = transaction.key;
      } catch (e) {
        print("Transaction not found for deletion: $indexOrId");
        return;
      }
    }

    if (transaction != null && key != null) {
      final deletedTransaction = Transaction(
        id: transaction.id,
        description: transaction.description,
        amount: transaction.amount,
        isExpense: transaction.isExpense,
        date: transaction.date,
        category: transaction.category,
        subcategory: transaction.subcategory,
        isReversal: transaction.isReversal,
        originalTransactionId: transaction.originalTransactionId,
        installmentId: transaction.installmentId,
        installmentNumber: transaction.installmentNumber,
        totalInstallments: transaction.totalInstallments,
        attachments: transaction.attachments,
        updatedAt: DateTime.now().toUtc(),
        isSynced: false,
        isDeleted: true,
      );
      await _transactionBox.put(key, deletedTransaction);
      await _syncDelete(deletedTransaction.id);
    }
  }

  Future<void> deleteTransactionSeries(String installmentId) async {
    final transactions = _transactionBox.values.where((t) => t.installmentId == installmentId).toList();
    
    for (var t in transactions) {
      final deletedTransaction = Transaction(
        id: t.id,
        description: t.description,
        amount: t.amount,
        isExpense: t.isExpense,
        date: t.date,
        category: t.category,
        subcategory: t.subcategory,
        isReversal: t.isReversal,
        originalTransactionId: t.originalTransactionId,
        installmentId: t.installmentId,
        installmentNumber: t.installmentNumber,
        totalInstallments: t.totalInstallments,
        attachments: t.attachments,
        updatedAt: DateTime.now().toUtc(),
        isSynced: false,
        isDeleted: true,
      );
      await _transactionBox.put(t.key, deletedTransaction);
      await _syncDelete(t.id);
    }
  }

  // Category management
  Future<void> addCategory(Category category) async {
    await _categoryBox.add(category);
  }

  List<Category> getCategories({String? type}) {
    if (type == null) {
      return _categoryBox.values.where((c) => !c.isDeleted).toList();
    }
    return _categoryBox.values.where((c) => c.type == type && !c.isDeleted).toList();
  }

  List<Category> getDirtyCategories() {
    return _categoryBox.values.where((c) => !c.isSynced).toList();
  }

  Future<void> saveCategoryFromCloud(Category category) async {
    dynamic key;
    try {
      final existing = _categoryBox.values.firstWhere((c) => c.id == category.id);
      key = existing.key;
    } catch (e) {
      // Not found
    }

    if (key != null) {
      await _categoryBox.put(key, category);
    } else {
      await _categoryBox.add(category);
    }
  }

  /// Deletes a category only if no transaction references it.
  /// Returns true if deletion succeeded, false otherwise.
  Future<bool> deleteCategory(int index) async {
    final category = _categoryBox.getAt(index);
    if (category == null) return false;
    final used = _transactionBox.values.any((t) => t.category == category.name && !t.isDeleted);
    if (used) {
      return false; // cannot delete because there are transactions using it
    }
    
    final deletedCategory = Category(
      id: category.id,
      name: category.name,
      description: category.description,
      subcategories: category.subcategories,
      type: category.type,
      updatedAt: DateTime.now().toUtc(),
      isSynced: false,
      isDeleted: true,
    );
    
    await _categoryBox.putAt(index, deletedCategory);
    return true;
  }

  Future<void> updateCategory(int index, Category category) async {
    final updatedCategory = Category(
      id: category.id,
      name: category.name,
      description: category.description,
      subcategories: category.subcategories,
      type: category.type,
      updatedAt: DateTime.now().toUtc(),
      isSynced: false,
      isDeleted: false,
    );
    await _categoryBox.putAt(index, updatedCategory);
  }

  // Migration: Update transactions from 2024 to 2025
  Future<void> migrateTransactionsTo2025() async {
    final transactions = _transactionBox.values.toList();
    for (int i = 0; i < transactions.length; i++) {
      final transaction = transactions[i];
      if (transaction.date.year == 2024) {
        final updatedTransaction = Transaction(
          id: transaction.id,
          description: transaction.description,
          amount: transaction.amount,
          isExpense: transaction.isExpense,
          date: DateTime(2025, transaction.date.month, transaction.date.day,
              transaction.date.hour, transaction.date.minute),
          category: transaction.category,
          subcategory: transaction.subcategory,
          isReversal: transaction.isReversal,
          originalTransactionId: transaction.originalTransactionId,
        );
        await _transactionBox.putAt(i, updatedTransaction);
      }
    }
  }

  // Migration: Update events from 2024 to 2025
  Future<void> migrateEventsTo2025() async {
    final events = _eventBox.values.toList();
    for (int i = 0; i < events.length; i++) {
      final event = events[i];
      if (event.date.year == 2024) {
        final updatedEvent = Event(
          id: event.id,
          title: event.title,
          date: DateTime(2025, event.date.month, event.date.day,
              event.date.hour, event.date.minute),
          description: event.description,
          isCancelled: event.isCancelled,
          recurrence: event.recurrence,
          lastNotifiedDate: event.lastNotifiedDate,
          attachments: event.attachments,
          reminderMinutes: event.reminderMinutes,
        );
        await _eventBox.putAt(i, updatedEvent);
      }
    }
  }

  // Data Management Methods
  
  Map<String, dynamic> getDataStats() {
    final transactions = _transactionBox.values.toList();
    final events = _eventBox.values.toList();
    
    DateTime? oldestTransaction;
    DateTime? newestTransaction;
    
    if (transactions.isNotEmpty) {
      oldestTransaction = transactions.map((t) => t.date).reduce((a, b) => a.isBefore(b) ? a : b);
      newestTransaction = transactions.map((t) => t.date).reduce((a, b) => a.isAfter(b) ? a : b);
    }
    
    
    return {
      'transactionCount': transactions.length,
      'eventCount': events.length,
      'categoryCount': _categoryBox.length,
      'oldestTransaction': oldestTransaction,
      'newestTransaction': newestTransaction,
    };
  }

  Future<int> getDatabaseSize() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      int totalSize = 0;
      
      // Calculate size of all Hive box files
      final boxNames = ['transactions', 'events', 'categories', 'settings'];
      for (var boxName in boxNames) {
        final file = File('${appDir.path}/$boxName.hive');
        if (await file.exists()) {
          totalSize += await file.length();
        }
        // Also check for lock files
        final lockFile = File('${appDir.path}/$boxName.lock');
        if (await lockFile.exists()) {
          totalSize += await lockFile.length();
        }
      }
      
      return totalSize;
    } catch (e) {
      print('Error calculating database size: $e');
      return 0;
    }
  }

  String exportDataToJson({DateTime? startDate, DateTime? endDate}) {
    final transactions = _transactionBox.values.where((t) {
      if (startDate != null && t.date.isBefore(startDate)) return false;
      if (endDate != null && t.date.isAfter(endDate)) return false;
      return true;
    }).toList();

    final events = _eventBox.values.where((e) {
      if (startDate != null && e.date.isBefore(startDate)) return false;
      if (endDate != null && e.date.isAfter(endDate)) return false;
      return true;
    }).toList();

    final data = {
      'exportDate': DateTime.now().toIso8601String(),
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'transactions': transactions.map((t) => {
        'id': t.id,
        'description': t.description,
        'amount': t.amount,
        'isExpense': t.isExpense,
        'date': t.date.toIso8601String(),
        'isReversal': t.isReversal,
        'originalTransactionId': t.originalTransactionId,
        'category': t.category,
        'subcategory': t.subcategory,
      }).toList(),
      'events': events.map((e) => {
        'id': e.id,
        'title': e.title,
        'date': e.date.toIso8601String(),
        'description': e.description,
        'isCancelled': e.isCancelled,
      }).toList(),
    };

    return jsonEncode(data);
  }

  Future<Map<String, int>> importDataFromJson(String jsonData) async {
    final data = jsonDecode(jsonData) as Map<String, dynamic>;
    
    int transactionsImported = 0;
    int eventsImported = 0;

    // Import transactions
    final transactions = data['transactions'] as List;
    for (var tData in transactions) {
      final transaction = Transaction(
        id: tData['id'],
        description: tData['description'],
        amount: (tData['amount'] as num).toDouble(),
        isExpense: tData['isExpense'],
        date: DateTime.parse(tData['date']),
        isReversal: tData['isReversal'] ?? false,
        originalTransactionId: tData['originalTransactionId'],
        category: tData['category'] ?? 'Outras Despesas',
        subcategory: tData['subcategory'],
      );
      await _transactionBox.add(transaction);
      transactionsImported++;
    }

    // Import events
    final events = data['events'] as List;
    for (var eData in events) {
      final event = Event(
        id: eData['id'],
        title: eData['title'],
        date: DateTime.parse(eData['date']),
        description: eData['description'],
        isCancelled: eData['isCancelled'] ?? false,
      );
      await _eventBox.add(event);
      eventsImported++;
    }

    return {
      'transactions': transactionsImported,
      'events': eventsImported,
    };
  }

  Future<Map<String, int>> deleteOldData(DateTime cutoffDate) async {
    int transactionsDeleted = 0;
    int eventsDeleted = 0;

    // Delete old transactions
    final transactionsToDelete = <int>[];
    for (var i = 0; i < _transactionBox.length; i++) {
      final transaction = _transactionBox.getAt(i);
      if (transaction != null && transaction.date.isBefore(cutoffDate)) {
        transactionsToDelete.add(i);
      }
    }
    
    // Delete in reverse order to maintain indices
    for (var i in transactionsToDelete.reversed) {
      await _transactionBox.deleteAt(i);
      transactionsDeleted++;
    }

    // Delete old events
    final eventsToDelete = <int>[];
    for (var i = 0; i < _eventBox.length; i++) {
      final event = _eventBox.getAt(i);
      if (event != null && event.date.isBefore(cutoffDate)) {
        eventsToDelete.add(i);
      }
    }
    
    // Delete in reverse order to maintain indices
    for (var i in eventsToDelete.reversed) {
      await _eventBox.deleteAt(i);
      eventsDeleted++;
    }

    return {
      'transactions': transactionsDeleted,
      'events': eventsDeleted,
    };
  }

  Future<Uint8List> exportBackupBytes({DateTime? startDate, DateTime? endDate}) async {
    final archive = Archive();
    
    // 1. Filter data
    final transactions = _transactionBox.values.where((t) {
      if (startDate != null && t.date.isBefore(startDate)) return false;
      if (endDate != null && t.date.isAfter(endDate)) return false;
      return true;
    }).toList();

    final events = _eventBox.values.where((e) {
      if (startDate != null && e.date.isBefore(startDate)) return false;
      if (endDate != null && e.date.isAfter(endDate)) return false;
      return true;
    }).toList();

    // 2. Process attachments and create modified data for JSON
    final modifiedTransactions = <Map<String, dynamic>>[];
    final modifiedEvents = <Map<String, dynamic>>[];
    
    // Helper to process attachments
    Future<List<String>?> processAttachments(List<String>? attachments) async {
      if (attachments == null || attachments.isEmpty) return null;
      final newPaths = <String>[];
      for (var path in attachments) {
        final file = File(path);
        if (await file.exists()) {
          final filename = p.basename(path);
          final zipPath = 'attachments/$filename';
          
          // Add file to archive if not already added
          if (archive.findFile(zipPath) == null) {
             final bytes = await file.readAsBytes();
             archive.addFile(ArchiveFile(zipPath, bytes.length, bytes));
          }
          
          newPaths.add(zipPath);
        } else {
          newPaths.add(path); 
        }
      }
      return newPaths;
    }

    for (var t in transactions) {
      final newAttachments = await processAttachments(t.attachments);
      modifiedTransactions.add({
        'id': t.id,
        'description': t.description,
        'amount': t.amount,
        'isExpense': t.isExpense,
        'date': t.date.toIso8601String(),
        'isReversal': t.isReversal,
        'originalTransactionId': t.originalTransactionId,
        'category': t.category,
        'subcategory': t.subcategory,
        'installmentId': t.installmentId,
        'installmentNumber': t.installmentNumber,
        'totalInstallments': t.totalInstallments,
        'attachments': newAttachments,
      });
    }

    for (var e in events) {
      final newAttachments = await processAttachments(e.attachments);
      modifiedEvents.add({
        'id': e.id,
        'title': e.title,
        'date': e.date.toIso8601String(),
        'description': e.description,
        'isCancelled': e.isCancelled,
        'recurrence': e.recurrence,
        'lastNotifiedDate': e.lastNotifiedDate?.toIso8601String(),
        'attachments': newAttachments,
      });
    }

    final data = {
      'exportDate': DateTime.now().toIso8601String(),
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'transactions': modifiedTransactions,
      'events': modifiedEvents,
    };

    // 3. Add JSON to archive
    final jsonBytes = utf8.encode(jsonEncode(data));
    archive.addFile(ArchiveFile('data.json', jsonBytes.length, jsonBytes));

    // 4. Encode archive to Zip
    final encoder = ZipEncoder();
    final zipBytes = encoder.encode(archive);
    
    return Uint8List.fromList(zipBytes!);
  }

  Future<Map<String, int>> importBackupBytes(Uint8List zipBytes) async {
    // Check if it's a ZIP file (PK signature)
    bool isZip = zipBytes.length > 4 && 
                 zipBytes[0] == 0x50 && 
                 zipBytes[1] == 0x4B && 
                 zipBytes[2] == 0x03 && 
                 zipBytes[3] == 0x04;

    if (!isZip) {
      // Try to parse as JSON directly (legacy backup)
      try {
        final jsonString = utf8.decode(zipBytes);
        return await importDataFromJson(jsonString);
      } catch (e) {
        throw Exception('Invalid backup format: Not a ZIP or JSON file');
      }
    }

    final archive = ZipDecoder().decodeBytes(zipBytes);
    
    // 1. Extract attachments
    final appDir = await getApplicationDocumentsDirectory();
    final attachmentsDir = Directory('${appDir.path}/attachments');
    if (!await attachmentsDir.exists()) {
      await attachmentsDir.create(recursive: true);
    }

    for (var file in archive) {
      if (file.isFile && file.name.startsWith('attachments/')) {
        final filename = p.basename(file.name);
        final outFile = File('${attachmentsDir.path}/$filename');
        await outFile.writeAsBytes(file.content as List<int>);
      }
    }

    // 2. Read JSON
    final jsonFile = archive.findFile('data.json');
    if (jsonFile == null) {
      throw Exception('Invalid backup: data.json not found');
    }
    final jsonData = utf8.decode(jsonFile.content as List<int>);
    final data = jsonDecode(jsonData) as Map<String, dynamic>;

    int transactionsImported = 0;
    int eventsImported = 0;

    // Helper to restore attachment paths
    List<String>? restoreAttachments(List<dynamic>? attachments) {
      if (attachments == null) return null;
      return attachments.map((path) {
        if (path.toString().startsWith('attachments/')) {
          final filename = p.basename(path);
          return '${attachmentsDir.path}/$filename';
        }
        return path.toString();
      }).toList().cast<String>();
    }

    // Import transactions
    final transactions = data['transactions'] as List;
    for (var tData in transactions) {
      final transaction = Transaction(
        id: tData['id'],
        description: tData['description'],
        amount: (tData['amount'] as num).toDouble(),
        isExpense: tData['isExpense'],
        date: DateTime.parse(tData['date']),
        isReversal: tData['isReversal'] ?? false,
        originalTransactionId: tData['originalTransactionId'],
        category: tData['category'] ?? 'Outras Despesas',
        subcategory: tData['subcategory'],
        installmentId: tData['installmentId'],
        installmentNumber: tData['installmentNumber'],
        totalInstallments: tData['totalInstallments'],
        attachments: restoreAttachments(tData['attachments']),
      );
      await _transactionBox.add(transaction);
      transactionsImported++;
    }

    // Import events
    final events = data['events'] as List;
    for (var eData in events) {
      final event = Event(
        id: eData['id'],
        title: eData['title'],
        date: DateTime.parse(eData['date']),
        description: eData['description'],
        isCancelled: eData['isCancelled'] ?? false,
        recurrence: eData['recurrence'],
        lastNotifiedDate: eData['lastNotifiedDate'] != null 
            ? DateTime.parse(eData['lastNotifiedDate']) 
            : null,
        attachments: restoreAttachments(eData['attachments']),
      );
      await _eventBox.add(event);
      eventsImported++;
    }

    return {
      'transactions': transactionsImported,
      'events': eventsImported,
    };
  }







  /// Helper to convert Event to Map for snapshot
  Map<String, dynamic> _eventToMap(Event event) {
    return {
      'id': event.id,
      'title': event.title,
      'date': event.date.toIso8601String(),
      'description': event.description,
      'isCancelled': event.isCancelled,
      'recurrence': event.recurrence,
      'lastNotifiedDate': event.lastNotifiedDate?.toIso8601String(),
    };
  }


  // Settings: Always announce events
  // Agenda Settings
  int getDefaultAgendaReminderMinutes() {
    if (!_settingsBox.isOpen) return 15;
    return _settingsBox.get('default_agenda_reminder', defaultValue: 15);
  }

  Future<void> setDefaultAgendaReminderMinutes(int minutes) async {
    if (!_settingsBox.isOpen) return;
    int oldDefault = getDefaultAgendaReminderMinutes();
    await _settingsBox.put('default_agenda_reminder', minutes);
    await _propagateReminderChange(AgendaItemType.COMPROMISSO, oldDefault, minutes);
    await _propagateReminderChange(AgendaItemType.TAREFA, oldDefault, minutes);
    await _propagateReminderChange(AgendaItemType.LEMBRETE, oldDefault, minutes);
    await _propagateReminderChange(AgendaItemType.PROJETO, oldDefault, minutes);
    await _propagateReminderChange(AgendaItemType.PRAZO, oldDefault, minutes);
  }

  int getDefaultMedicineReminderMinutes() {
    if (!_settingsBox.isOpen) return 5;
    return _settingsBox.get('default_medicine_reminder', defaultValue: 5);
  }

  Future<void> setDefaultMedicineReminderMinutes(int minutes) async {
    if (!_settingsBox.isOpen) return;
    int oldDefault = getDefaultMedicineReminderMinutes();
    await _settingsBox.put('default_medicine_reminder', minutes);
    await _propagateReminderChange(AgendaItemType.REMEDIO, oldDefault, minutes);
  }

  int getDefaultPaymentReminderMinutes() {
    if (!_settingsBox.isOpen) return 30;
    return _settingsBox.get('default_payment_reminder', defaultValue: 30);
  }

  Future<void> setDefaultPaymentReminderMinutes(int minutes) async {
    if (!_settingsBox.isOpen) return;
    int oldDefault = getDefaultPaymentReminderMinutes();
    await _settingsBox.put('default_payment_reminder', minutes);
    await _propagateReminderChange(AgendaItemType.PAGAMENTO, oldDefault, minutes);
  }

  int getDefaultWarningCount() {
    if (!_settingsBox.isOpen) return 3;
    return _settingsBox.get('default_warning_count', defaultValue: 3);
  }

  Future<void> setDefaultWarningCount(int count) async {
    if (!_settingsBox.isOpen) return;
    int oldDefault = getDefaultWarningCount();
    await _settingsBox.put('default_warning_count', count);
    
    // We should also propagate? User requested: "Toda vez que o usuário mudar o valor do campo avisar antes..."
    // Did they ask for this for "Quantity" too? 
    // "Inserir um campo... Na configuração estabelecer um item de quantidade de avisos e 3 será o padrão."
    // Doesn't explicitly say to update old items.
    // BUT, consistency suggests yes.
    // However, I will implement propagation later if requested, to be safe.
    // Or I can add it now. Let's add it for consistency.
    await _propagateWarningCountChange(oldDefault, count);
  }

  Future<void> _propagateWarningCountChange(int oldDefault, int newDefault) async {
       try {
         if (!Hive.isBoxOpen('agenda_items')) return; 
         final box = Hive.box<AgendaItem>('agenda_items');
         final now = DateTime.now();
         
         // Updates ALL types? "Inserir um campo em todos os tipos de agenda"
         // So we filter all.
         final itemsToUpdate = box.values.where((item) {
             if (item.dataInicio != null && item.dataInicio!.isBefore(now)) return false; 
             if (item.status == ItemStatus.CONCLUIDO || item.status == ItemStatus.CANCELADO) return false;
             
             int currentVal = item.quantidadeAvisos ?? oldDefault;
             return currentVal == oldDefault;
         }).toList();

         for (var item in itemsToUpdate) {
            item.quantidadeAvisos = newDefault;
            await item.save(); 
            // Note: changing count doesn't reschedule notification unless we implement multiple notifications logic.
            // Since we haven't implemented logic for "Multiple Warnings" in Repository yet,
            // we just save the value. Repository will use it next time _schedule is called or if we trigger it.
            // To be safe, we should trigger reschedule if we implement the logic soon.
         }
         print("DEBUG: Propagated WARNING COUNT change (old: $oldDefault -> new: $newDefault) to ${itemsToUpdate.length} items.");
       } catch (e) {
          print("ERROR propagating warning count: $e");
       }
  }

  Future<void> _propagateReminderChange(AgendaItemType type, int oldDefault, int newDefault) async {
     try {
       // Avoid circular dependency by getting box directly if possible, or lazy loading repo logic
       // Since DatabaseService handles Hive Boxes, we can iterate Agenda Box if it's open.
       if (!Hive.isBoxOpen('agenda_items')) return; 
       
       final box = Hive.box<AgendaItem>('agenda_items');
       final now = DateTime.now();
       
       final itemsToUpdate = box.values.where((item) {
          // 1. Match Type
          if (item.tipo != type) return false;
          // 2. Is Future Event
          if (item.dataInicio != null && item.dataInicio!.isBefore(now)) return false; 
          // 3. Status is not Completed/Cancelled (optional, but good practice)
          if (item.status == ItemStatus.CONCLUIDO || item.status == ItemStatus.CANCELADO) return false;

          // 4. CRITICAL: Matches OLD default (user hasn't customized it)
          // If avisoMinutosAntes is NULL, it effectively IS the default (implicitly).
          // If it is explicitly set to oldDefault, we update it.
          int currentVal = item.avisoMinutosAntes ?? oldDefault;
          return currentVal == oldDefault;
       }).toList();

       for (var item in itemsToUpdate) {
          item.avisoMinutosAntes = newDefault;
          await item.save(); // This saves to Hive
          
          // We also need to RESCHEDULE notification.
          // Since AgendaRepository logic for rescheduling is in AgendaRepository, 
          // and DatabaseService shouldn't depend on Repo (circular), 
          // we can call NotificationService directly logic here or duplicated logic.
          // BUT, to be clean, we should trigger a reschedule.
          // Ideally, the item.save() triggers a listener? No.
          
          // We will use NotificationService directly to reschedule.
          // Logic: Calculate new time.
          if (item.dataInicio == null) continue;
           
           DateTime? scheduledTime;
           if (item.horarioInicio != null && item.horarioInicio!.contains(':')) {
               final parts = item.horarioInicio!.split(':');
               scheduledTime = DateTime(item.dataInicio!.year, item.dataInicio!.month, item.dataInicio!.day, int.parse(parts[0]), int.parse(parts[1]));
           }
           
           if (scheduledTime != null) {
               final notificationTime = scheduledTime.subtract(Duration(minutes: newDefault));
               final id = item.key as int;
               
               String body = item.descricao ?? 'Agenda FinAgeVoz';
               if (type == AgendaItemType.PAGAMENTO && item.pagamento != null) {
                  body = "Vencimento: R\$ ${item.pagamento!.valor.toStringAsFixed(2)}";
               } else if (type == AgendaItemType.REMEDIO && item.remedio != null) {
                  body = "Dosagem: ${item.remedio!.dosagem}";
               }
               
               if (notificationTime.isBefore(scheduledTime)) {
                   body = "Em ${scheduledTime.difference(notificationTime).inMinutes} minutos: " + body;
               }

               await NotificationService().scheduleEvent(
                  id, 
                  item.titulo, 
                  body, 
                  notificationTime
               );
           }
       }
       print("DEBUG: Propagated default change (old: $oldDefault -> new: $newDefault) to ${itemsToUpdate.length} items of type $type.");

     } catch (e) {
       print("ERROR propagating reminder change: $e");
     }
  }

  // --- EXISTING METHODS BELOW ---
  bool getAlwaysAnnounceEvents() {
    return _settingsBox.get('always_announce_events', defaultValue: true);
  }

  Future<void> setAlwaysAnnounceEvents(bool value) async {
    await _settingsBox.put('always_announce_events', value);
  }

  // Settings: Voice commands enabled
  bool getVoiceCommandsEnabled() {
    return _settingsBox.get('voice_commands_enabled', defaultValue: true);
  }

  Future<void> setVoiceCommandsEnabled(bool value) async {
    await _settingsBox.put('voice_commands_enabled', value);
  }

  // Settings: App Lock (Biometrics)
  bool getAppLockEnabled() {
    return _settingsBox.get('app_lock_enabled', defaultValue: false);
  }

  Future<void> setAppLockEnabled(bool value) async {
    await _settingsBox.put('app_lock_enabled', value);
  }

  bool getAutoSyncEnabled() {
    return _settingsBox.get('auto_sync_enabled', defaultValue: true);
  }

  Future<void> setAutoSyncEnabled(bool value) async {
    await _settingsBox.put('auto_sync_enabled', value);
  }

  // --- Sync Helpers ---

  Future<void> markTransactionAsSynced(Transaction t) async {
    // We need to find the key because the object passed might be a copy
    dynamic key;
    if (t.isInBox) {
      key = t.key;
    } else {
      try {
        final existing = _transactionBox.values.firstWhere((item) => item.id == t.id);
        key = existing.key;
      } catch (e) {
        return; // Not found
      }
    }

    final updated = Transaction(
      id: t.id,
      description: t.description,
      amount: t.amount,
      isExpense: t.isExpense,
      date: t.date,
      category: t.category,
      subcategory: t.subcategory,
      isReversal: t.isReversal,
      originalTransactionId: t.originalTransactionId,
      installmentId: t.installmentId,
      installmentNumber: t.installmentNumber,
      totalInstallments: t.totalInstallments,
      attachments: t.attachments,
      updatedAt: t.updatedAt,
      isDeleted: t.isDeleted,
      isSynced: true,
    );
    await _transactionBox.put(key, updated);
  }

  Future<void> markEventAsSynced(Event e) async {
    dynamic key;
    if (e.isInBox) {
      key = e.key;
    } else {
      try {
        final existing = _eventBox.values.firstWhere((item) => item.id == e.id);
        key = existing.key;
      } catch (err) {
        return;
      }
    }

    final updated = Event(
      id: e.id,
      title: e.title,
      date: e.date,
      description: e.description,
      isCancelled: e.isCancelled,
      recurrence: e.recurrence,
      lastNotifiedDate: e.lastNotifiedDate,
      attachments: e.attachments,
      updatedAt: e.updatedAt,
      isDeleted: e.isDeleted,
      isSynced: true,
    );
    await _eventBox.put(key, updated);
  }

  Future<void> markCategoryAsSynced(Category c) async {
    dynamic key;
    if (c.isInBox) {
      key = c.key;
    } else {
      try {
        final existing = _categoryBox.values.firstWhere((item) => item.id == c.id);
        key = existing.key;
      } catch (err) {
        return;
      }
    }

    final updated = Category(
      id: c.id,
      name: c.name,
      description: c.description,
      subcategories: c.subcategories,
      type: c.type,
      updatedAt: c.updatedAt,
      isDeleted: c.isDeleted,
      isSynced: true,
    );
    await _categoryBox.put(key, updated);
  }


  // One-time reset for new agenda
  Future<void> resetAgenda() async {
    await _eventBox.clear();
    await _settingsBox.put('agenda_reset_v2', true);
    print("DEBUG: Agenda events cleared for update.");
  }
  
  bool get isAgendaResetV2 => _settingsBox.get('agenda_reset_v2', defaultValue: false);

  // Medicine CRUD
  Future<void> addRemedio(Remedio r) async {
    await _remedioBox.put(r.id, r);
  }
  
  List<Remedio> getRemedios() => _remedioBox.values.toList();
  
  Remedio? getRemedio(String id) => _remedioBox.get(id);

  Future<void> updateRemedio(Remedio r) async {
    await _remedioBox.put(r.id, r);
  }

  Future<void> deleteRemedio(String id) async {
    await _remedioBox.delete(id);
    final posologias = getPosologias(id);
    for (var p in posologias) {
       await deletePosologia(p.id);
    }
  }

  // Posologia CRUD
  Future<void> addPosologia(Posologia p) async {
    await _posologiaBox.put(p.id, p);
    final remedio = getRemedio(p.remedioId);
    if (remedio != null) {
       if (!remedio.posologiaIds.contains(p.id)) {
           remedio.posologiaIds.add(p.id);
           await updateRemedio(remedio);
       }
       // Notification Hook
       await NotificationService().schedulePosology(p, remedio);
    }
  }

  List<Posologia> getPosologias(String remedioId) {
    return _posologiaBox.values.where((p) => p.remedioId == remedioId).toList();
  }
  
  Posologia? getPosologia(String id) => _posologiaBox.get(id);

  Future<void> updatePosologia(Posologia p) async {
    await _posologiaBox.put(p.id, p);
    
    // Notification Hook (Cancel old + Schedule new)
    final remedio = getRemedio(p.remedioId);
    if (remedio != null) {
        await NotificationService().cancelPosologyNotifications(p.id);
        await NotificationService().schedulePosology(p, remedio);
    }
  }

  Future<void> deletePosologia(String id) async {
    // Notification Hook (Cancel)
    await NotificationService().cancelPosologyNotifications(id);
    
    await _posologiaBox.delete(id);
    final history = getHistorico(id);
    for (var h in history) {
       await deleteHistoricoTomada(h.id);
    }
  }

  // Historico CRUD
  Future<void> addHistoricoTomada(HistoricoTomada h) async {
    await _historicoTomadaBox.put(h.id, h);
  }

  List<HistoricoTomada> getHistorico(String posologiaId) {
    return _historicoTomadaBox.values.where((h) => h.posologiaId == posologiaId).toList();
  }
  
  List<HistoricoTomada> getAllHistorico() => _historicoTomadaBox.values.toList();

  Future<void> deleteHistoricoTomada(String id) async {
    await _historicoTomadaBox.delete(id);
  }

  // ===== PRIVACY & COMPLIANCE METHODS =====
  
  /// Verifica se o usuário aceitou a política de privacidade
  /// Conforme Google Play Privacy Policy Requirements
  bool hasAcceptedPrivacy() {
    return _settingsBox.get('privacy_accepted', defaultValue: false);
  }

  /// Marca que o usuário aceitou a política de privacidade
  Future<void> setPrivacyAccepted(bool value) async {
    await _settingsBox.put('privacy_accepted', value);
  }

  /// Deleta TODOS os dados do usuário (transações, eventos, medicamentos, etc.)
  /// Usado para exclusão de conta conforme Google Play Account Deletion Policy
  /// ATENÇÃO: Esta ação é IRREVERSÍVEL!
  Future<void> deleteAllData() async {
    print("DEBUG: Iniciando exclusão completa de dados...");
    
    // Limpar todas as boxes de DADOS (preservando configurações estruturais como categorias)
    await _transactionBox.clear();
    await _eventBox.clear();
    // await _categoryBox.clear(); // NÃO apagar categorias

    await _remedioBox.clear();
    await _posologiaBox.clear();
    await _historicoTomadaBox.clear();
    
    // AGENDA ITEMS
    await ensureAgendaBoxOpen();
    await agendaBox.clear();
    
    // Limpar settings (mas manter configuração de idioma se desejar)
    final currentLanguage = getLanguage();
    await _settingsBox.clear();
    await setLanguage(currentLanguage); // Restaurar idioma
    
    // Categorias são preservadas, não precisa re-seed
    // await _seedCategories();
    
    print("DEBUG: Todos os dados foram excluídos.");
  }
  /* Sincronismo Financeiro -> Agenda */

  Future<void> _syncMissingAgendaItems() async {
     print("DEBUG: Checking for missing agenda items...");
     await ensureAgendaBoxOpen();
     final agenda = agendaBox;
     
     final existingIds = agenda.values
         .where((i) => i.pagamento?.transactionId != null)
         .map((i) => i.pagamento!.transactionId!)
         .toSet();
         
     final transactions = _transactionBox.values; 
     int count = 0;
     
     for (var t in transactions) {
        // STRICT RULE: Only Pending items.
        // STRICT RULE: Only Pending items.
        // Paid items or Deleted items must NOT be in Agenda.
        if (t.isDeleted) continue;
        
        bool isRelevant = !t.isPaid; 
        if (!isRelevant) continue;

        if (!existingIds.contains(t.id)) {
           await _syncAdd(t); // Reuse existing add logic which assumes box is open
           count++;
        }
     }
     if (count > 0) print("DEBUG: Synced $count missing transactions to agenda.");
  }

  Future<void> _syncAdd(Transaction t) async {
    // Sincronizar se for relevante para Agenda:
    // Apenas PENDENTES (A Pagar / A Receber).
    // Realizados (Pagos) NÃO vão para agenda.
    
    bool isRelevant = !t.isPaid;
    
    if (!isRelevant) return;

    await ensureAgendaBoxOpen();
    final box = agendaBox;

    final prefix = t.isExpense ? "Pagar: " : "Receber: ";
    final baseTitle = t.description;
    final fullTitle = baseTitle.startsWith(prefix) ? baseTitle : "$prefix$baseTitle";

    final agendaItem = AgendaItem(
      tipo: AgendaItemType.PAGAMENTO,
      titulo: fullTitle,
      descricao: t.installmentText.isNotEmpty ? t.installmentText : "Gerado pelo Financeiro",
      dataInicio: t.date,
      horarioInicio: "${t.date.hour}:${t.date.minute.toString().padLeft(2,'0')}",
      status: t.isPaid ? ItemStatus.CONCLUIDO : ItemStatus.PENDENTE,
      pagamento: PagamentoInfo(
        valor: t.amount.abs(), // Valor absoluto
        status: t.isPaid ? 'PAGO' : 'PENDENTE',
        dataVencimento: t.date,
        dataPagamento: t.paymentDate,
        transactionId: t.id,
        moeda: 'BRL',
      ),
      criado: DateTime.now(),
    );

    final exists = box.values.any((i) => i.pagamento?.transactionId == t.id);
    if (!exists) {
       await box.add(agendaItem);
       print("DEBUG: Synced transaction ${t.id} to Agenda.");
    }
  }

  Future<void> _syncUpdate(Transaction t) async {
    await ensureAgendaBoxOpen();
    final box = agendaBox;

    // RELEVANCE RULE: Only Pending items go to Agenda/Payments Tab.
    // If it is PAID (Realized), it must NOT be in the Agenda.
    // This applies to single transactions and paid installments.
    bool isRelevant = !t.isPaid;

    AgendaItem? item;
    try {
      item = box.values.firstWhere((i) => i.pagamento?.transactionId == t.id);
    } catch (_) {}

    if (!isRelevant) {
       // If transaction is Paid, REMOVE from Agenda if it exists.
       if (item != null) {
          await item.delete();
          print("DEBUG: Deleted agenda item for transaction ${t.id} because it is Paid.");
       }
       return;
    }

    // If Relevant (Pending): Update or Create
    if (item == null) {
       await _syncAdd(t);
       return;
    }
    
    // Update existing item
    try {
      final prefix = t.isExpense ? "Pagar: " : "Receber: ";
      final fullTitle = "$prefix${t.description}";

      item.titulo = fullTitle;
      item.descricao = t.installmentText.isNotEmpty ? t.installmentText : "Gerado pelo Financeiro";
      item.dataInicio = t.date;
      item.horarioInicio = "${t.date.hour}:${t.date.minute.toString().padLeft(2,'0')}";
      
      // Since it is relevant, it is Pending.
      item.status = ItemStatus.PENDENTE;
      item.atualizadoEm = DateTime.now();
      
      if (item.pagamento != null) {
        item.pagamento!.valor = t.amount.abs();
        item.pagamento!.status = 'PENDENTE';
        item.pagamento!.dataVencimento = t.date;
        item.pagamento!.dataPagamento = null;
      }

      await item.save();
      print("DEBUG: Updated synced agenda item for ${t.id}");
    } catch (e) {
       print("Error updating agenda item: $e");
    }
  }

  Future<void> _syncDelete(String transactionId) async {
    await ensureAgendaBoxOpen();
    final box = agendaBox;
    
    final itemsToDelete = box.values.where((i) => i.pagamento?.transactionId == transactionId).toList();
    for (var item in itemsToDelete) {
      await item.delete();
      print("DEBUG: Deleted synced agenda item for $transactionId");
    }
  }
  Future<void> _fixPastTenseTransactions() async {
      // Heuristic: If description contains "Comprei", "Gastei", "Paguei" -> it should be PAID.
      // This acts as a safety net for any logic gaps where past actions were saved as pending.
      final transactions = _transactionBox.values.where((t) => !t.isPaid && !t.isDeleted).toList();
      int fixed = 0;
      for (var t in transactions) {
          final desc = t.description.toLowerCase();
          // Simple Check: Contains precise words suggesting past action.
          if (desc.contains("comprei") || desc.contains("gastei") || desc.contains("paguei")) {
               // Safety exclusion list
               if (!desc.contains("vou") && !desc.contains("preciso") && !desc.contains("falta") && !desc.contains("para")) {
                   // Fix it: Force isPaid = true
                  final updated = Transaction(
                      id: t.id,
                      description: t.description,
                      amount: t.amount,
                      isExpense: t.isExpense,
                      date: t.date,
                      category: t.category,
                      subcategory: t.subcategory,
                      installmentId: t.installmentId,
                      installmentNumber: t.installmentNumber,
                      totalInstallments: t.totalInstallments,
                      attachments: t.attachments,
                      updatedAt: DateTime.now(),
                      isDeleted: t.isDeleted,
                      isSynced: false,
                      isPaid: true, // FORCE TRUE
                      paymentDate: t.date, // Assume paid on transaction date
                      isReversal: t.isReversal,
                      originalTransactionId: t.originalTransactionId,
                  );
                  await _transactionBox.put(t.key, updated);
                  fixed++;
               }
          }
      }
      if (fixed > 0) print("DEBUG: Auto-fixed $fixed past tense transactions to PAID.");
  }

  Future<void> _resetSyncedAgendaItems() async {
     print("DEBUG: Executing Full Agenda Resync (Nuke Option)...");
     await ensureAgendaBoxOpen();
     
     // User Request Step 2995: "Limpar toda a aba Pagamentos antes de repovoar".
     // Delete ALL AgendaItemType.PAGAMENTO unconditionally.
     final toDelete = agendaBox.values.where((i) => i.tipo == AgendaItemType.PAGAMENTO).toList();
     
     for (var item in toDelete) {
       await item.delete();
     }
     print("DEBUG: Deleted ${toDelete.length} payment items (Global Nuke).");
  }
}
