import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart';
import 'homepage.dart';
import 'widgets/app_logo.dart';

class PendingApprovalPage extends StatefulWidget {
  const PendingApprovalPage({super.key});

  @override
  State<PendingApprovalPage> createState() => _PendingApprovalPageState();
}

class _PendingApprovalPageState extends State<PendingApprovalPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<DocumentSnapshot>? _statusSubscription;
  String _currentStatus = 'pending';
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _checkStatusNow(); // Check immediately
    _listenToApprovalStatus();
    // Also poll status every 5 seconds as backup
    _startBackupStatusCheck();
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    super.dispose();
  }

  // Backup status check in case stream fails
  void _startBackupStatusCheck() {
    Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      final user = _auth.currentUser;
      if (user != null) {
        try {
          final doc = await _firestore.collection('users').doc(user.uid).get();
          final status = doc.data()?['accountStatus'] ?? 'pending';
          print('🔄 Backup check - Current status: $status');
          
          if (status == 'approved' || status == 'active') {
            print('✅ Backup check detected approval! Navigating to HomePage');
            timer.cancel();
            _statusSubscription?.cancel();
            
            if (mounted) {
              // Navigate directly to HomePage
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const HomePage()),
                (route) => false,
              );
            }
          }
        } catch (e) {
          print('❌ Backup status check error: $e');
        }
      }
    });
  }

  // Listen to real-time approval status changes
  void _listenToApprovalStatus() {
    final user = _auth.currentUser;
    if (user != null) {
      print('👂 Setting up status listener for user: ${user.uid}');
      _statusSubscription = _firestore
          .collection('users')
          .doc(user.uid)
          .snapshots(includeMetadataChanges: true) // Include metadata for instant updates
          .listen(
        (snapshot) async {
          if (!mounted) return;
          
          print('📩 Received status update - exists: ${snapshot.exists}, data: ${snapshot.data()}, fromCache: ${snapshot.metadata.isFromCache}, hasPendingWrites: ${snapshot.metadata.hasPendingWrites}');
          
          final status = snapshot.data()?['accountStatus'] ?? 'pending';
          print('📊 Current status: $status');
          
          // Update UI state
          if (mounted) {
            setState(() {
              _currentStatus = status;
            });
          }
          
          if (status == 'approved' || status == 'active') {
            print('✅✅✅ STATUS APPROVED! Navigating to HomePage');
            // Cancel subscription to prevent multiple navigations
            _statusSubscription?.cancel();
            
            if (mounted) {
              // Navigate directly to HomePage
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const HomePage()),
                (route) => false,
              );
            }
          } else if (status == 'rejected') {
            print('❌ Status is rejected');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Your account was rejected. Please contact support.',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } else {
            print('⏳ Status is still pending');
          }
        },
        onError: (error) {
          print('❌ Stream error: $error');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error monitoring status: $error'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      );
    }
  }

  // Check current status immediately
  Future<void> _checkStatusNow() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        final status = doc.data()?['accountStatus'] ?? 'pending';
        print('🔍 Initial status check: $status');
        
        if (status == 'approved' || status == 'active') {
          print('✅ Initial check found approved/active status! Navigating to HomePage');
          _statusSubscription?.cancel();
          
          if (mounted) {
            // Navigate directly to HomePage
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const HomePage()),
              (route) => false,
            );
          }
          return; // Exit early
        }
        
        if (mounted) {
          setState(() {
            _currentStatus = status;
          });
        }
      } catch (e) {
        print('❌ Error checking status: $e');
      }
    }
  }

  // Manual refresh triggered by user
  Future<void> _refreshStatus() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });

    final user = _auth.currentUser;
    if (user != null) {
      try {
        print('🔄 Manual refresh requested');
        final doc = await _firestore.collection('users').doc(user.uid).get();
        final status = doc.data()?['accountStatus'] ?? 'pending';
        print('📊 Refreshed status: $status');
        
        if (status == 'approved' || status == 'active') {
          print('✅ Manual refresh detected approval! Navigating to HomePage');
          _statusSubscription?.cancel();
          
          if (mounted) {
            // Navigate directly to HomePage
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const HomePage()),
              (route) => false,
            );
          }
          return; // Exit early, don't need to update UI
        }
        
        if (mounted) {
          setState(() {
            _currentStatus = status;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Status refreshed: $status'),
              backgroundColor: Colors.blue,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        print('❌ Error refreshing status: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  Future<void> _logout() async {
    try {
      await _auth.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error logging out: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF2D3748),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D3748),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _logout,
          tooltip: 'Logout and go back',
        ),
        title: const Text(
          'Account Pending',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Logo
                const AppLogo(size: 100, color: Colors.white),
                const SizedBox(height: 40),

                // Pending Icon
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.hourglass_empty,
                    size: 80,
                    color: Colors.orange,
                  ),
                ),

                const SizedBox(height: 32),

                // Title
                const Text(
                  'Account Pending Approval',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Description
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Thank you for registering!',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[300],
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Your account is currently under review by an administrator. You will receive access once your account has been approved.',
                        style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      if (user?.email != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.email_outlined,
                              size: 16,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              user!.email!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[400],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Status Display (for debugging)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Current Status: $_currentStatus',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[400],
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _isRefreshing ? null : _refreshStatus,
                        icon: _isRefreshing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.refresh, size: 18),
                        label: Text(
                          _isRefreshing ? 'Checking...' : 'Refresh Status',
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Info text
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue[300],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You will be automatically redirected when your account is approved',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[300],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40), // Extra bottom spacing
              ],
            ),
          ),
        ),
      ),
    );
  }
}
