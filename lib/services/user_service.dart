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
  }) async {
    try {
      print('📄 Creating user profile for UID: $uid');
      print('📄 Email: $email, DisplayName: $displayName');

      // Generate username if not provided
      String finalUsername =
          username ?? await _generateUniqueUsername(email, displayName);

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
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (finalFirstName != null) userData['firstName'] = finalFirstName;
      if (finalLastName != null) userData['lastName'] = finalLastName;
      if (phoneNumber != null) userData['phoneNumber'] = phoneNumber;

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
}
