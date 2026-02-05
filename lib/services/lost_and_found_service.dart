import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LostAndFoundService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Submit a lost item (any user can report)
  Future<void> submitLostItem({
    required String item,
    required String notes,
    required String name,
    required String email,
    required String phone,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      await _firestore.collection('lost_items').add({
        'userId': user.uid,
        'userEmail': user.email,
        'item': item,
        'notes': notes,
        'name': name,
        'email': email,
        'phone': phone,
        'status': 'lost', // lost, found, claimed
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Lost item submitted successfully!');
    } catch (e) {
      print('❌ Error submitting lost item: $e');
      rethrow;
    }
  }

  // Submit a found item (admin only - this should be called with admin check)
  Future<void> submitFoundItem({
    required String item,
    required String notes,
    required String name,
    required String email,
    required String phone,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      await _firestore.collection('found_items').add({
        'userId': user.uid,
        'userEmail': user.email,
        'item': item,
        'notes': notes,
        'name': name,
        'email': email,
        'phone': phone,
        'status': 'found', // found, claimed
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Found item submitted successfully!');
    } catch (e) {
      print('❌ Error submitting found item: $e');
      rethrow;
    }
  }

  // Stream lost items for real-time updates (only user's own items or admin sees all)
  Stream<List<Map<String, dynamic>>> streamLostItems() async* {
    final user = _auth.currentUser;
    if (user == null) {
      yield [];
      return;
    }

    // Check if user is admin
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final isAdmin = userDoc.exists && (userDoc.data()?['isAdmin'] == true);

    yield* _firestore.collection('lost_items').snapshots().map((snapshot) {
      var items = snapshot.docs
          .map((doc) => {...doc.data(), 'id': doc.id})
          .toList();

      // Filter: only show user's own items unless admin
      if (!isAdmin) {
        items = items.where((item) => item['userId'] == user.uid).toList();
      }

      // Sort by createdAt in memory
      items.sort((a, b) {
        final aTime = a['createdAt'] as Timestamp?;
        final bTime = b['createdAt'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime); // descending order
      });

      return items;
    });
  }

  // Stream found items for real-time updates (only user's own items or admin sees all)
  Stream<List<Map<String, dynamic>>> streamFoundItems() async* {
    final user = _auth.currentUser;
    if (user == null) {
      yield [];
      return;
    }

    // Check if user is admin
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final isAdmin = userDoc.exists && (userDoc.data()?['isAdmin'] == true);

    yield* _firestore.collection('found_items').snapshots().map((snapshot) {
      var items = snapshot.docs
          .map((doc) => {...doc.data(), 'id': doc.id})
          .toList();

      // Filter: only show user's own items unless admin
      if (!isAdmin) {
        items = items.where((item) => item['userId'] == user.uid).toList();
      }

      // Sort by createdAt in memory
      items.sort((a, b) {
        final aTime = a['createdAt'] as Timestamp?;
        final bTime = b['createdAt'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime); // descending order
      });

      return items;
    });
  }

  // Update item status
  Future<void> updateItemStatus(
    String itemId,
    String status,
    bool isLost,
  ) async {
    try {
      final collection = isLost ? 'lost_items' : 'found_items';
      await _firestore.collection(collection).doc(itemId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error updating item status: $e');
      rethrow;
    }
  }

  // Delete item (admin only)
  Future<void> deleteItem(String itemId, bool isLost) async {
    try {
      final collection = isLost ? 'lost_items' : 'found_items';
      await _firestore.collection(collection).doc(itemId).delete();
    } catch (e) {
      print('❌ Error deleting item: $e');
      rethrow;
    }
  }
}
