# React Admin Dashboard - Notification Integration

## Quick Fix for "Missing or insufficient permissions" Error

First, verify your admin account has the `isAdmin: true` field:

1. Open Firebase Console → Firestore Database
2. Find `users` collection → Find your admin user document
3. Add field if missing: `isAdmin` (boolean) = `true`
4. Refresh your React admin dashboard

---

## Step 1: Create Notification Helper (React)

Create a new file: `src/utils/notificationHelper.js`

```javascript
import { collection, addDoc, serverTimestamp, getDocs, query, where, writeBatch, doc } from 'firebase/firestore';
import { db } from './firebase'; // Adjust path to your Firebase config

/**
 * Create a notification for a specific user
 */
export const createNotification = async (userId, title, body, type, actionId = null) => {
    try {
        await addDoc(collection(db, 'notifications'), {
            userId,
            title,
            body,
            type, // 'report', 'service', 'supplies', 'news', 'approval', 'barangay_info'
            actionId,
            isRead: false,
            createdAt: serverTimestamp()
        });
        console.log('✅ Notification created for user:', userId);
        return true;
    } catch (error) {
        console.error('❌ Error creating notification:', error);
        return false;
    }
};

/**
 * Notify user when report status changes
 */
export const notifyReportStatusUpdate = async (userId, reportId, newStatus) => {
    let body = '';
    
    if (newStatus === 'in_progress' || newStatus === 'in-progress') {
        body = 'Your report is now being processed by the admin team.';
    } else if (newStatus === 'resolved') {
        body = 'Good news! Your report has been resolved.';
    } else {
        body = `Your report status has been updated to: ${newStatus}`;
    }
    
    return await createNotification(
        userId,
        '📋 Report Status Updated',
        body,
        'report',
        reportId
    );
};

/**
 * Notify user when service request status changes
 */
export const notifyServiceRequestUpdate = async (userId, requestId, newStatus) => {
    return await createNotification(
        userId,
        '🛠️ Service Request Updated',
        `Your service request status: ${newStatus}`,
        'service',
        requestId
    );
};

/**
 * Notify user when borrow request is approved
 */
export const notifyBorrowApproved = async (userId, borrowId, supplyName, quantity) => {
    return await createNotification(
        userId,
        '✅ Borrow Request Approved',
        `Your request to borrow ${quantity} ${supplyName} has been approved!`,
        'supplies',
        borrowId
    );
};

/**
 * Notify user when borrow request is rejected
 */
export const notifyBorrowRejected = async (userId, borrowId, supplyName, reason = '') => {
    const body = reason 
        ? `Your request to borrow ${supplyName} was rejected. Reason: ${reason}`
        : `Your request to borrow ${supplyName} was rejected.`;
    
    return await createNotification(
        userId,
        '❌ Borrow Request Rejected',
        body,
        'supplies',
        borrowId
    );
};

/**
 * Notify user when account is approved
 */
export const notifyUserApproved = async (userId) => {
    return await createNotification(
        userId,
        '✅ Account Approved!',
        'Your account has been approved by the admin. You now have full access to all features.',
        'approval',
        null
    );
};

/**
 * Notify user when account is rejected
 */
export const notifyUserRejected = async (userId, reason = '') => {
    const body = reason
        ? `Your account verification was rejected. Reason: ${reason}. Please contact the admin for more information.`
        : 'Your account verification was rejected. Please contact the admin for more information.';
    
    return await createNotification(
        userId,
        '❌ Account Verification Rejected',
        body,
        'approval',
        null
    );
};

/**
 * Notify all approved users about new announcement
 */
export const notifyNewAnnouncement = async (announcementTitle, category) => {
    try {
        // Get all approved users
        const usersQuery = query(
            collection(db, 'users'),
            where('accountStatus', 'in', ['approved', 'active'])
        );
        const usersSnapshot = await getDocs(usersQuery);
        
        // Create batch notification
        const batch = writeBatch(db);
        usersSnapshot.forEach(userDoc => {
            const notifRef = doc(collection(db, 'notifications'));
            batch.set(notifRef, {
                userId: userDoc.id,
                title: `📢 New ${category} Announcement`,
                body: announcementTitle,
                type: 'news',
                isRead: false,
                createdAt: serverTimestamp()
            });
        });
        
        await batch.commit();
        console.log(`✅ Notifications sent to ${usersSnapshot.size} users`);
        return true;
    } catch (error) {
        console.error('❌ Error sending announcement notifications:', error);
        return false;
    }
};

/**
 * Notify all approved users about barangay info update
 */
export const notifyBarangayInfoUpdated = async () => {
    try {
        const usersQuery = query(
            collection(db, 'users'),
            where('accountStatus', 'in', ['approved', 'active'])
        );
        const usersSnapshot = await getDocs(usersQuery);
        
        const batch = writeBatch(db);
        usersSnapshot.forEach(userDoc => {
            const notifRef = doc(collection(db, 'notifications'));
            batch.set(notifRef, {
                userId: userDoc.id,
                title: '🏢 Barangay Information Updated',
                body: 'The barangay information has been updated. Check it out!',
                type: 'barangay_info',
                isRead: false,
                createdAt: serverTimestamp()
            });
        });
        
        await batch.commit();
        console.log(`✅ Notifications sent to ${usersSnapshot.size} users`);
        return true;
    } catch (error) {
        console.error('❌ Error sending barangay update notifications:', error);
        return false;
    }
};
```

---

## Step 2: Update Your ViewReports Component

In your `ViewReports.jsx` (or wherever you update report status):

```javascript
import { notifyReportStatusUpdate } from '../utils/notificationHelper';
import { doc, updateDoc, serverTimestamp } from 'firebase/firestore';
import { db } from '../utils/firebase';

// Inside your component:

const handleStatusUpdate = async (reportId, userId, newStatus) => {
    try {
        // 1. Update report status in Firestore
        const reportRef = doc(db, 'reports', reportId);
        await updateDoc(reportRef, {
            status: newStatus,
            updatedAt: serverTimestamp()
        });
        
        // 2. Send notification to user
        await notifyReportStatusUpdate(userId, reportId, newStatus);
        
        // 3. Show success message
        alert('✅ Status updated and user notified!');
        
    } catch (error) {
        console.error('Error updating status:', error);
        alert('❌ Error updating status: ' + error.message);
    }
};

// Example: Button click handlers
<button onClick={() => handleStatusUpdate(report.id, report.userId, 'in-progress')}>
    Set In-Progress
</button>

<button onClick={() => handleStatusUpdate(report.id, report.userId, 'resolved')}>
    Mark Resolved
</button>
```

---

## Step 3: Quick Integration Examples

### For In-Progress Button:
```javascript
const handleSetInProgress = async (report) => {
    try {
        // Update Firestore
        await updateDoc(doc(db, 'reports', report.id), {
            status: 'in-progress',
            updatedAt: serverTimestamp()
        });
        
        // Send notification
        await notifyReportStatusUpdate(report.userId, report.id, 'in-progress');
        
        console.log('✅ Report set to in-progress and user notified');
    } catch (error) {
        console.error('Error:', error);
    }
};
```

### For Resolved Button:
```javascript
const handleMarkResolved = async (report) => {
    try {
        await updateDoc(doc(db, 'reports', report.id), {
            status: 'resolved',
            updatedAt: serverTimestamp()
        });
        
        await notifyReportStatusUpdate(report.userId, report.id, 'resolved');
        
        console.log('✅ Report resolved and user notified');
    } catch (error) {
        console.error('Error:', error);
    }
};
```

---

## Step 4: Test Notification (React Console)

Open your React admin dashboard, press **F12**, and paste this in the Console tab:

```javascript
// Test notification for your account
const { collection, addDoc, serverTimestamp } = require('firebase/firestore');
const { db } = require('./utils/firebase'); // Adjust path

await addDoc(collection(db, 'notifications'), {
    userId: 'DLthdLzxkLbqwFFccFckDtqjIv1', // Your admin user ID
    title: '📋 Test Notification',
    body: 'This is a test notification from React admin!',
    type: 'report',
    actionId: 'test_123',
    isRead: false,
    createdAt: serverTimestamp()
});

console.log('✅ Test notification created! Check your Flutter app!');
```

Or use the simpler version if you have notificationHelper imported:

```javascript
await createNotification(
    'DLthdLzxkLbqwFFccFckDtqjIv1',
    '📋 Test from React',
    'Testing notification system!',
    'report',
    'test_123'
);
```

---

## Complete Example: ViewReports.jsx

```javascript
import React, { useState, useEffect } from 'react';
import { collection, getDocs, doc, updateDoc, serverTimestamp } from 'firebase/firestore';
import { db } from '../utils/firebase';
import { notifyReportStatusUpdate } from '../utils/notificationHelper';

const ViewReports = () => {
    const [reports, setReports] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        fetchReports();
    }, []);

    const fetchReports = async () => {
        try {
            const querySnapshot = await getDocs(collection(db, 'reports'));
            const reportsData = querySnapshot.docs.map(doc => ({
                id: doc.id,
                ...doc.data()
            }));
            setReports(reportsData);
            console.log('Fetched reports:', reportsData.length);
        } catch (error) {
            console.error('Error fetching reports:', error);
        } finally {
            setLoading(false);
        }
    };

    const updateStatus = async (reportId, userId, newStatus) => {
        try {
            // Update Firestore
            await updateDoc(doc(db, 'reports', reportId), {
                status: newStatus,
                updatedAt: serverTimestamp()
            });

            // Send notification
            await notifyReportStatusUpdate(userId, reportId, newStatus);

            // Update local state
            setReports(prev => prev.map(report => 
                report.id === reportId 
                    ? { ...report, status: newStatus }
                    : report
            ));

            alert('✅ Status updated and user notified!');
        } catch (error) {
            console.error('Error updating status:', error);
            alert('❌ Error: ' + error.message);
        }
    };

    if (loading) return <div>Loading...</div>;

    return (
        <div className="reports-container">
            <h1>Reports Management</h1>
            <table>
                <thead>
                    <tr>
                        <th>#</th>
                        <th>Category</th>
                        <th>Description</th>
                        <th>Status</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    {reports.map((report, index) => (
                        <tr key={report.id}>
                            <td>{index + 1}</td>
                            <td>{report.category}</td>
                            <td>{report.description}</td>
                            <td>
                                <span className={`status-badge ${report.status}`}>
                                    {report.status}
                                </span>
                            </td>
                            <td>
                                <button 
                                    onClick={() => updateStatus(report.id, report.userId, 'in-progress')}
                                    disabled={report.status === 'in-progress'}
                                >
                                    In-Progress
                                </button>
                                <button 
                                    onClick={() => updateStatus(report.id, report.userId, 'resolved')}
                                    disabled={report.status === 'resolved'}
                                >
                                    Resolve
                                </button>
                            </td>
                        </tr>
                    ))}
                </tbody>
            </table>
        </div>
    );
};

export default ViewReports;
```

---

## What You Need to Do:

1. **Create** `src/utils/notificationHelper.js` with the helper functions
2. **Import** notification helpers in your ViewReports component
3. **Add** `await notifyReportStatusUpdate(...)` after every status update
4. **Test** by clicking "In-Progress" button - notification should appear in Flutter app!

## Need Help?

Share your `ViewReports.jsx` file and I'll integrate the notification code for you directly!
