import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models/daily_progress_model.dart';

class ProgressService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> addProgress(DailyProgressModel model) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('progress')
        .doc(model.date.toIso8601String())
        .set(model.toMap());
  }

  Future<List<DailyProgressModel>> fetchProgressData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];

    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('progress')
        .orderBy('date', descending: false)
        .get();

    return snapshot.docs.map((doc) => DailyProgressModel.fromMap(doc.data())).toList();
  }
}
