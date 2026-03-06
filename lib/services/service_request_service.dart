import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';

class ServiceRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  // Submit a new service request
  Future<String> submitServiceRequest({
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

      final docRef = await _firestore.collection('service_requests').add({
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

      print('✅ Service request submitted successfully! ID: ${docRef.id}');
      return docRef.id;
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
      // Get request data for notification
      final requestDoc = await _firestore.collection('service_requests').doc(requestId).get();
      final requestData = requestDoc.data();
      
      await _firestore.collection('service_requests').doc(requestId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Send notification to user
      if (requestData != null && requestData['userId'] != null) {
        String notificationBody = 'Your service request status has been updated to: $status';
        if (status == 'in-progress') {
          notificationBody = 'Your service request is now being processed.';
        } else if (status == 'completed') {
          notificationBody = 'Good news! Your service request has been completed.';
        }
        
        await _notificationService.sendNotificationToUser(
          userId: requestData['userId'],
          title: '📋 Service Request Updated',
          body: notificationBody,
          type: 'service',
          actionId: requestId,
        );
      }
    } catch (e) {
      print('❌ Error updating service request status: $e');
      rethrow;
    }
  }

  // Submit feedback rating for resolved service request
  Future<void> submitFeedbackRating({
    required String requestId,
    required int rating,
    String? feedbackComment,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      await _firestore.collection('service_requests').doc(requestId).update({
        'rating': rating,
        'feedbackComment': feedbackComment,
        'ratedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Service request rating submitted successfully!');
    } catch (e) {
      print('❌ Error submitting rating: $e');
      rethrow;
    }
  }

  // Delete service request
  Future<void> deleteServiceRequest(String requestId) async {
    try {
      await _firestore.collection('service_requests').doc(requestId).delete();
      print('✅ Service request deleted successfully!');
    } catch (e) {
      print('❌ Error deleting service request: $e');
      rethrow;
    }
  }

  // Update service request with borrowed items information (for funeral assistance)
  Future<void> updateServiceRequestWithBorrowedItems(
    String requestId,
    List<String> borrowedItemIds,
    String updatedDescription,
  ) async {
    try {
      await _firestore.collection('service_requests').doc(requestId).update({
        'description': updatedDescription,
        'borrowedItemIds': borrowedItemIds,
        'hasBorrowedItems': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Service request updated with borrowed items!');
    } catch (e) {
      print('❌ Error updating service request: $e');
      rethrow;
    }
  }

  // Synchronize service request status with borrowed items
  // When borrowed items are all returned, mark service as resolved
  Future<void> syncServiceRequestStatus(String requestId) async {
    try {
      final serviceDoc = await _firestore.collection('service_requests').doc(requestId).get();
      if (!serviceDoc.exists) return;
      
      final serviceData = serviceDoc.data()!;
      final borrowedItemIds = serviceData['borrowedItemIds'] as List<dynamic>?;
      
      if (borrowedItemIds == null || borrowedItemIds.isEmpty) return;
      
      // Check if all borrowed items are returned
      bool allReturned = true;
      for (var borrowId in borrowedItemIds) {
        final borrowDoc = await _firestore.collection('borrowed_supplies').doc(borrowId).get();
        if (borrowDoc.exists) {
          final status = borrowDoc.data()!['status'];
          if (status != 'returned') {
            allReturned = false;
            break;
          }
        }
      }
      
      // If all items returned and service is completed, mark as resolved
      if (allReturned && serviceData['status'] == 'completed') {
        await _firestore.collection('service_requests').doc(requestId).update({
          'status': 'resolved',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        // Send notification
        if (serviceData['userId'] != null) {
          await _notificationService.sendNotificationToUser(
            userId: serviceData['userId'],
            title: '✅ Service Request Resolved',
            body: 'Your funeral assistance request has been completed and all items have been returned.',
            type: 'service',
            actionId: requestId,
          );
        }
        
        print('✅ Service request marked as resolved!');
      }
    } catch (e) {
      print('❌ Error syncing service request status: $e');
      rethrow;
    }
  }
}
