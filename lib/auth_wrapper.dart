import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'FirsPage.dart';
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
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          if (_hasTimeout) {
            // If timeout, show error and go to FirstPage
            print('⏱️ Auth check timeout, showing FirstPage');
            return const FirstPage();
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
          return const FirstPage();
        }

        // Debug: Print current auth state
        print(
          '🔍 Auth State: hasData=${snapshot.hasData}, user=${snapshot.data?.email}',
        );

        // If user is logged in, check account status
        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;
          print('✅ User logged in: ${user.email}');

          // Check account status
          return StreamBuilder<String>(
            stream: _userService.streamAccountStatus(user.uid),
            builder: (context, statusSnapshot) {
              if (statusSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final accountStatus = statusSnapshot.data ?? 'pending';
              print('📋 Account status: $accountStatus');

              // Route based on status
              if (accountStatus == 'approved') {
                print('✅ Account approved, showing HomePage');
                return const HomePage();
              } else if (accountStatus == 'rejected') {
                print('❌ Account rejected, showing PendingApprovalPage');
                return const PendingApprovalPage();
              } else {
                // pending or any other status
                print('⏳ Account pending, showing PendingApprovalPage');
                return const PendingApprovalPage();
              }
            },
          );
        }

        // If not logged in, show FirstPage (landing page)
        print('❌ No user, showing FirstPage');
        return const FirstPage();
      },
    );
  }
}
