import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'FirsPage.dart';
import 'homepage.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _hasTimeout = false;

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

        // If user is logged in, show HomePage
        if (snapshot.hasData && snapshot.data != null) {
          print('✅ User logged in, showing HomePage');
          return const HomePage();
        }

        // If not logged in, show FirstPage (landing page)
        print('❌ No user, showing FirstPage');
        return const FirstPage();
      },
    );
  }
}
