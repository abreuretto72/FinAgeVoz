import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsi;
import '../database_service.dart';
import 'firestore_repository.dart';
import '../../models/transaction_model.dart';
import '../../models/event_model.dart';
import '../../models/category_model.dart';

class CloudSyncService {
  static final CloudSyncService _instance = CloudSyncService._internal();
  factory CloudSyncService() => _instance;
  CloudSyncService._internal();

  final DatabaseService _dbService = DatabaseService();
  final FirestoreRepository _firestoreRepo = FirestoreRepository();
  final Connectivity _connectivity = Connectivity();

  Timer? _autoSyncTimer;
  bool _isSyncing = false;
  
  // Observable status
  final ValueNotifier<bool> isSyncingNotifier = ValueNotifier(false);
  final ValueNotifier<DateTime?> lastSyncNotifier = ValueNotifier(null);

  Future<void> init() async {
    lastSyncNotifier.value = _dbService.getLastSyncTime();
    
    // Listen to connectivity changes
    _connectivity.onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        sync();
      }
    });

    startAutoSync();
  }

  void startAutoSync() {
    _autoSyncTimer?.cancel();
    if (!_dbService.getAutoSyncEnabled()) return;
    
    // Sync every 5 minutes
    _autoSyncTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      sync();
    });
  }

  Future<void> sync() async {
    if (_isSyncing) return;
    
    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) return;

    _isSyncing = true;
    isSyncingNotifier.value = true;

    try {
      print("DEBUG: Starting Cloud Sync...");
      
      // 1. Sync FROM Cloud (Download changes)
      await _syncFromCloud();

      // 2. Sync TO Cloud (Upload changes)
      await _syncToCloud();

      // 3. Update Last Sync Time
      final now = DateTime.now().toUtc();
      await _dbService.setLastSyncTime(now);
      lastSyncNotifier.value = now;
      
      print("DEBUG: Cloud Sync Completed Successfully.");
    } catch (e) {
      print("ERROR: Cloud Sync Failed: $e");
    } finally {
      _isSyncing = false;
      isSyncingNotifier.value = false;
    }
  }

  Future<void> _syncFromCloud() async {
    final lastSync = _dbService.getLastSyncTime();
    
    // --- Transactions ---
    final cloudTransactions = await _firestoreRepo.getTransactionsSince(lastSync);
    for (var cloudT in cloudTransactions) {
      await _dbService.saveTransactionFromCloud(cloudT);
    }

    // --- Events ---
    final cloudEvents = await _firestoreRepo.getEventsSince(lastSync);
    for (var cloudE in cloudEvents) {
      await _dbService.saveEventFromCloud(cloudE);
    }

    // --- Categories ---
    final cloudCategories = await _firestoreRepo.getCategoriesSince(lastSync);
    for (var cloudC in cloudCategories) {
      await _dbService.saveCategoryFromCloud(cloudC);
    }
  }

  Future<void> _syncToCloud() async {
    // --- Transactions ---
    final dirtyTransactions = _dbService.getDirtyTransactions();
    for (var t in dirtyTransactions) {
      await _firestoreRepo.saveTransaction(t);
      await _dbService.markTransactionAsSynced(t);
    }

    // --- Events ---
    final dirtyEvents = _dbService.getDirtyEvents();
    for (var e in dirtyEvents) {
      await _firestoreRepo.saveEvent(e);
      await _dbService.markEventAsSynced(e);
    }

    // --- Categories ---
    final dirtyCategories = _dbService.getDirtyCategories();
    for (var c in dirtyCategories) {
      await _firestoreRepo.saveCategory(c);
      await _dbService.markCategoryAsSynced(c);
    }
  }

  // --- Auth ---
  
  User? get currentUser => FirebaseAuth.instance.currentUser;
  
  Stream<User?> get authStateChanges => FirebaseAuth.instance.authStateChanges();

  Future<User?> signInWithGoogle() async {
    print("DEBUG: Iniciando signInWithGoogle...");
    try {
      // Trigger the authentication flow
      print("DEBUG: Chamando GoogleSignIn().signIn()...");
      final gsi.GoogleSignInAccount? googleUser = await gsi.GoogleSignIn().signIn();
      
      if (googleUser == null) {
        print("DEBUG: GoogleSignIn retornou null (usuário cancelou ou falha silenciosa).");
        return null;
      }
      print("DEBUG: GoogleSignIn sucesso: ${googleUser.email}");

      // Obtain the auth details from the request
      final gsi.GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      print("DEBUG: Autenticação obtida. AccessToken: ${googleAuth.accessToken != null}, IdToken: ${googleAuth.idToken != null}");

      // Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      print("DEBUG: Fazendo login no Firebase com credencial...");
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      print("DEBUG: Login no Firebase realizado com sucesso: ${userCredential.user?.uid}");
      return userCredential.user;
    } catch (e, stackTrace) {
      print("ERROR: Erro detalhado no signInWithGoogle: $e");
      print("STACKTRACE: $stackTrace");
      return null;
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    // Clear local user data? No, we keep local data.
  }

  /// Checks if there is data in the cloud that can be restored.
  /// Returns true if cloud has data and local is empty.
  Future<bool> hasCloudDataToRestore() async {
    if (currentUser == null) return false;
    
    // Check if local is empty
    if (_dbService.getTransactions().isNotEmpty) return false;

    // Check if cloud has data (limit 1)
    final transactions = await _firestoreRepo.getTransactionsSince(DateTime(2000));
    return transactions.isNotEmpty;
  }
}
