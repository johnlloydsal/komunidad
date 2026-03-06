# Notification System Setup Guide

## What Was Implemented

A complete push notification system that notifies users when:
- ✅ Admin approves/rejects their account
- ✅ Admin updates their report status (pending → in-progress → resolved)
- ✅ Admin updates their service request status
- ✅ Admin approves/rejects their supply borrow request
- ✅ Admin posts new community news/announcements
- ✅ Admin updates barangay information

## Files Created/Modified

### New Files:
1. **lib/models/app_notification.dart** - Notification data model
2. **lib/services/notification_service.dart** - Firebase Cloud Messaging service
3. **lib/notifications_screen.dart** - In-app notifications UI
4. **This guide** - Setup instructions

### Modified Files:
1. **pubspec.yaml** - Added `firebase_messaging: ^15.1.6`
2. **lib/main.dart** - Initialize notification service & navigation
3. **lib/homepage.dart** - Added notification bell icon with unread count
4. **firestore.rules** - Added notifications collection security rules
5. **lib/services/user_service.dart** - Send notifications on approve/reject
6. **lib/services/report_service.dart** - Send notifications on status updates
7. **lib/services/service_request_service.dart** - Send notifications on updates
8. **lib/services/supplies_service.dart** - Send notifications on borrow approve/reject
9. **lib/services/announcement_service.dart** - Send notifications on new posts
10. **lib/services/barangay_service.dart** - Send notifications on info updates

## How It Works

### In-App Notifications (Working Now)
- Notifications are stored in Firestore `notifications` collection
- Users can view all their notifications in the Notifications screen
- Clicking a notification navigates to the related feature
- Users can mark as read, delete, or clear all notifications

### Push Notifications (Requires Additional Setup)
For notifications to appear on locked screen/notification tray:

#### Android Setup Required:
1. **Add to `android/app/src/main/AndroidManifest.xml`** (inside `<application>` tag):
```xml
<!-- Firebase Messaging -->
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="high_importance_channel" />
    
<meta-data
    android:name="com.google.firebase.messaging.default_notification_icon"
    android:resource="@drawable/ic_notification" />

<meta-data
    android:name="com.google.firebase.messaging.default_notification_color"
    android:resource="@color/notification_color" />
```

2. **Create notification icon** at `android/app/src/main/res/drawable/ic_notification.xml`:
```xml
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24"
    android:tint="#FFFFFF">
  <path
      android:fillColor="@android:color/white"
      android:pathData="M12,22c1.1,0 2,-0.9 2,-2h-4c0,1.1 0.9,2 2,2zM18,16v-5c0,-3.07 -1.64,-5.64 -4.5,-6.32V4c0,-0.83 -0.67,-1.5 -1.5,-1.5s-1.5,0.67 -1.5,1.5v0.68C7.63,5.36 6,7.92 6,11v5l-2,2v1h16v-1l-2,-2z"/>
</vector>
```

3. **Create colors resource** at `android/app/src/main/res/values/colors.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="notification_color">#1E3A8A</color>
</resources>
```

#### iOS Setup Required:
1. **Add notification capability** in Xcode:
   - Open `ios/Runner.xcworkspace` in Xcode
   - Select Runner target → Signing & Capabilities
   - Click "+ Capability" → Push Notifications
   - Click "+ Capability" → Background Modes
   - Check "Remote notifications"

2. **Request permission** (already done in notification_service.dart)

#### Backend Server (Optional - for better push notifications):
Currently, notifications are stored in Firestore only. For actual push notifications to devices, you need a backend server with Firebase Admin SDK:

**Option 1: Cloud Functions (Recommended)**
Create a Firebase Cloud Function that listens to new notifications in Firestore and sends FCM messages:

```javascript
// functions/index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendNotificationOnCreate = functions.firestore
    .document('notifications/{notificationId}')
    .onCreate(async (snap, context) => {
        const notification = snap.data();
        const userId = notification.userId;
        
        // Get user's FCM token
        const userDoc = await admin.firestore().collection('users').doc(userId).get();
        const fcmToken = userDoc.data().fcmToken;
        
        if (!fcmToken) return null;
        
        // Send push notification
        const message = {
            notification: {
                title: notification.title,
                body: notification.body,
            },
            data: {
                type: notification.type,
                actionId: notification.actionId || '',
            },
            token: fcmToken,
        };
        
        return admin.messaging().send(message);
    });
```

Deploy with: `firebase deploy --only functions`

**Option 2: Simple PHP/Node Backend**
Create a simple API endpoint that uses Firebase Admin SDK to send messages.

## Firestore Collections

### notifications collection structure:
```
notifications/{notificationId}
├── userId: string (recipient)
├── title: string
├── body: string
├── type: string (report|service|supplies|news|approval|barangay_info)
├── actionId: string? (optional - for navigation)
├── isRead: boolean
├── createdAt: timestamp
└── data: map? (optional additional data)
```

### users collection - added fields:
```
users/{userId}
├── fcmToken: string (device token for push notifications)
└── fcmTokenUpdatedAt: timestamp
```

## Current Status

✅ **Working:**
- In-app notification storage in Firestore
- Notification bell icon on homepage with unread count
- Notifications screen with list of all notifications
- Mark as read/unread functionality
- Delete individual or all notifications
- Navigation when tapping notifications
- Automatic notification creation when admin takes actions

⏳ **Needs Setup for Push Notifications:**
- Android manifest configuration (see above)
- iOS capabilities (see above)
- Firebase Cloud Functions OR backend server for sending FCM messages

## Testing In-App Notifications

1. **As Admin:**
   - Go to Admin User Management
   - Approve or reject a pending user
   - Update a report status to "in-progress" or "resolved"
   - Approve/reject a supply borrow request
   - Update a service request status
   - Post new community news
   - Update barangay information

2. **As User:**
   - Open the app
   - Look at the notification bell icon (should show red badge with count)
   - Tap the bell icon to see notifications
   - Tap a notification to navigate to related page
   - Swipe left to delete a notification
   - Use menu to mark all as read or delete all

## Troubleshooting

### "Error loading notifications"
- ✅ FIXED: Firestore rules updated and deployed

### Notifications not showing in list
- Check if notification was created in Firebase Console → Firestore → notifications collection
- Verify userId matches the logged-in user
- Check console logs for errors

### Push notifications not appearing on device
- Verify Android manifest is configured (see above)
- Check FCM token is saved in users/{userId}/fcmToken
- Verify Cloud Functions are deployed (if using)
- Check Android notification permissions are granted
- Test with Firebase Console → Cloud Messaging → Send test message

### Token not saving
- Check console logs for "FCM Token:" message
- Verify notification permissions were granted
- Check Firestore rules allow updating fcmToken field

## Security

- Notifications are user-specific (stored with userId)
- Firestore rules ensure users can only read their own notifications
- FCM tokens are securely stored in Firestore
- Admin actions are verified before sending notifications

## Future Enhancements

1. Notification categories/filtering
2. Notification sound customization
3. Rich notifications with images
4. Action buttons in notifications (e.g., "View Report", "Dismiss")
5. Email notifications as backup
6. Notification preferences (allow users to choose what to be notified about)
7. Scheduled notifications
8. Batch notifications (group similar notifications)

## Questions?

If you encounter any issues:
1. Check Flutter console for error logs
2. Check Firebase Console → Firestore for notification documents
3. Verify Firestore rules are deployed: `firebase deploy --only firestore:rules`
4. Test notification creation manually in Firebase Console
