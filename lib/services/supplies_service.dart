import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SuppliesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Add a new supply item (admin only)
  Future<void> addSupply({
    required String name,
    required int quantity,
    String? description,
    String? category, // 'funeral', 'borrowing', 'event'
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      await _firestore.collection('supplies').add({
        'name': name,
        'quantity': quantity,
        'availableQuantity': quantity,
        'description': description,
        'category': category ?? 'borrowing',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Supply added successfully!');
    } catch (e) {
      print('❌ Error adding supply: $e');
      rethrow;
    }
  }

  // Get all supplies
  Stream<List<Map<String, dynamic>>> streamSupplies() {
    return _firestore
        .collection('supplies')
        .snapshots()
        .map(
          (snapshot) {
            var items = snapshot.docs
                .map((doc) => {...doc.data(), 'id': doc.id})
                .toList();
            // Sort by name in memory
            items.sort((a, b) => (a['name'] ?? '').toString().toLowerCase().compareTo((b['name'] ?? '').toString().toLowerCase()));
            return items;
          },
        );
  }

  // Get supplies by category
  Stream<List<Map<String, dynamic>>> streamSuppliesByCategory(String category) {
    return _firestore
        .collection('supplies')
        .where('category', isEqualTo: category)
        .snapshots()
        .map(
          (snapshot) {
            var items = snapshot.docs
                .map((doc) => {...doc.data(), 'id': doc.id})
                .toList();
            // Sort by name in memory to avoid composite index requirement
            items.sort((a, b) => (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()));
            return items;
          },
        );
  }

  // Borrow supplies
  Future<void> borrowSupply({
    required String supplyId,
    required int quantity,
    required String borrowerName,
    required String purpose,
    DateTime? returnDate,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Get current supply
      final supplyDoc = await _firestore.collection('supplies').doc(supplyId).get();
      if (!supplyDoc.exists) {
        throw Exception('Supply not found');
      }

      final supplyData = supplyDoc.data()!;
      final availableQty = supplyData['availableQuantity'] as int;

      if (availableQty < quantity) {
        throw Exception('Not enough supplies available');
      }

      // Get supply name with fallback for different field names
      final supplyName = supplyData['name'] ?? supplyData['itemName'] ?? supplyData['item'] ?? 'Unknown';

      // Create pending borrow request (admin must approve before qty is decremented)
      await _firestore.collection('borrowed_supplies').add({
        'supplyId': supplyId,
        'supplyName': supplyName,
        'userId': user.uid,
        'userEmail': user.email,
        'borrowerName': borrowerName,
        'quantity': quantity,
        'purpose': purpose,
        'requestedAt': FieldValue.serverTimestamp(),
        'borrowedAt': FieldValue.serverTimestamp(),
        'returnDate': returnDate != null ? Timestamp.fromDate(returnDate) : null,
        'returnedAt': null,
        'status': 'pending', // pending, borrowed, returned, rejected
      });

      print('✅ Borrow request submitted (pending admin approval)!');
    } catch (e) {
      print('❌ Error borrowing supply: $e');
      rethrow;
    }
  }

  // Approve a pending borrow request (admin only) — decrements qty
  Future<void> approveBorrow(String borrowedId) async {
    try {
      final borrowedDoc = await _firestore.collection('borrowed_supplies').doc(borrowedId).get();
      if (!borrowedDoc.exists) throw Exception('Borrow record not found');

      final borrowedData = borrowedDoc.data()!;
      final supplyId = borrowedData['supplyId'] as String;
      final quantity = borrowedData['quantity'] as int;

      // Check available qty before decrementing
      final supplyDoc = await _firestore.collection('supplies').doc(supplyId).get();
      if (!supplyDoc.exists) throw Exception('Supply not found');
      final availableQty = supplyDoc.data()!['availableQuantity'] as int;
      if (availableQty < quantity) throw Exception('Not enough supplies available');

      // Approve: set status to borrowed and decrement qty
      await _firestore.collection('borrowed_supplies').doc(borrowedId).update({
        'status': 'borrowed',
        'approvedAt': FieldValue.serverTimestamp(),
        'borrowedAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('supplies').doc(supplyId).update({
        'availableQuantity': availableQty - quantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Borrow request approved!');
    } catch (e) {
      print('❌ Error approving borrow: $e');
      rethrow;
    }
  }

  // Reject a pending borrow request (admin only)
  Future<void> rejectBorrow(String borrowedId, {String? reason}) async {
    try {
      final updateData = <String, dynamic>{
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
      };
      if (reason != null && reason.isNotEmpty) {
        updateData['rejectionReason'] = reason;
      }
      await _firestore.collection('borrowed_supplies').doc(borrowedId).update(updateData);
      print('✅ Borrow request rejected!');
    } catch (e) {
      print('❌ Error rejecting borrow: $e');
      rethrow;
    }
  }

  // Return borrowed supplies
  Future<void> returnSupply(String borrowedId, {String? feedback}) async {
    try {
      final borrowedDoc = await _firestore.collection('borrowed_supplies').doc(borrowedId).get();
      if (!borrowedDoc.exists) {
        throw Exception('Borrowed record not found');
      }

      final borrowedData = borrowedDoc.data()!;
      final supplyId = borrowedData['supplyId'] as String;
      final quantity = borrowedData['quantity'] as int;

      // Update borrowed record with feedback
      final updateData = {
        'returnedAt': FieldValue.serverTimestamp(),
        'status': 'returned',
      };
      
      if (feedback != null && feedback.isNotEmpty) {
        updateData['feedback'] = feedback;
        updateData['feedbackSubmittedAt'] = FieldValue.serverTimestamp();
      }

      await _firestore.collection('borrowed_supplies').doc(borrowedId).update(updateData);

      // Get current supply
      final supplyDoc = await _firestore.collection('supplies').doc(supplyId).get();
      if (supplyDoc.exists) {
        final availableQty = supplyDoc.data()!['availableQuantity'] as int;

        // Update available quantity
        await _firestore.collection('supplies').doc(supplyId).update({
          'availableQuantity': availableQty + quantity,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      print('✅ Supply returned successfully!');
    } catch (e) {
      print('❌ Error returning supply: $e');
      rethrow;
    }
  }

  // Get user's borrowed supplies
  Stream<List<Map<String, dynamic>>> streamUserBorrowedSupplies() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('borrowed_supplies')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map(
          (snapshot) {
            var items = snapshot.docs
                .map((doc) => {...doc.data(), 'id': doc.id})
                .toList();
            // Sort by borrowedAt in memory to avoid composite index requirement
            items.sort((a, b) {
              final aTime = a['borrowedAt'] as Timestamp?;
              final bTime = b['borrowedAt'] as Timestamp?;
              if (aTime == null && bTime == null) return 0;
              if (aTime == null) return 1;
              if (bTime == null) return -1;
              return bTime.compareTo(aTime); // descending order
            });
            return items;
          },
        );
  }

  // Update supply quantity (admin only)
  Future<void> updateSupplyQuantity(String supplyId, int newQuantity) async {
    try {
      final supplyDoc = await _firestore.collection('supplies').doc(supplyId).get();
      if (!supplyDoc.exists) {
        throw Exception('Supply not found');
      }

      final currentData = supplyDoc.data()!;
      final currentTotal = currentData['quantity'] as int;
      final currentAvailable = currentData['availableQuantity'] as int;
      final borrowed = currentTotal - currentAvailable;

      await _firestore.collection('supplies').doc(supplyId).update({
        'quantity': newQuantity,
        'availableQuantity': newQuantity - borrowed,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Supply quantity updated successfully!');
    } catch (e) {
      print('❌ Error updating supply quantity: $e');
      rethrow;
    }
  }

  // Delete supply (admin only)
  Future<void> deleteSupply(String supplyId) async {
    try {
      await _firestore.collection('supplies').doc(supplyId).delete();
      print('✅ Supply deleted successfully!');
    } catch (e) {
      print('❌ Error deleting supply: $e');
      rethrow;
    }
  }
}
