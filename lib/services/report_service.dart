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
    double? latitude,
    double? longitude,
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
        'latitude': latitude,
        'longitude': longitude,
        'mediaUrls': mediaUrls ?? [],
        'status': 'pending', // pending, in-progress, resolved
        'assignedTo': null, // Admin/handler assigned to this report
        'assignedToName': null, // Name of assigned admin
        'solutionDescription': null, // Description of how issue was resolved
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

  // Assign handler to report (admin use)
  Future<void> assignHandler({
    required String reportId,
    required String adminId,
    required String adminName,
  }) async {
    try {
      await _firestore.collection('reports').doc(reportId).update({
        'assignedTo': adminId,
        'assignedToName': adminName,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Handler assigned to report');
    } catch (e) {
      print('❌ Error assigning handler: $e');
      rethrow;
    }
  }

  // Add solution description when resolving (admin use)
  Future<void> resolveReportWithSolution({
    required String reportId,
    required String solutionDescription,
  }) async {
    try {
      await _firestore.collection('reports').doc(reportId).update({
        'status': 'resolved',
        'solutionDescription': solutionDescription,
        'resolvedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Report resolved with solution');
    } catch (e) {
      print('❌ Error resolving report: $e');
      rethrow;
    }
  }

  // Submit feedback rating for resolved report
  Future<void> submitFeedbackRating({
    required String reportId,
    required int rating,
    String? feedbackComment,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      await _firestore.collection('reports').doc(reportId).update({
        'rating': rating,
        'feedbackComment': feedbackComment,
        'ratedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Rating submitted successfully!');
    } catch (e) {
      print('❌ Error submitting rating: $e');
      rethrow;
    }
  }

  // Delete report
  Future<void> deleteReport(String reportId) async {
    try {
      await _firestore.collection('reports').doc(reportId).delete();
      print('✅ Report deleted successfully!');
    } catch (e) {
      print('❌ Error deleting report: $e');
      rethrow;
    }
  }
}
