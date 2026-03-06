// ========================================
// QUICK FIX - USE IN BROWSER CONSOLE
// ========================================
// Copy this entire script and paste in browser console (F12)
// Then just type: notifyUser('report_id', 'user_id', 'in-progress')

window.notifyUser = async function(reportId, userId, status) {
    const messages = {
        'in-progress': 'Your report is now being processed by the admin team.',
        'In-progress': 'Your report is now being processed by the admin team.',
        'resolved': 'Good news! Your report has been resolved.',
        'Resolved': 'Good news! Your report has been resolved.',
        'pending': 'Your report status has been updated.',
        'Pending': 'Your report status has been updated.'
    };
    
    try {
        await firebase.firestore().collection('notifications').add({
            userId: userId,
            title: '📋 Report Status Updated',
            body: messages[status] || `Your report status: ${status}`,
            type: 'report',
            actionId: reportId,
            isRead: false,
            createdAt: firebase.firestore.FieldValue.serverTimestamp()
        });
        console.log('✅ Notification sent to user:', userId);
        alert('✅ Notification sent!');
        return true;
    } catch (error) {
        console.error('❌ Error:', error);
        alert('❌ Error: ' + error.message);
        return false;
    }
};

// Quick helper for your user (johnlloyd salvador)
window.notifyJohn = async function(status) {
    return await notifyUser('report_auto', 'DLthdLzxkLbqwFFccFckDtqjIv1', status);
};

console.log('✅ Notification helpers loaded!');
console.log('📝 Usage:');
console.log('  notifyUser(reportId, userId, status)');
console.log('  notifyJohn("in-progress")  // Quick test for John');
