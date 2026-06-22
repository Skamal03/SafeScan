import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Save a scan report
  Future<void> saveReport({
    required String type, // 'SSL Check', 'WiFi Scan', 'Breach Check', 'Device Audit'
    required String status, // 'SAFE', 'WARNING', 'CRITICAL'
    required String summary, // Short description like "google.com is secure"
    required Map<String, dynamic> details, // Full JSON data
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _db.collection('users').doc(user.uid).collection('reports').add({
        'type': type,
        'status': status,
        'summary': summary,
        'timestamp': FieldValue.serverTimestamp(),
        'details': details,
      });
    } catch (e) {
      print("Error saving report: $e");
    }
  }

  // Stream for history
  Stream<QuerySnapshot> getReportHistory() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('reports')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Purge history
  Future<void> purgeHistory() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final reports = await _db.collection('users').doc(user.uid).collection('reports').get();
      final batch = _db.batch();
      for (var doc in reports.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print("Error purging history: $e");
    }
  }
}
