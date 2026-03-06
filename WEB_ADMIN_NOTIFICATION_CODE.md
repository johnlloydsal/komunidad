# Add Notifications to Your Web Admin Dashboard

Since your admin dashboard is separate from the Flutter app, add this code directly to your admin panel.

## Option 1: Quick Copy-Paste Solution

Add this function to your admin dashboard JavaScript:

```javascript
// Function to create notification in Firestore
async function createNotification(userId, title, body, type, actionId = null) {
    try {
        await firebase.firestore().collection('notifications').add({
            userId: userId,
            title: title,
            body: body,
            type: type,              // 'report', 'service', 'supplies', 'news', 'approval', 'barangay_info'
            actionId: actionId,      // Report ID, Service Request ID, etc.
            isRead: false,
            createdAt: firebase.firestore.FieldValue.serverTimestamp()
        });
        console.log('✅ Notification created for user:', userId);
    } catch (error) {
        console.error('❌ Error creating notification:', error);
    }
}
```

## Option 2: For Report Status Updates

When you update a report status in your admin dashboard, add this code IMMEDIATELY AFTER:

```javascript
// Example: When admin clicks "In-progress" button
async function updateReportStatus(reportId, newStatus) {
    // 1. Get the report document first
    const reportDoc = await firebase.firestore()
        .collection('reports')
        .doc(reportId)
        .get();
    
    const reportData = reportDoc.data();
    const userId = reportData.userId;
    
    // 2. Update the status
    await firebase.firestore()
        .collection('reports')
        .doc(reportId)
        .update({
            status: newStatus,
            updatedAt: firebase.firestore.FieldValue.serverTimestamp()
        });
    
    // 3. Create notification based on status
    let title = '📋 Report Status Updated';
    let body = '';
    
    if (newStatus === 'in_progress') {
        body = 'Your report is now being processed by the admin team.';
    } else if (newStatus === 'resolved') {
        body = 'Good news! Your report has been resolved.';
    } else {
        body = `Your report status has been updated to: ${newStatus}`;
    }
    
    // 4. Send notification
    await createNotification(userId, title, body, 'report', reportId);
    
    console.log('✅ Report updated and notification sent!');
}
```

## Option 3: For ALL Notification Types

Copy all these functions to your admin dashboard:

```javascript
// === REPORT STATUS NOTIFICATIONS ===
async function notifyReportStatusUpdate(userId, reportId, newStatus) {
    let body = '';
    if (newStatus === 'in_progress') {
        body = 'Your report is now being processed by the admin team.';
    } else if (newStatus === 'resolved') {
        body = 'Good news! Your report has been resolved.';
    } else {
        body = `Your report status has been updated to: ${newStatus}`;
    }
    
    await createNotification(
        userId,
        '📋 Report Status Updated',
        body,
        'report',
        reportId
    );
}

// === SERVICE REQUEST NOTIFICATIONS ===
async function notifyServiceRequestUpdate(userId, requestId, newStatus) {
    let body = `Your service request status: ${newStatus}`;
    
    await createNotification(
        userId,
        '🛠️ Service Request Updated',
        body,
        'service',
        requestId
    );
}

// === BORROW REQUEST NOTIFICATIONS ===
async function notifyBorrowApproved(userId, borrowId, supplyName, quantity) {
    await createNotification(
        userId,
        '✅ Borrow Request Approved',
        `Your request to borrow ${quantity} ${supplyName} has been approved!`,
        'supplies',
        borrowId
    );
}

async function notifyBorrowRejected(userId, borrowId, supplyName, reason = '') {
    let body = `Your request to borrow ${supplyName} was rejected.`;
    if (reason) {
        body += ` Reason: ${reason}`;
    }
    
    await createNotification(
        userId,
        '❌ Borrow Request Rejected',
        body,
        'supplies',
        borrowId
    );
}

// === USER APPROVAL NOTIFICATIONS ===
async function notifyUserApproved(userId) {
    await createNotification(
        userId,
        '✅ Account Approved!',
        'Your account has been approved by the admin. You now have full access to all features.',
        'approval',
        null
    );
}

async function notifyUserRejected(userId, reason = '') {
    let body = 'Your account verification was rejected.';
    if (reason) {
        body += ` Reason: ${reason}. Please contact the admin for more information.`;
    }
    
    await createNotification(
        userId,
        '❌ Account Verification Rejected',
        body,
        'approval',
        null
    );
}

// === ANNOUNCEMENT NOTIFICATIONS (for all users) ===
async function notifyNewAnnouncement(announcementTitle, category) {
    // Get all approved users
    const usersSnapshot = await firebase.firestore()
        .collection('users')
        .where('accountStatus', 'in', ['approved', 'active'])
        .get();
    
    // Create notification for each user
    const batch = firebase.firestore().batch();
    usersSnapshot.forEach(userDoc => {
        const notifRef = firebase.firestore().collection('notifications').doc();
        batch.set(notifRef, {
            userId: userDoc.id,
            title: `📢 New ${category} Announcement`,
            body: announcementTitle,
            type: 'news',
            isRead: false,
            createdAt: firebase.firestore.FieldValue.serverTimestamp()
        });
    });
    
    await batch.commit();
    console.log(`✅ Notifications sent to ${usersSnapshot.size} users`);
}

// === BARANGAY INFO NOTIFICATIONS (for all users) ===
async function notifyBarangayInfoUpdated() {
    // Get all approved users
    const usersSnapshot = await firebase.firestore()
        .collection('users')
        .where('accountStatus', 'in', ['approved', 'active'])
        .get();
    
    // Create notification for each user
    const batch = firebase.firestore().batch();
    usersSnapshot.forEach(userDoc => {
        const notifRef = firebase.firestore().collection('notifications').doc();
        batch.set(notifRef, {
            userId: userDoc.id,
            title: '🏢 Barangay Information Updated',
            body: 'The barangay information has been updated. Check it out!',
            type: 'barangay_info',
            isRead: false,
            createdAt: firebase.firestore.FieldValue.serverTimestamp()
        });
    });
    
    await batch.commit();
    console.log(`✅ Notifications sent to ${usersSnapshot.size} users`);
}
```

## How to Use in Your Admin Dashboard

### Example 1: When clicking "In-Progress" button
```javascript
// In your button click handler
document.getElementById('btnInProgress').addEventListener('click', async () => {
    const reportId = 'report_123';  // Get from your table row
    const userId = 'user_456';       // Get from report data
    
    // Update Firestore
    await firebase.firestore().collection('reports').doc(reportId).update({
        status: 'in_progress'
    });
    
    // Send notification
    await notifyReportStatusUpdate(userId, reportId, 'in_progress');
    
    alert('Status updated and user notified!');
});
```

### Example 2: When clicking "Resolved" button
```javascript
document.getElementById('btnResolved').addEventListener('click', async () => {
    const reportId = getCurrentReportId();
    const userId = getCurrentReportUserId();
    
    await firebase.firestore().collection('reports').doc(reportId).update({
        status: 'resolved'
    });
    
    await notifyReportStatusUpdate(userId, reportId, 'resolved');
});
```

## Quick Test (Create notification manually)

Open your browser console on the admin dashboard and run:

```javascript
// Test notification for user: DLthdLzxkLbqwFFccFckDtqjIv1
await firebase.firestore().collection('notifications').add({
    userId: 'DLthdLzxkLbqwFFccFckDtqjIv1',
    title: '📋 Report Status Updated',
    body: 'Your report is now being processed by the admin team.',
    type: 'report',
    actionId: 'test_report_123',
    isRead: false,
    createdAt: firebase.firestore.FieldValue.serverTimestamp()
});
console.log('✅ Test notification created!');
```

Then check your phone - the notification should appear immediately!

## Need Help?

1. **What web framework are you using?** (React, Vue, plain JavaScript, etc.)
2. **Share your admin code** where you update report statuses
3. I'll integrate the notification code for you!
