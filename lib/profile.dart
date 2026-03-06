import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_wrapper.dart';
import 'homepage.dart';
import 'community_news.dart';
import 'theme/app_theme.dart';
import 'services/auth_service.dart';
import 'services/user_service.dart';
import 'history.dart';
import 'terms_and_conditions.dart';
import 'submit_id_verification.dart';
import 'utils/password_validator.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final int _selectedIndex = 3; // Profile tab is selected

  void _onBottomNavTap(int index) {
    if (index == _selectedIndex) return;

    Widget destination;
    if (index == 0) {
      destination = const HomePage();
    } else if (index == 1 || index == 2) {
      destination = const CommunityNewsPage();
    } else if (index == 3) {
      return; // Already on profile
    } else {
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    // First check auth state to handle logout properly
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // If user logged out, navigate to FirstPage
        if (authSnapshot.connectionState == ConnectionState.active && 
            (authSnapshot.data == null || !authSnapshot.hasData)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const AuthWrapper()),
                (route) => false,
              );
            }
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authSnapshot.data;
        if (user == null) {
          return const Scaffold(body: Center(child: Text('Not logged in')));
        }

        // Now stream user profile data
        return StreamBuilder<DocumentSnapshot>(
          stream: _userService.streamUserProfile(user.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // Handle errors - especially permission-denied after logout
            if (snapshot.hasError) {
              print('❌ Profile stream error: ${snapshot.error}');
              
              // If permission denied, user likely logged out - go to FirstPage
              if (snapshot.error.toString().contains('permission-denied')) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const AuthWrapper()),
                      (route) => false,
                    );
                  }
                });
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 60, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text('Error loading profile'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => const AuthWrapper()),
                            (route) => false,
                          );
                        },
                        child: const Text('Go to Home'),
                      ),
                    ],
                  ),
                ),
              );
            }

            Map<String, dynamic>? userData;
            if (snapshot.hasData && snapshot.data!.exists) {
              userData = snapshot.data!.data() as Map<String, dynamic>?;
            }

            String displayName =
                userData?['displayName'] ??
                user.displayName ??
                user.email?.split('@')[0] ??
                'User';
            String email = userData?['email'] ?? user.email ?? 'No email';
            String? username = userData?['username'];
            String? photoUrl = userData?['photoUrl'] ?? user.photoURL;

            // Get account creation date
            String memberSince = user.metadata.creationTime != null
                ? _formatDate(user.metadata.creationTime!)
                : 'Recently joined';

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            toolbarHeight: 80,
            automaticallyImplyLeading: false,
            leading: null,
            centerTitle: true,
            title: const Text(
              "My Profile",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // 🔹 Profile Header
                Center(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 55,
                            backgroundColor: AppTheme.primaryColor,
                            backgroundImage: photoUrl != null
                                ? NetworkImage(photoUrl)
                                : null,
                            child: photoUrl == null
                                ? const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          // Show exclamation mark if ID not verified
                          StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .snapshots()
                                .handleError((error) {
                                  print('⚠️ Error reading user verification status: $error');
                                  return null;
                                }),
                            builder: (context, snapshot) {
                              final isGoogleUser = user.providerData.any(
                                (provider) => provider.providerId == 'google.com',
                              );
                              
                              if (isGoogleUser && snapshot.hasData && snapshot.data!.exists) {
                                final data = snapshot.data!.data() as Map<String, dynamic>?;
                                // For Google users, show badge if ID not submitted OR not approved
                                final accountStatus = data?['accountStatus'] as String? ?? 'pending';
                                final hasSubmittedId = data?['submitId'] != null && (data!['submitId'] as String).isNotEmpty;
                                final showBadge = !hasSubmittedId || (accountStatus != 'approved' && accountStatus != 'active');
                                
                                if (showBadge) {
                                  return Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.orange,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.priority_high,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  );
                                }
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (username != null && username.isNotEmpty) ...[
                        Text(
                          '@$username',
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        email,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        memberSince,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // � ID Verification Card - Real-time for Google Users
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .snapshots(),
                  builder: (context, verifySnapshot) {
                    print('\n🔍 === VERIFICATION CARD DEBUG ===');
                    print('User UID: ${user.uid}');
                    print('ConnectionState: ${verifySnapshot.connectionState}');
                    print('Snapshot hasData: ${verifySnapshot.hasData}');
                    print('Snapshot data exists: ${verifySnapshot.data?.exists}');
                    
                    // Check if user is Google user
                    final isGoogleUser = user.providerData.any((p) => p.providerId == 'google.com');
                    print('👤 Is Google User: $isGoogleUser');
                    print('   Provider IDs: ${user.providerData.map((p) => p.providerId).toList()}');
                    
                    // If not a Google user, never show card
                    if (!isGoogleUser) {
                      print('❌ Not a Google user - hiding card');
                      print('=================================\n');
                      return const SizedBox.shrink();
                    }
                    
                    // For Google users: ALWAYS show card during loading OR if not approved
                    // This ensures new users see the card even while Firestore data loads
                    
                    // Show loading state briefly if data hasn't arrived yet
                    if (verifySnapshot.connectionState == ConnectionState.waiting) {
                      print('⏳ Still loading Firestore data - SHOWING CARD (default pending)');
                      print('=================================\n');
                      // Don't return loading indicator - just show the card immediately
                    }
                    
                    // Default values - assume pending if no data (NEW USER scenario)
                    String accountStatus = 'pending';
                    String approvalStatus = 'pending';
                    bool hasSubmittedId = false;
                    
                    // Read real-time data from Firestore (if available)
                    if (verifySnapshot.hasData && verifySnapshot.data!.exists) {
                      final data = verifySnapshot.data!.data() as Map<String, dynamic>?;
                      if (data != null) {
                        accountStatus = data['accountStatus'] as String? ?? 'pending';
                        approvalStatus = data['approvalStatus'] as String? ?? 'pending';
                        hasSubmittedId = data['submitId'] != null && (data['submitId'] as String).isNotEmpty;
                        
                        print('📊 Firebase Data LOADED:');
                        print('   accountStatus: "$accountStatus"');
                        print('   approvalStatus: "$approvalStatus"');
                        print('   submitId: ${data['submitId']}');
                        print('   hasSubmittedId: $hasSubmittedId');
                      } else {
                        print('⚠️ Document exists but data is null - using defaults (pending)');
                      }
                    } else {
                      print('⚠️ No Firebase data yet (new user OR loading) - using defaults (pending)');
                    }
                    
                    // Check status
                    final isAccountApproved = accountStatus == 'approved' || accountStatus == 'active';
                    final isApprovalApproved = approvalStatus == 'approved' || approvalStatus == 'active';
                    final isApproved = isAccountApproved || isApprovalApproved;
                    final isRejected = accountStatus == 'rejected' || approvalStatus == 'rejected';
                    
                    // Get rejection reason if available
                    String? rejectionReason;
                    if (verifySnapshot.hasData && verifySnapshot.data!.exists) {
                      final data = verifySnapshot.data!.data() as Map<String, dynamic>?;
                      if (data != null) {
                        rejectionReason = data['rejectionReason'] as String?;
                      }
                    }
                    
                    print('✅ Approval Status:');
                    print('   accountStatus="$accountStatus" → approved? $isAccountApproved, rejected? $isRejected');
                    print('   approvalStatus="$approvalStatus" → approved? $isApprovalApproved');
                    print('   COMBINED approved? $isApproved, rejected? $isRejected');
                    if (rejectionReason != null) print('   ❌ Rejection reason: "$rejectionReason"');
                    
                    final shouldShow = !isApproved; // Show if NOT approved
                    print('🎯 FINAL DECISION:');
                    print('   Google user: ✅ $isGoogleUser');
                    print('   Is approved: ${isApproved ? "✅" : "❌"} $isApproved');
                    print('   Is rejected: ${isRejected ? "❌" : "✅"} $isRejected');
                    print('   SHOW CARD: ${shouldShow ? "✅ YES" : "❌ NO"}');
                    print('=================================\n');
                    
                    // HIDE card ONLY if approved
                    if (isApproved) {
                      print('🚫 User is approved - hiding card\n');
                      return const SizedBox.shrink();
                    }
                    
                    print('✅ RENDERING ${isRejected ? "RED REJECTION" : "ORANGE PENDING"} CARD NOW!\n');
                    
                    // SHOW card for Google users who are pending or rejected
                    
                    // Determine card color and message based on status
                    final cardGradient = isRejected
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFDC2626), Color(0xFFEF4444)], // Red gradient for rejected
                          )
                        : LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: hasSubmittedId 
                                ? [Colors.orange, Colors.deepOrange] // Orange for pending approval
                                : [Colors.red, Colors.redAccent], // Red for not submitted
                          );
                    
                    final cardTitle = isRejected
                        ? 'Verification Rejected'
                        : hasSubmittedId
                            ? 'Verification Required'
                            : 'Verification Required';
                    
                    final cardSubtitle = isRejected
                        ? (rejectionReason ?? 'Please resubmit your ID with valid information')
                        : hasSubmittedId
                            ? 'Waiting for admin approval'
                            : 'Tap to submit your ID';
                    
                    final cardIcon = isRejected
                        ? Icons.cancel_outlined
                        : hasSubmittedId
                            ? Icons.hourglass_empty
                            : Icons.shield_outlined;
                      
                      return Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (!hasSubmittedId || isRejected) {
                                // Allow submission for new users OR rejected users (resubmission)
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SubmitIdVerificationPage(),
                                  ),
                                );
                              } else {
                                // Already submitted and pending - show info
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Your ID is under review by admin'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: cardGradient,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isRejected ? Colors.red : hasSubmittedId ? Colors.orange : Colors.red).withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.3),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      cardIcon,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(width: 18),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          cardTitle,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          cardSubtitle,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.white,
                                          ),
                                          maxLines: isRejected ? 3 : 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                      );
                  },
                ),

                // 🔹 Account Information
                _buildProfileSection(
                  context: context,
                  userData: userData,
                  icon: Icons.person,
                  title: "Account Information",
                  subtitle: "View and manage your account details",
                  onTap: () {
                    _showEditAccountDialog(context, userData, user);
                  },
                ),

                // 🔹 Password
                _buildProfileSection(
                  context: context,
                  userData: userData,
                  icon: Icons.lock,
                  title: "Password",
                  subtitle: "Change your password",
                  onTap: () {
                    _showChangePasswordDialog(context, user);
                  },
                ),

                // 🔹 History
                _buildProfileSection(
                  context: context,
                  userData: userData,
                  icon: Icons.history,
                  title: "History",
                  subtitle: "View your activity history",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HistoryPage(),
                      ),
                    );
                  },
                ),

                // 🔹 Terms and Conditions
                _buildProfileSection(
                  context: context,
                  userData: userData,
                  icon: Icons.description,
                  title: "Terms and Conditions",
                  subtitle: "Read our terms and policies",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TermsAndConditionsPage(),
                      ),
                    );
                  },
                ),

                // 🔹 Admin Section (only visible to admins)
                FutureBuilder<bool>(
                  future: _userService.isAdmin(user.uid),
                  builder: (context, adminSnapshot) {
                    if (adminSnapshot.data == true) {
                      return Column(
                        children: [
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.purple,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'ADMIN PANEL',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                const SizedBox(height: 30),

                // 🔹 Logout Button
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Confirm Logout"),
                        content: const Text("Are you sure you want to logout?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(context); // Close dialog

                              try {
                                // Sign out from Firebase
                                await _authService.signOut();

                                if (!mounted) return;

                                // Navigate to AuthWrapper and clear all routes
                                // AuthWrapper will automatically show FirstPage
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (context) => const AuthWrapper(),
                                  ),
                                  (route) => false,
                                );
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Logout failed: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            child: const Text(
                              "Logout",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout, color: Colors.white),
                        SizedBox(width: 10),
                        Text(
                          "Logout",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            backgroundColor: Colors.white,
            unselectedItemColor: Colors.grey,
            selectedItemColor: AppTheme.primaryColor,
            type: BottomNavigationBarType.fixed,
            onTap: _onBottomNavTap,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
              BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: ''),
              BottomNavigationBarItem(icon: Icon(Icons.filter_list), label: ''),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
            ],
          ),
        );
        },
      );
    },
  );
}

  String _formatDate(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return 'Member since ${months[date.month - 1]} ${date.year}';
  }

  void _showEditAccountDialog(
    BuildContext context,
    Map<String, dynamic>? userData,
    User user,
  ) {
    // Split display name into first and last name
    String fullName =
        userData?['displayName'] ?? user.displayName ?? '';
    List<String> nameParts = fullName.split(' ');
    String firstName = nameParts.isNotEmpty ? nameParts[0] : '';
    String lastName = nameParts.length > 1
        ? nameParts.sublist(1).join(' ')
        : '';

    final firstNameController = TextEditingController(text: firstName);
    final lastNameController = TextEditingController(text: lastName);
    final usernameController = TextEditingController(
      text: userData?['username'] ?? '',
    );
    final phoneController = TextEditingController(
      text: userData?['phoneNumber'] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Account Information"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: firstNameController,
                decoration: const InputDecoration(
                  labelText: "First Name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: lastNameController,
                decoration: const InputDecoration(
                  labelText: "Last Name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: "Username",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Phone Number",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.email, color: Colors.grey, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        user.email ?? 'No email',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              try {
                String displayName =
                    '${firstNameController.text.trim()} ${lastNameController.text.trim()}'
                        .trim();

                // Update Firebase Auth display name
                await user.updateDisplayName(displayName);
                await user.reload();

                // Update Firestore
                await _userService.updateUserProfile(
                  uid: user.uid,
                  displayName: displayName,
                  phoneNumber: phoneController.text.trim(),
                );

                // Update username separately if needed
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .update({
                      'username': usernameController.text.trim(),
                      'firstName': firstNameController.text.trim(),
                      'lastName': lastNameController.text.trim(),
                    });

                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Profile updated successfully!"),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Error: ${e.toString()}"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, User user) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    int passwordStrength = 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Change Password"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Current Password",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  onChanged: (value) {
                    setState(() {
                      passwordStrength = PasswordValidator.getStrength(value);
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: "New Password",
                    border: OutlineInputBorder(),
                  ),
                ),
                if (newPasswordController.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: passwordStrength / 4,
                    backgroundColor: Colors.grey[300],
                    color: Color(
                      int.parse(
                        '0xFF${PasswordValidator.getStrengthColor(passwordStrength)}',
                      ),
                    ),
                    minHeight: 8,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Strength: ${PasswordValidator.getStrengthLabel(passwordStrength)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(
                        int.parse(
                          '0xFF${PasswordValidator.getStrengthColor(passwordStrength)}',
                        ),
                      ),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...PasswordValidator.getRequirements(newPasswordController.text)
                      .map((req) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Icon(
                                  req.isMet ? Icons.check_circle : Icons.cancel,
                                  color: req.isMet ? Colors.green : Colors.grey,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    req.label,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ],
                const SizedBox(height: 10),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Confirm New Password",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                if (newPasswordController.text !=
                    confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Passwords do not match"),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Validate password strength
                final validationError = PasswordValidator.validate(
                  newPasswordController.text,
                );
                if (validationError != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(validationError),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  // Re-authenticate user
                  final credential = EmailAuthProvider.credential(
                    email: user.email!,
                    password: currentPasswordController.text,
                  );
                  await user.reauthenticateWithCredential(credential);

                  // Update password
                  await user.updatePassword(newPasswordController.text);

                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Password changed successfully!"),
                      backgroundColor: Colors.green,
                    ),
                  );
                } on FirebaseAuthException catch (e) {
                  if (!mounted) return;
                  String errorMessage = 'Error changing password';
                  if (e.code == 'wrong-password') {
                    errorMessage = 'Current password is incorrect';
                  } else if (e.code == 'weak-password') {
                    errorMessage = 'New password is too weak';
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(errorMessage),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text("Change Password"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection({
    required BuildContext context,
    required Map<String, dynamic>? userData,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final color = iconColor ?? AppTheme.primaryColor;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
