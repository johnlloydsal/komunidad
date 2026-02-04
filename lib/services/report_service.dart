import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Submit a new issue report
  Future<void> submitReport({
    required String name,
    required String description,
    required String category,
    required String location,
    List<String>? mediaUrls,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      await _firestore.collection('reports').add({
        'userId': user.uid,
        'userEmail': user.email,
        'userName': name,
        'description': description,
        'category': category,
        'location': location,
        'mediaUrls': mediaUrls ?? [],
        'status': 'pending', // pending, in-progress, resolved
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Report submitted successfully!');
    } catch (e) {
      print('❌ Error submitting report: $e');
      rethrow;
    }
  }

  // Get all reports for current user
  Future<List<Map<String, dynamic>>> getUserReports() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final snapshot = await _firestore
          .collection('reports')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
    } catch (e) {
      print('❌ Error getting user reports: $e');
      return [];
    }
  }

  // Stream user reports for real-time updates
  Stream<List<Map<String, dynamic>>> streamUserReports() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('reports')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {...doc.data(), 'id': doc.id})
              .toList(),
        );
  }

  // Update report status (for admin use)
  Future<void> updateReportStatus(String reportId, String status) async {
    try {
      await _firestore.collection('reports').doc(reportId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error updating report status: $e');
      rethrow;
    }
  }
}
