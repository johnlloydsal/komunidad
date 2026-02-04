import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ServiceRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Submit a new service request
  Future<void> submitServiceRequest({
    required String name,
    required String description,
    required String category,
    required String location,
    String? mediaUrl,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      await _firestore.collection('service_requests').add({
        'userId': user.uid,
        'userEmail': user.email,
        'userName': name,
        'description': description,
        'category': category,
        'location': location,
        'mediaUrl': mediaUrl,
        'status': 'pending', // pending, in-progress, completed
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Service request submitted successfully!');
    } catch (e) {
      print('❌ Error submitting service request: $e');
      rethrow;
    }
  }

  // Get all service requests for current user
  Future<List<Map<String, dynamic>>> getUserServiceRequests() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final snapshot = await _firestore
          .collection('service_requests')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
    } catch (e) {
      print('❌ Error getting user service requests: $e');
      return [];
    }
  }

  // Stream user service requests for real-time updates
  Stream<List<Map<String, dynamic>>> streamUserServiceRequests() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('service_requests')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {...doc.data(), 'id': doc.id})
              .toList(),
        );
  }

  // Update service request status
  Future<void> updateServiceRequestStatus(
    String requestId,
    String status,
  ) async {
    try {
      await _firestore.collection('service_requests').doc(requestId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error updating service request status: $e');
      rethrow;
    }
  }
}
