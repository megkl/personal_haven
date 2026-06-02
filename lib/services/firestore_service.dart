import 'package:cloud_firestore/cloud_firestore.dart';

/// Central Firestore helper — all collections live under users/{uid}/...
class FirestoreService {
  static final FirestoreService instance = FirestoreService._();
  FirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Collection references ────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> userDoc(String uid) =>
      _db.collection('users');

  DocumentReference<Map<String, dynamic>> userProfile(String uid) =>
      _db.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> col(String uid, String name) =>
      _db.collection('users').doc(uid).collection(name);

  // ── Generic CRUD ─────────────────────────────────────────────────────────────

  Future<void> set(String uid, String collection, String docId,
      Map<String, dynamic> data) async {
    await col(uid, collection).doc(docId).set(data);
  }

  Future<void> update(String uid, String collection, String docId,
      Map<String, dynamic> data) async {
    await col(uid, collection).doc(docId).update(data);
  }

  Future<void> delete(String uid, String collection, String docId) async {
    await col(uid, collection).doc(docId).delete();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> get(
      String uid, String collection, String docId) async {
    return await col(uid, collection).doc(docId).get();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getAll(
      String uid, String collection) async {
    return await col(uid, collection).get();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> query(
      String uid,
      String collection,
      Query<Map<String, dynamic>> Function(
              CollectionReference<Map<String, dynamic>>)
          builder) async {
    return await builder(col(uid, collection)).get();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> stream(
      String uid,
      String collection,
      Query<Map<String, dynamic>> Function(
              CollectionReference<Map<String, dynamic>>)
          builder) {
    return builder(col(uid, collection)).snapshots();
  }
}
