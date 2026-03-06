// ========================================
// COPY THIS CODE TO YOUR REACT ADMIN DASHBOARD
// ========================================

// FILE: src/utils/notificationHelper.js (CREATE THIS FILE)
import { collection, addDoc, serverTimestamp } from 'firebase/firestore';
import { db } from './firebase'; // Adjust path to your Firebase config

/**
 * Create notification for report status update
 */
export const notifyReportStatusUpdate = async (userId, reportId, newStatus) => {
    try {
        let body = '';
        
        if (newStatus === 'in-progress' || newStatus === 'In-progress') {
            body = 'Your report is now being processed by the admin team.';
        } else if (newStatus === 'resolved' || newStatus === 'Resolved') {
            body = 'Good news! Your report has been resolved.';
        } else {
            body = `Your report status has been updated to: ${newStatus}`;
        }
        
        await addDoc(collection(db, 'notifications'), {
            userId: userId,
            title: '📋 Report Status Updated',
            body: body,
            type: 'report',
            actionId: reportId,
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

// ========================================
// THEN IN YOUR ViewReports.jsx COMPONENT:
// ========================================

// 1. Import the notification helper at the top:
import { notifyReportStatusUpdate } from '../utils/notificationHelper';

// 2. Find the function that handles the green checkmark button click
//    (the one that sets status to "in-progress")
//    It might look like handleApprove, onStatusChange, updateStatus, etc.

// 3. Add this line AFTER you update the report in Firestore:
await notifyReportStatusUpdate(report.userId, report.id, 'in-progress');

// EXAMPLE - Your code might look like this:
const handleSetInProgress = async (reportId, userId) => {
    try {
        // Update status in Firestore
        await updateDoc(doc(db, 'reports', reportId), {
            status: 'in-progress'
        });
        
        // 👇 ADD THIS LINE - Send notification
        await notifyReportStatusUpdate(userId, reportId, 'in-progress');
        
        // Show success message
        alert('Status updated!');
        
    } catch (error) {
        console.error('Error:', error);
    }
};

// ========================================
// FOR THE RESOLVED BUTTON (the other checkmark):
// ========================================
const handleSetResolved = async (reportId, userId) => {
    try {
        await updateDoc(doc(db, 'reports', reportId), {
            status: 'resolved'
        });
        
        // 👇 ADD THIS LINE
        await notifyReportStatusUpdate(userId, reportId, 'resolved');
        
        alert('Report resolved!');
        
    } catch (error) {
        console.error('Error:', error);
    }
};

// ========================================
// QUICK TEST IN BROWSER CONSOLE
// ========================================
// Open your React admin page, press F12, paste this:

firebase.firestore().collection('notifications').add({
    userId: 'DLthdLzxkLbqwFFccFckDtqjIv1',
    title: '📋 Report Status Updated',
    body: 'Your report is now being processed by the admin team.',
    type: 'report',
    actionId: 'test',
    isRead: false,
    createdAt: firebase.firestore.FieldValue.serverTimestamp()
}).then(() => {
    alert('✅ Notification created! Check your Flutter app!');
});
