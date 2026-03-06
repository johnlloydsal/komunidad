import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login.dart';
import 'homepage.dart';
import 'pending_approval.dart';
import 'services/user_service.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _hasTimeout = false;
  final UserService _userService = UserService();
  String? _cachedStatus;

  @override
  void initState() {
    super.initState();
    // Set a timeout to prevent infinite loading
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          _hasTimeout = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    print('🔄 AuthWrapper building...');
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          if (_hasTimeout) {
            // If timeout, show error and go to FirstPage
            print('⏱️ Auth check timeout, showing FirstPage');
            return const LoginPage();
          }
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading...'),
                ],
              ),
            ),
          );
        }

        // Handle errors
        if (snapshot.hasError) {
          print('❌ Auth error: ${snapshot.error}');
          return const LoginPage();
        }

        // Debug: Print current auth state
        print(
          '🔍 Auth State: hasData=${snapshot.hasData}, user=${snapshot.data?.email}',
        );

        // If user is logged in, check account status
        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;
          print('✅ User logged in: ${user.email}');

          // Check if user is a Google user (bypasses admin approval)
          final isGoogleUser = user.providerData.any(
            (provider) => provider.providerId == 'google.com',
          );

          if (isGoogleUser) {
            print('🌐 Google user detected - allowing homepage access');
            
            // For Google users, they can access homepage but features are restricted
            // until admin approves them (accountStatus = 'approved')
            return const HomePage();
          }

          // Non-Google users - check admin approval status
          return StreamBuilder<String>(
            stream: _userService.streamAccountStatus(user.uid),
            builder: (context, statusSnapshot) {
              // Add more detailed logging
              print('📊 Status snapshot - connectionState: ${statusSnapshot.connectionState}, hasData: ${statusSnapshot.hasData}, data: ${statusSnapshot.data}');
              
              // Don't show loading if we have cached data
              if (statusSnapshot.connectionState == ConnectionState.waiting && _cachedStatus == null) {
                print('⏳ Initial loading of account status...');
                return const Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Checking account status...'),
                      ],
                    ),
                  ),
                );
              }

              if (statusSnapshot.hasError) {
                print('❌ Status stream error: ${statusSnapshot.error}');
                // Default to pending on error
                return const PendingApprovalPage();
              }

              // Get current status from stream or use cached
              final accountStatus = statusSnapshot.data ?? _cachedStatus ?? 'pending';
              
              // Update cached status if we have new data
              if (statusSnapshot.hasData && statusSnapshot.data != _cachedStatus) {
                _cachedStatus = statusSnapshot.data;
                print('🔄 Status changed from $_cachedStatus to ${statusSnapshot.data}');
              }
              
              print('📋 Current account status: $accountStatus');

              // Route based on status with immediate rebuild
              // Accept both 'approved' and 'active' (for backward compatibility)
              if (accountStatus == 'approved' || accountStatus == 'active') {
                print('✅ Account approved/active, showing HomePage');
                // Force rebuild by using a key
                return const HomePage(key: ValueKey('homepage_approved'));
              } else if (accountStatus == 'rejected') {
                print('❌ Account rejected, showing PendingApprovalPage');
                return const PendingApprovalPage(key: ValueKey('pending_rejected'));
              } else {
                // pending or any other status
                print('⏳ Account pending, showing PendingApprovalPage');
                return const PendingApprovalPage(key: ValueKey('pending_waiting'));
              }
            },
          );
        }

        // If not logged in, show FirstPage (landing page)
        print('❌ No user, showing FirstPage');
        return const LoginPage();
      },
    );
  }
}
