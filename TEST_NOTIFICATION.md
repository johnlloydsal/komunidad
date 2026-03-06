# Manual Test: Create a Notification in Firebase Console

Since automatic notifications aren't appearing yet, let's test manually:

## Steps to Create Test Notification:

1. **Go to Firebase Console** → Firestore Database
2. **Click "Start collection"** or select `notifications` collection
3. **Click "Add document"**
4. **Use Auto-ID** for Document ID
5. **Add these fields:**

```
userId: "YOUR_USER_ID_HERE"  (string)
title: "Test Notification"  (string)
body: "This is a test notification from Firebase Console"  (string)
type: "report"  (string)
isRead: false  (boolean)
createdAt: (click clock icon to use server timestamp)
```

6. **Get your User ID:**
   - Firebase Console → Authentication → Users
   - Copy YOUR user's UID (the one you're logged in with)
   - Paste it in the `userId` field above

7. **Save the document**

8. **Refresh your app** → Open notifications screen

You should see the test notification!

## If This Works:

The notification system IS working, and the issue is with automatic notification creation. Check:
- Console logs when admin clicks "In-progress" button
- Verify `NotificationService` is being called in `report_service.dart`

## If This Doesn't Work:

The issue is with:
- Firestore security rules (unlikely since we deployed them)
- User authentication/UID mismatch
- App not reading from Firestore properly
