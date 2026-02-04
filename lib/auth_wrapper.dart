import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'FirsPage.dart';
import 'homepage.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Debug: Print current auth state
        print('🔍 Auth State: hasData=${snapshot.hasData}, user=${snapshot.data?.email}');

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
