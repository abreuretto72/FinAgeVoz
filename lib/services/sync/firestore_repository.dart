import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/transaction_model.dart' as tm;
import '../../models/event_model.dart';
import '../../models/category_model.dart';

class FirestoreRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  // --- Transactions ---

  Future<void> saveTransaction(tm.Transaction transaction) async {
    if (_userId == null) return;
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('transactions')
        .doc(transaction.id)
        .set(transaction.toMap());
  }

  Future<List<tm.Transaction>> getTransactionsSince(DateTime? since) async {
    if (_userId == null) return [];
    
    Query query = _firestore
        .collection('users')
        .doc(_userId)
        .collection('transactions');

    if (since != null) {
      query = query.where('updatedAt', isGreaterThan: since.toIso8601String());
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      return tm.Transaction.fromMap(doc.data() as Map<String, dynamic>);
    }).toList();
  }

  // --- Events ---

  Future<void> saveEvent(Event event) async {
    if (_userId == null) return;
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('events')
        .doc(event.id)
        .set(event.toMap());
  }

  Future<List<Event>> getEventsSince(DateTime? since) async {
    if (_userId == null) return [];

    Query query = _firestore
        .collection('users')
        .doc(_userId)
        .collection('events');

    if (since != null) {
      query = query.where('updatedAt', isGreaterThan: since.toIso8601String());
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      return Event.fromMap(doc.data() as Map<String, dynamic>);
    }).toList();
  }

  // --- Categories ---

  Future<void> saveCategory(Category category) async {
    if (_userId == null) return;
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('categories')
        .doc(category.id)
        .set(category.toMap());
  }

  Future<List<Category>> getCategoriesSince(DateTime? since) async {
    if (_userId == null) return [];

    Query query = _firestore
        .collection('users')
        .doc(_userId)
        .collection('categories');

    if (since != null) {
      query = query.where('updatedAt', isGreaterThan: since.toIso8601String());
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      return Category.fromMap(doc.data() as Map<String, dynamic>);
    }).toList();
  }
}
