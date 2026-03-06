import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/app_notification.dart';

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Navigation callback - set this from main.dart
  Function(String type, String? actionId, Map<String, dynamic>? data)? onNotificationTap;

  // Initialize FCM
  Future<void> initialize() async {
    try {
      // Request permission for iOS
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted notification permission');
      } else {
        debugPrint('User declined notification permission');
        return;
      }

      // Get FCM token
      String? token = await _messaging.getToken();
      if (token != null) {
        await _saveFCMToken(token);
        debugPrint('FCM Token: $token');
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen(_saveFCMToken);

      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification taps when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check if app was opened from a notification
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      debugPrint('Notification service initialized');
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  // Save FCM token to Firestore
  Future<void> _saveFCMToken(String token) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('FCM token saved to Firestore');
      }
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message: ${message.notification?.title}');
    
    // Store notification in Firestore
    if (message.data.isNotEmpty) {
      _storeNotification(
        title: message.notification?.title ?? 'New Notification',
        body: message.notification?.body ?? '',
        type: message.data['type'] ?? 'general',
        actionId: message.data['actionId'],
        data: message.data,
      );
    }
  }

  // Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Notification tapped: ${message.data}');
    
    if (onNotificationTap != null && message.data.isNotEmpty) {
      onNotificationTap!(
        message.data['type'] ?? 'general',
        message.data['actionId'],
        message.data,
      );
    }
  }

  // Store notification in Firestore
  Future<void> _storeNotification({
    required String title,
    required String body,
    required String type,
    String? actionId,
    Map<String, dynamic>? data,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return;

      final notification = AppNotification(
        id: '', // Will be set by Firestore
        userId: user.uid,
        title: title,
        body: body,
        type: type,
        actionId: actionId,
        isRead: false,
        createdAt: DateTime.now(),
        data: data,
      );

      await _firestore
          .collection('notifications')
          .add(notification.toFirestore());
    } catch (e) {
      debugPrint('Error storing notification: $e');
    }
  }

  // Send notification to specific user (called by admin actions)
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    required String type,
    String? actionId,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Store notification in Firestore
      final notification = AppNotification(
        id: '',
        userId: userId,
        title: title,
        body: body,
        type: type,
        actionId: actionId,
        isRead: false,
        createdAt: DateTime.now(),
        data: additionalData,
      );

      await _firestore
          .collection('notifications')
          .add(notification.toFirestore());

      // Get user's FCM token
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        String? fcmToken = (userDoc.data() as Map<String, dynamic>)['fcmToken'];
        
        if (fcmToken != null) {
          // In production, you would send this to your backend server
          // which would use Firebase Admin SDK to send the push notification
          // For now, we're just storing in Firestore
          debugPrint('Would send push notification to token: $fcmToken');
          debugPrint('Title: $title, Body: $body');
        }
      }
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }

  // Get user's notifications stream
  Stream<List<AppNotification>> getUserNotifications() {
    User? user = _auth.currentUser;
    if (user == null) {
      debugPrint('⚠️ No user logged in for notifications');
      return Stream.value([]);
    }

    debugPrint('📡 Setting up notification stream for user: ${user.uid}');

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
          debugPrint('📬 Received ${snapshot.docs.length} notifications from Firestore');
          final notifications = snapshot.docs
              .map((doc) {
                try {
                  final notification = AppNotification.fromFirestore(doc);
                  debugPrint('✅ Parsed notification: ${notification.title}');
                  return notification;
                } catch (e) {
                  debugPrint('❌ Error parsing notification ${doc.id}: $e');
                  return null;
                }
              })
              .whereType<AppNotification>() // Filter out nulls
              .toList();
          // Sort in memory instead of using orderBy to avoid needing composite index
          notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          debugPrint('📋 Returning ${notifications.length} parsed notifications');
          return notifications.take(50).toList();
        });
  }

  // Get unread notification count
  Stream<int> getUnreadCount() {
    User? user = _auth.currentUser;
    if (user == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return;

      QuerySnapshot unreadNotifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .get();

      WriteBatch batch = _firestore.batch();
      for (var doc in unreadNotifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  // Delete all notifications for current user
  Future<void> deleteAllNotifications() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return;

      QuerySnapshot userNotifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .get();

      WriteBatch batch = _firestore.batch();
      for (var doc in userNotifications.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error deleting all notifications: $e');
    }
  }

  // Clear FCM token on logout
  Future<void> clearFCMToken() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': FieldValue.delete(),
        });
      }
      await _messaging.deleteToken();
    } catch (e) {
      debugPrint('Error clearing FCM token: $e');
    }
  }
}
