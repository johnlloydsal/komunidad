import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'hotline.dart';
import 'lostandfound.dart';
import 'profile.dart';
import 'report_issue.dart';
import 'service_request.dart';
import 'community_news.dart';
import 'barangay_information.dart';
import 'view_my_reports.dart';
import 'widgets/app_logo.dart';
import 'widgets/barangay_background.dart';
import 'services/notification_service.dart';
import 'notifications_screen.dart';
import 'theme/app_theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String? _cachedIdStatus;

  @override
  void initState() {
    super.initState();
    _listenToIdVerificationStatus();
  }

  /// Listen to ID verification status changes for Google users
  void _listenToIdVerificationStatus() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Check if user signed in with Google
    final isGoogleUser = user.providerData.any(
      (provider) => provider.providerId == 'google.com',
    );

    if (isGoogleUser) {
      // Listen to the full user document to check ID submission AND admin approval
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen(
        (snapshot) {
          if (snapshot.exists && mounted) {
            final data = snapshot.data();
            // For Google users, check BOTH ID submission AND admin approval
            final accountStatus = data?['accountStatus'] as String? ?? 'pending';
            final approvalStatus = data?['approvalStatus'] as String? ?? 'pending';
            final hasSubmittedId = data?['submitId'] != null && (data!['submitId'] as String).isNotEmpty;
            
            // User is verified if they submitted ID AND admin approved (check BOTH status fields)
            final isApprovedAccount = accountStatus == 'approved' || accountStatus == 'active';
            final isApprovedApproval = approvalStatus == 'approved' || approvalStatus == 'active';
            final isVerified = hasSubmittedId && (isApprovedAccount || isApprovedApproval);
            final newStatus = isVerified ? 'approved' : hasSubmittedId ? 'pending' : 'not_submitted';
            
            final oldStatus = _cachedIdStatus;
            print('🔄 Google user status - hasSubmittedId: $hasSubmittedId, accountStatus: $accountStatus, approvalStatus: $approvalStatus, verified: $isVerified');
            
            if (_cachedIdStatus != newStatus) {
              setState(() {
                _cachedIdStatus = newStatus;
              });
              print('✅ Verification status updated to: $newStatus');
              
              // If just became approved, show success message
              if (isVerified && oldStatus != null && oldStatus != 'approved') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Account Approved! You now have full access to all features.'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 5),
                  ),
                );
              }
            }
          }
        },
        onError: (error) {
          print('⚠️ Error listening to user document: $error');
        },
      );
    }
  }

  /// Check if user can access features based on ID verification status
  /// Returns true if user can access, false otherwise
  Future<bool> _checkFeatureAccess() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    // Check if user signed in with Google
    final isGoogleUser = user.providerData.any(
      (provider) => provider.providerId == 'google.com',
    );

    print('\n🔐 === FEATURE ACCESS CHECK ===');
    print('User: ${user.email}');
    print('Is Google User: $isGoogleUser');

    // Non-Google users can access all features (admin approval handled in auth_wrapper)
    if (!isGoogleUser) {
      print('✅ NON-GOOGLE USER - Full access granted');
      print('================================\n');
      return true;
    }

    // For Google users, check BOTH ID submission AND admin approval
    String status;
    String? rejectionReason;
    if (_cachedIdStatus != null) {
      status = _cachedIdStatus!;
    } else {
      // Read from Firestore
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data();
      final accountStatus = data?['accountStatus'] as String? ?? 'pending';
      final approvalStatus = data?['approvalStatus'] as String? ?? 'pending';
      final hasSubmittedId = data?['submitId'] != null && (data!['submitId'] as String).isNotEmpty;
      rejectionReason = data?['rejectionReason'] as String?;
      
      // User is verified if they submitted ID AND admin approved (check BOTH status fields)
      final isApprovedAccount = accountStatus == 'approved' || accountStatus == 'active';
      final isApprovedApproval = approvalStatus == 'approved' || approvalStatus == 'active';
      final isVerified = hasSubmittedId && (isApprovedAccount || isApprovedApproval);
      status = isVerified ? 'approved' : hasSubmittedId ? 'pending' : 'not_submitted';
      
      // Override status to rejected if accountStatus is rejected
      if (accountStatus == 'rejected' || approvalStatus == 'rejected') {
        status = 'rejected';
      }
      
      print('📊 Firebase Data:');
      print('   accountStatus: "$accountStatus"');
      print('   approvalStatus: "$approvalStatus"');
      print('   hasSubmittedId: $hasSubmittedId');
      print('🎯 Verification Status: "$status"');
      if (rejectionReason != null) print('   ❌ Rejection reason: "$rejectionReason"');
    }
    
    if (status == 'approved') {
      print('✅ APPROVED - Access GRANTED');
      print('================================\n');
      return true;
    } else {
      print('❌ ACCESS BLOCKED - Status: "$status"');
      print('   💡 User needs to: ${status == 'not_submitted' ? 'Submit ID' : status == 'pending' ? 'Wait for admin approval' : 'Resubmit valid ID'}');
      print('================================\n');
      // Show dialog prompting user to wait for admin approval
      if (mounted) {
        _showIdVerificationDialog(status, rejectionReason: rejectionReason);
      }
      return false;
    }
  }

  /// Show dialog informing user about ID verification requirement
  void _showIdVerificationDialog(String status, {String? rejectionReason}) {
    String title;
    String message;
    String buttonText;
    IconData icon;
    Color iconColor;

    switch (status) {
      case 'not_submitted':
        title = 'ID Verification Required';
        message = 'Please complete your ID verification in your profile to access this feature.';
        buttonText = 'Go to Profile';
        icon = Icons.badge_outlined;
        iconColor = Colors.orange;
        break;
      case 'pending':
        title = 'Verification Pending';
        message = 'Your ID is being reviewed by our admin team. You will be able to access all features once approved.';
        buttonText = 'OK';
        icon = Icons.hourglass_empty;
        iconColor = Colors.blue;
        break;
      case 'rejected':
        title = 'Verification Rejected';
        message = rejectionReason ?? 'Your ID verification was not approved. Please submit a valid ID in your profile.';
        buttonText = 'Go to Profile';
        icon = Icons.cancel_outlined;
        iconColor = Colors.red;
        break;
      default:
        title = 'Access Restricted';
        message = 'Please complete ID verification to access this feature.';
        buttonText = 'Go to Profile';
        icon = Icons.lock_outlined;
        iconColor = Colors.grey;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(icon, color: iconColor, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
          actions: [
            if (status == 'not_submitted' || status == 'rejected')
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfilePage()),
                  );
                },
                child: Text(
                  buttonText,
                  style: const TextStyle(
                    color: Color(0xFF1E3A8A),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  buttonText,
                  style: const TextStyle(
                    color: Color(0xFF1E3A8A),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _onBottomNavTap(int index) async {
    setState(() {
      _selectedIndex = index;
    });

    // Navigate based on selected tab
    if (index == 0) {
      // Home - stay on current page
      return;
    }

    // Profile is always accessible (index 3)
    if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ProfilePage()),
      );
      return;
    }

    // Check verification for other features
    if (index == 1 || index == 2) {
      // Community News or Filter/Announcements - check access
      if (await _checkFeatureAccess()) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CommunityNewsPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        toolbarHeight: 0,
        automaticallyImplyLeading: false,
      ),
      body: BarangayBackground(
        child: SafeArea(
          child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 80),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🔹 Logo and Header with gradient background
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 40,
                  horizontal: 24,
                ),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(36),
                    bottomRight: Radius.circular(36),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Center the main content
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Logo with subtle animation
                          const AppLogo(size: 90, color: Colors.white),
                          const SizedBox(height: 20),
                          // App Name with gradient
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Colors.white, Color(0xFFFCD116)],
                            ).createShader(bounds),
                            child: const Text(
                              "KOMUNIDAD",
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Your Community, Connected",
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white.withOpacity(0.95),
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Notification Bell Icon
                    Positioned(
                      top: 0,
                      right: 0,
                      child: StreamBuilder<int>(
                        stream: NotificationService().getUnreadCount(),
                        builder: (context, snapshot) {
                          final unreadCount = snapshot.data ?? 0;
                          return Stack(
                            children: [
                              IconButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const NotificationsScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.notifications_outlined,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              if (unreadCount > 0)
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        unreadCount > 99 ? '99+' : unreadCount.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // 🔹 Services List
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Services",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "What would you like to do?",
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 20),

                    // Report Issue
                    _buildServiceCard(
                      context,
                      icon: Icons.report_problem,
                      title: "Report Issue",
                      onTap: () async {
                        if (await _checkFeatureAccess()) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ReportIssuePage(),
                            ),
                          );
                        }
                      },
                    ),

                    // Service Request
                    _buildServiceCard(
                      context,
                      icon: Icons.build,
                      title: "Service Request",
                      onTap: () async {
                        if (await _checkFeatureAccess()) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ServiceRequestPage(),
                            ),
                          );
                        }
                      },
                    ),

                    // Lost and Found
                    _buildServiceCard(
                      context,
                      icon: Icons.search,
                      title: "Lost and Found",
                      onTap: () async {
                        if (await _checkFeatureAccess()) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LostAndFoundPage(),
                            ),
                          );
                        }
                      },
                    ),

                    // Emergency Hotline
                    _buildServiceCard(
                      context,
                      icon: Icons.phone,
                      title: "Emergency Hotline",
                      onTap: () async {
                        if (await _checkFeatureAccess()) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HotlinePage(),
                            ),
                          );
                        }
                      },
                    ),

                    // Barangay Information
                    _buildServiceCard(
                      context,
                      icon: Icons.info,
                      title: "Barangay Information",
                      onTap: () async {
                        if (await _checkFeatureAccess()) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const BarangayInformationPage(),
                            ),
                          );
                        }
                      },
                    ),

                    // View Report & Borrowed Items
                    _buildServiceCard(
                      context,
                      icon: Icons.description,
                      title: "View My Reports & Borrowed Items",
                      onTap: () async {
                        if (await _checkFeatureAccess()) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ViewMyReportsPage(),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          backgroundColor: Colors.white,
          unselectedItemColor: Colors.grey[400],
          selectedItemColor: AppTheme.primaryColor,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          onTap: _onBottomNavTap,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: ''),
            BottomNavigationBarItem(icon: Icon(Icons.bookmark_rounded), label: ''),
            BottomNavigationBarItem(icon: Icon(Icons.filter_list_rounded), label: ''),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: ''),
          ],
        ),
      ),
    );
  }
}

// 🔹 Enhanced Service Card Widget
Widget _buildServiceCard(
  BuildContext context, {
  required IconData icon,
  required String title,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon container with gradient
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 18),
          // Title
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
                letterSpacing: 0.2,
              ),
            ),
          ),
          // Arrow with subtle background
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    ),
  );
}
