import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_wrapper.dart';
import 'services/auth_service.dart';
import 'widgets/app_logo.dart';
import 'widgets/barangay_background.dart';
import 'forgot_password.dart';
import 'theme/app_theme.dart';
import 'utils/page_transitions.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool isLoading = false;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: AnimatedBarangayBackground(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor.withOpacity(0.95),
                  AppTheme.primaryDark.withOpacity(0.9),
                  AppTheme.accentRed.withOpacity(0.1),
                ],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                children: [
                  const SizedBox(height: 60),
                  // Logo at top
                  const AppLogo(size: 90, color: Colors.white),
                  const SizedBox(height: 60),
                  // Main content area with glassmorphism
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(36),
                        topRight: Radius.circular(36),
                      ),
                    ),
                    child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        // Login heading with gradient
                        ShaderMask(
                          shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
                          child: const Text(
                            "Login",
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Making lives better",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 15,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Username Field
                        TextField(
                          controller: usernameController,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          textCapitalization: TextCapitalization.none,
                          decoration: InputDecoration(
                            hintText: "Username",
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            filled: true,
                            fillColor: AppTheme.primaryColor.withOpacity(0.03),
                            prefixIcon: Icon(
                              Icons.person_outline_rounded,
                              color: AppTheme.primaryColor.withOpacity(0.6),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: AppTheme.primaryColor,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Password Field
                        TextField(
                          controller: passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          autocorrect: false,
                          enableSuggestions: false,
                          decoration: InputDecoration(
                            hintText: "Password",
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            filled: true,
                            fillColor: AppTheme.primaryColor.withOpacity(0.03),
                            prefixIcon: Icon(
                              Icons.lock_outline_rounded,
                              color: AppTheme.primaryColor.withOpacity(0.6),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppTheme.primaryColor.withOpacity(0.6),
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: AppTheme.primaryColor,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Forgot Password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              context.pushWithFade(const ForgotPasswordPage());
                            },
                            child: Text(
                              "Forgot Password ?",
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Login Button with gradient
                        SizedBox(
                          width: double.infinity,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                            onPressed: isLoading
                                ? null
                                : () async {
                                    String usernameOrEmail = usernameController
                                        .text
                                        .trim();
                                    String password = passwordController.text;

                                    if (usernameOrEmail.isEmpty ||
                                        password.isEmpty) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Please enter username and password",
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }

                                    setState(() {
                                      isLoading = true;
                                    });

                                    try {
                                      String email;

                                      // Check if input contains @ (is email)
                                      if (usernameOrEmail.contains('@')) {
                                        email = usernameOrEmail;
                                        print(
                                          '🔐 Attempting login with email: $email',
                                        );
                                      } else {
                                        // It's a username, look up the email
                                        print(
                                          '🔍 Looking up email for username: $usernameOrEmail',
                                        );

                                        final userQuery =
                                            await FirebaseFirestore.instance
                                                .collection('users')
                                                .where(
                                                  'username',
                                                  isEqualTo: usernameOrEmail,
                                                )
                                                .limit(1)
                                                .get();

                                        if (userQuery.docs.isEmpty) {
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                "Username not found",
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                          setState(() {
                                            isLoading = false;
                                          });
                                          return;
                                        }

                                        email =
                                            userQuery.docs.first.data()['email']
                                                as String;
                                        print(
                                          '✅ Found email: $email for username: $usernameOrEmail',
                                        );
                                      }

                                      // Try to sign in with email and password
                                      await _authService
                                          .signInWithEmailPassword(
                                            email,
                                            password,
                                          );

                                      if (!mounted) return;
                                      print('✅ Login successful!');

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Login Successful! Welcome! 🎉",
                                          ),
                                          backgroundColor: Colors.green,
                                          duration: Duration(seconds: 1),
                                        ),
                                      );

                                      // Navigate to AuthWrapper which will handle routing based on account status
                                      await Future.delayed(
                                        const Duration(milliseconds: 500),
                                      );
                                      if (!mounted) return;
                                      Navigator.of(context).pushAndRemoveUntil(
                                        MaterialPageRoute(
                                          builder: (context) => const AuthWrapper(),
                                        ),
                                        (route) => false,
                                      );
                                    } on FirebaseAuthException catch (e) {
                                      if (!mounted) return;
                                      print(
                                        '❌ FirebaseAuth error: ${e.code} - ${e.message}',
                                      );

                                      String errorMessage = 'An error occurred';

                                      if (e.code == 'user-not-found') {
                                        errorMessage =
                                            'No account found. Please check your username or register first.\n\nTip: If you signed up with Google, use "Continue with Google" instead.';
                                      } else if (e.code == 'wrong-password') {
                                        errorMessage =
                                            'Incorrect password.\n\nNote: If you signed up with Google, you don\'t have a password. Use "Continue with Google" instead.';
                                      } else if (e.code == 'invalid-email') {
                                        errorMessage = 'Invalid email address';
                                      } else if (e.code ==
                                          'invalid-credential') {
                                        errorMessage =
                                            'Incorrect username or password.\n\nNote: If you signed up with Google, please use "Continue with Google" instead.';
                                      } else if (e.code ==
                                          'too-many-requests') {
                                        errorMessage =
                                            'Too many failed attempts. Please try again later.';
                                      } else {
                                        errorMessage =
                                            e.message ??
                                            'Login failed. Please check your credentials.';
                                      }

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(errorMessage),
                                          backgroundColor: Colors.red,
                                          duration: const Duration(seconds: 3),
                                        ),
                                      );
                                    } catch (e) {
                                      if (!mounted) return;
                                      print('❌ General Error: $e');
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'An unexpected error occurred: ${e.toString()}',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    } finally {
                                      if (mounted) {
                                        setState(() {
                                          isLoading = false;
                                        });
                                      }
                                    }
                                  },
                              child: isLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Text(
                                      "Login",
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Signup Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(context, '/register');
                              },
                              child: ShaderMask(
                                shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
                                child: const Text(
                                  "Signup",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        // OR Divider
                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.grey[300])),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Text(
                                "Or continue with",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: Colors.grey[300])),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Google Sign-In Button
                        Center(
                          child: InkWell(
                            onTap: isLoading ? null : _handleGoogleSignIn,
                            borderRadius: BorderRadius.circular(30),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.primaryColor.withOpacity(0.2),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withOpacity(0.1),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                'assets/images/gagle.png',
                                height: 26,
                                width: 26,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    ),
  ),
);
  }

  // Google Sign-In Handler
  Future<void> _handleGoogleSignIn() async {
    setState(() {
      isLoading = true;
    });

    try {
      print('🔐 Starting Google Sign-In...');
      final userCredential = await _authService.signInWithGoogle();

      if (userCredential != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Welcome ${userCredential.user?.displayName ?? 'User'}! 🎉",
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );

        // Navigate to AuthWrapper which will handle routing
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const AuthWrapper(),
          ),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String errorMessage = 'An error occurred';

        switch (e.code) {
          case 'account-exists-with-different-credential':
            errorMessage = 'An account already exists with this email';
            break;
          case 'invalid-credential':
            errorMessage = 'Invalid credentials';
            break;
          case 'operation-not-allowed':
            errorMessage = 'Google Sign-In is not enabled';
            break;
          case 'user-disabled':
            errorMessage = 'This user has been disabled';
            break;
          case 'user-not-found':
            errorMessage = 'No user found';
            break;
          case 'wrong-password':
            errorMessage = 'Wrong password';
            break;
          default:
            errorMessage = e.message ?? 'Authentication failed';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('❌ Google Sign-In error: $e');
      if (mounted) {
        String errorMessage =
            'Google Sign-In failed. Please use Email & Password instead.';

        // Check for specific error codes
        if (e.toString().contains('ApiException: 10')) {
          errorMessage =
              'Google Sign-In is not configured for this device. Please use Email & Password login.';
        } else if (e.toString().contains('SIGN_IN_CANCELLED')) {
          errorMessage = 'Sign-in cancelled';
        } else if (e.toString().contains('network')) {
          errorMessage = 'Network error. Please check your connection.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
}
