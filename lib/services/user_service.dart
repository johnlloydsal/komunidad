import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create or update user profile in Firestore
  Future<void> createUserProfile({
    required String uid,
    required String email,
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      print('📄 Creating user profile for UID: $uid');
      print('📄 Email: $email, DisplayName: $displayName');

      await _firestore.collection('users').doc(uid).set({
        'email': email,
        'displayName': displayName ?? email.split('@')[0],
        'photoUrl': photoUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✅ User profile created successfully!');
    } catch (e) {
      print('❌ Error creating user profile: $e');
      rethrow;
    }
  }

  // Get user profile from Firestore
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String uid,
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    String? address,
  }) async {
    try {
      print('📝 Updating user profile for UID: $uid');

      Map<String, dynamic> updates = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (displayName != null) {
        updates['displayName'] = displayName;
        print('   - displayName: $displayName');
      }
      if (photoUrl != null) {
        updates['photoUrl'] = photoUrl;
        print('   - photoUrl: $photoUrl');
      }
      if (phoneNumber != null) {
        updates['phoneNumber'] = phoneNumber;
        print('   - phoneNumber: $phoneNumber');
      }
      if (address != null) {
        updates['address'] = address;
        print('   - address: $address');
      }

      // Use set with merge to create document if it doesn't exist
      await _firestore
          .collection('users')
          .doc(uid)
          .set(updates, SetOptions(merge: true));

      print('✅ User profile update successful!');
    } catch (e) {
      print('❌ Error updating user profile: $e');
      rethrow;
    }
  }

  // Stream user profile
  Stream<DocumentSnapshot> streamUserProfile(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }
}
