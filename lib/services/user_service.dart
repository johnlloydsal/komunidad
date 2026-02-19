import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create or update user profile in Firestore
  Future<void> createUserProfile({
    required String uid,
    required String email,
    String? displayName,
    String? photoUrl,
    String? username,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? houseStreet,
    String? zone,
    String? submitId,
    String? idImageUrl,
    String? accountStatus,
  }) async {
    try {
      print('📄 Creating user profile for UID: $uid');
      print('📄 Email: $email, DisplayName: $displayName');

      // Check if user already exists
      final existingDoc = await _firestore.collection('users').doc(uid).get();
      final existingData = existingDoc.data();
      
      // Generate username ONLY if not provided AND user doesn't exist yet
      String finalUsername;
      if (username != null) {
        finalUsername = username;
      } else if (existingData != null && existingData['username'] != null) {
        // Use existing username if user already exists
        finalUsername = existingData['username'];
        print('🔄 Using existing username: $finalUsername');
      } else {
        // Generate new username only for new users
        finalUsername = await _generateUniqueUsername(email, displayName);
        print('🆕 Generated new username: $finalUsername');
      }

      // Split displayName into firstName and lastName if provided
      String? finalFirstName = firstName;
      String? finalLastName = lastName;

      if (finalFirstName == null &&
          finalLastName == null &&
          displayName != null) {
        final nameParts = displayName.split(' ');
        if (nameParts.length > 1) {
          finalFirstName = nameParts.first;
          finalLastName = nameParts.skip(1).join(' ');
        } else {
          finalFirstName = displayName;
        }
      }

      Map<String, dynamic> userData = {
        'email': email,
        'displayName': displayName ?? email.split('@')[0],
        'photoUrl': photoUrl,
        'username': finalUsername,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Only set createdAt for new users
      if (existingData == null) {
        userData['createdAt'] = FieldValue.serverTimestamp();
      }

      if (finalFirstName != null) userData['firstName'] = finalFirstName;
      if (finalLastName != null) userData['lastName'] = finalLastName;
      if (phoneNumber != null) userData['phoneNumber'] = phoneNumber;
      if (houseStreet != null) userData['houseStreet'] = houseStreet;
      if (zone != null) userData['zone'] = zone;
      if (houseStreet != null || zone != null) {
        userData['address'] = [if (houseStreet != null) houseStreet, if (zone != null) zone]
            .join(', ');
      }
      if (submitId != null) userData['submitId'] = submitId;
      if (idImageUrl != null) userData['idImageUrl'] = idImageUrl;
      
      // Only set accountStatus if provided (don't overwrite existing status)
      if (accountStatus != null) {
        userData['accountStatus'] = accountStatus;
      } else if (existingData == null) {
        // Set default status only for new users
        userData['accountStatus'] = 'pending';
      }

      await _firestore
          .collection('users')
          .doc(uid)
          .set(userData, SetOptions(merge: true));

      print(
        '✅ User profile created successfully with username: $finalUsername',
      );
    } catch (e) {
      print('❌ Error creating user profile: $e');
      rethrow;
    }
  }

  // Generate unique username from email or displayName
  Future<String> _generateUniqueUsername(
    String email,
    String? displayName,
  ) async {
    // Start with email prefix or displayName
    String baseUsername =
        displayName?.toLowerCase().replaceAll(' ', '_') ??
        email.split('@')[0].toLowerCase().replaceAll('.', '_');

    // Remove special characters
    baseUsername = baseUsername.replaceAll(RegExp(r'[^a-z0-9_]'), '');

    // Ensure it starts with a letter or underscore
    if (baseUsername.isEmpty || !RegExp(r'^[a-z_]').hasMatch(baseUsername)) {
      baseUsername = 'user_$baseUsername';
    }

    // Check if username exists
    String username = baseUsername;
    int counter = 1;

    while (await _usernameExists(username)) {
      username = '${baseUsername}_$counter';
      counter++;
    }

    return username;
  }

  // Check if username exists
  Future<bool> _usernameExists(String username) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking username existence: $e');
      return false;
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
    String? username,
    String? firstName,
    String? lastName,
    String? submitId,
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
      if (username != null) {
        // Check if username is already taken by another user
        final existingUser = await _firestore
            .collection('users')
            .where('username', isEqualTo: username)
            .limit(1)
            .get();

        if (existingUser.docs.isNotEmpty && existingUser.docs.first.id != uid) {
          throw Exception('Username already taken');
        }

        updates['username'] = username;
        print('   - username: $username');
      }
      if (firstName != null) {
        updates['firstName'] = firstName;
        print('   - firstName: $firstName');
      }
      if (lastName != null) {
        updates['lastName'] = lastName;
        print('   - lastName: $lastName');
      }
      if (submitId != null) {
        updates['submitId'] = submitId;
        print('   - submitId: $submitId');
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

  // Check if user is admin
  Future<bool> isAdmin(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['isAdmin'] == true;
      }
      return false;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  // Get account status
  Future<String> getAccountStatus(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['accountStatus'] as String?;
        print('📋 Got status for $uid: ${status ?? "null (defaulting to pending)"}');
        return status ?? 'pending';
      }
      return 'pending';
    } catch (e) {
      print('Error getting account status: $e');
      return 'pending';
    }
  }

  // Stream account status with real-time updates
  Stream<String> streamAccountStatus(String uid) {
    print('🎧 Setting up real-time status stream for user: $uid');
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots(includeMetadataChanges: true) // Include metadata changes for faster updates
        .map((doc) {
      print('📡 Stream update received for $uid - exists: ${doc.exists}, hasPendingWrites: ${doc.metadata.hasPendingWrites}');
      
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['accountStatus'] as String?;
        print('📊 Stream emitting status for $uid: ${status ?? "null (defaulting to pending)"}');
        // Default to 'pending' if status is not set (safer than approved)
        return status ?? 'pending';
      }
      print('⚠️ User document does not exist for $uid in stream, defaulting to pending');
      return 'pending';
    });
  }

  // Get all pending users (admin only)
  Stream<List<Map<String, dynamic>>> streamPendingUsers() {
    return _firestore
        .collection('users')
        .where('accountStatus', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['uid'] = doc.id;
            return data;
          }).toList();
        });
  }

  // Approve user (admin only)
  Future<void> approveUser(String uid) async {
    try {
      print('🔄 Approving user: $uid');
      await _firestore.collection('users').doc(uid).update({
        'accountStatus': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ User $uid approved successfully');
      
      // Verify the update
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final status = doc.data()?['accountStatus'];
        print('✔️ Verified status in Firestore: $status');
      }
    } catch (e) {
      print('❌ Error approving user: $e');
      rethrow;
    }
  }

  // Reject user (admin only)
  Future<void> rejectUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'accountStatus': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ User $uid rejected successfully');
    } catch (e) {
      print('❌ Error rejecting user: $e');
      rethrow;
    }
  }

  // Get all users with their status (admin only)
  Stream<List<Map<String, dynamic>>> streamAllUsers() {
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['uid'] = doc.id;
            return data;
          }).toList();
        });
  }

  // Delete user and all their records (admin only)
  Future<void> deleteUserAndRecords(String uid) async {
    try {
      print('🗑️ Starting deletion of user $uid and all their records...');

      // Delete all user's reports
      final reportsSnapshot = await _firestore
          .collection('reports')
          .where('userId', isEqualTo: uid)
          .get();

      for (var doc in reportsSnapshot.docs) {
        await doc.reference.delete();
      }
      print('✅ Deleted ${reportsSnapshot.docs.length} reports');

      // Delete all user's service requests
      final serviceRequestsSnapshot = await _firestore
          .collection('service_requests')
          .where('userId', isEqualTo: uid)
          .get();

      for (var doc in serviceRequestsSnapshot.docs) {
        await doc.reference.delete();
      }
      print(
        '✅ Deleted ${serviceRequestsSnapshot.docs.length} service requests',
      );

      // Delete all user's lost items
      final lostItemsSnapshot = await _firestore
          .collection('lost_items')
          .where('userId', isEqualTo: uid)
          .get();

      for (var doc in lostItemsSnapshot.docs) {
        await doc.reference.delete();
      }
      print('✅ Deleted ${lostItemsSnapshot.docs.length} lost items');

      // Delete all user's found items
      final foundItemsSnapshot = await _firestore
          .collection('found_items')
          .where('userId', isEqualTo: uid)
          .get();

      for (var doc in foundItemsSnapshot.docs) {
        await doc.reference.delete();
      }
      print('✅ Deleted ${foundItemsSnapshot.docs.length} found items');

      // Delete user profile document from Firestore
      await _firestore.collection('users').doc(uid).delete();
      print('✅ Deleted user profile document');

      print('✅ User $uid and all their records deleted successfully');
    } catch (e) {
      print('❌ Error deleting user and records: $e');
      rethrow;
    }
  }
}
