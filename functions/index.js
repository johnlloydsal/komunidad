const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();

// Trigger when a report status is updated
exports.onReportStatusUpdate = functions.firestore
    .document('reports/{reportId}')
    .onUpdate(async (change, context) => {
        const before = change.before.data();
        const after = change.after.data();
        
        // Check if status changed
        if (before.status !== after.status) {
            const newStatus = after.status;
            const userId = after.userId;
            const reportId = context.params.reportId;
            
            let notificationBody = '';
            const statusLower = newStatus.toLowerCase().replace(/\s+/g, '-');
            
            if (statusLower === 'in-progress' || statusLower === 'in_progress') {
                notificationBody = 'Your report is now being processed by the admin team.';
            } else if (statusLower === 'resolved') {
                notificationBody = 'Good news! Your report has been resolved.';
            } else if (statusLower === 'pending') {
                notificationBody = 'Your report has been received and is pending review.';
            } else if (statusLower === 'rejected') {
                notificationBody = 'Your report has been reviewed. Please check for details.';
            } else {
                notificationBody = `Your report status has been updated to: ${newStatus}`;
            }
            
            // Create notification document
            await db.collection('notifications').add({
                userId: userId,
                title: '📋 Report Status Updated',
                body: notificationBody,
                type: 'report',
                actionId: reportId,
                isRead: false,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            
            console.log(`Created notification for user ${userId} - Report ${reportId} status: ${newStatus}`);
        }
    });

// Trigger when user account is approved/rejected
exports.onUserApprovalStatusUpdate = functions.firestore
    .document('users/{userId}')
    .onUpdate(async (change, context) => {
        const before = change.before.data();
        const after = change.after.data();
        const userId = context.params.userId;
        
        // Check if account status changed to approved or rejected
        const accountStatusChanged = before.accountStatus !== after.accountStatus;
        const idVerificationChanged = before.idVerificationStatus !== after.idVerificationStatus;
        
        // Handle account status change
        if (accountStatusChanged) {
            if (after.accountStatus === 'approved') {
                await db.collection('notifications').add({
                    userId: userId,
                    title: '✅ Account Approved!',
                    body: 'Congratulations! Your account has been approved by the admin. You now have full access to all features.',
                    type: 'approval',
                    isRead: false,
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                });
                console.log(`Created approval notification for user ${userId}`);
            } else if (after.accountStatus === 'rejected') {
                const reason = after.rejectionReason || 'Please contact the admin for more information.';
                await db.collection('notifications').add({
                    userId: userId,
                    title: '❌ Account Verification Rejected',
                    body: `Your account verification was rejected. Reason: ${reason}`,
                    type: 'approval',
                    isRead: false,
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                });
                console.log(`Created rejection notification for user ${userId}`);
            }
        }
        
        // Handle ID verification status change
        if (idVerificationChanged && after.idVerificationStatus === 'verified') {
            await db.collection('notifications').add({
                userId: userId,
                title: '🎉 ID Verification Approved!',
                body: 'Congratulations! Your ID has been verified and approved by the admin. You now have access to all app features.',
                type: 'approval',
                isRead: false,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            console.log(`Created ID verification approval notification for user ${userId}`);
        }
    });

// Trigger when service request status is updated
exports.onServiceRequestStatusUpdate = functions.firestore
    .document('service_requests/{requestId}')
    .onUpdate(async (change, context) => {
        const before = change.before.data();
        const after = change.after.data();
        const requestId = context.params.requestId;
        
        if (before.status !== after.status) {
            const newStatus = after.status;
            const userId = after.userId;
            const statusLower = newStatus.toLowerCase().replace(/\s+/g, '-');
            
            let notificationBody = '';
            if (statusLower === 'in-progress' || statusLower === 'in_progress' || statusLower === 'actioned') {
                notificationBody = 'Your service request is now being processed.';
                
                // If service has linked borrowed items, auto-approve them
                if (after.hasBorrowedItems && after.borrowedItemIds) {
                    for (const borrowId of after.borrowedItemIds) {
                        const borrowDoc = await db.collection('borrowed_supplies').doc(borrowId).get();
                        if (borrowDoc.exists && borrowDoc.data().status === 'pending') {
                            const borrowData = borrowDoc.data();
                            const supplyDoc = await db.collection('supplies').doc(borrowData.supplyId).get();
                            
                            if (supplyDoc.exists) {
                                const supplyData = supplyDoc.data();
                                const availableQty = supplyData.availableQuantity || 0;
                                const quantity = borrowData.quantity || 0;
                                
                                // Auto-approve: update status and decrement quantity
                                await db.collection('borrowed_supplies').doc(borrowId).update({
                                    status: 'borrowed',
                                    approvedAt: admin.firestore.FieldValue.serverTimestamp(),
                                    borrowedAt: admin.firestore.FieldValue.serverTimestamp(),
                                });
                                
                                await db.collection('supplies').doc(borrowData.supplyId).update({
                                    availableQuantity: availableQty - quantity,
                                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                                });
                                
                                console.log(`Auto-approved borrowed item ${borrowId} for service request ${requestId}`);
                            }
                        }
                    }
                }
            } else if (statusLower === 'completed') {
                notificationBody = 'Good news! Your service request has been completed.';
                
                // If service has linked borrowed items, auto-mark them as returned
                if (after.hasBorrowedItems && after.borrowedItemIds) {
                    for (const borrowId of after.borrowedItemIds) {
                        const borrowDoc = await db.collection('borrowed_supplies').doc(borrowId).get();
                        if (borrowDoc.exists && borrowDoc.data().status === 'borrowed') {
                            const borrowData = borrowDoc.data();
                            const supplyDoc = await db.collection('supplies').doc(borrowData.supplyId).get();
                            
                            if (supplyDoc.exists) {
                                const supplyData = supplyDoc.data();
                                const quantity = borrowData.quantity || 0;
                                const availableQty = supplyData.availableQuantity || 0;
                                
                                // Auto-mark as returned: update status and increment quantity
                                await db.collection('borrowed_supplies').doc(borrowId).update({
                                    status: 'returned',
                                    returnedAt: admin.firestore.FieldValue.serverTimestamp(),
                                });
                                
                                await db.collection('supplies').doc(borrowData.supplyId).update({
                                    availableQuantity: availableQty + quantity,
                                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                                });
                                
                                console.log(`Auto-returned borrowed item ${borrowId} for service request ${requestId}`);
                            }
                        }
                    }
                }
            } else if (statusLower === 'resolved') {
                notificationBody = 'Your service request has been fully resolved and all items have been returned.';
            } else if (statusLower === 'pending') {
                notificationBody = 'Your service request has been received and is pending review.';
            } else if (statusLower === 'rejected') {
                notificationBody = 'Your service request has been reviewed. Please check for details.';
            } else {
                notificationBody = `Your service request status has been updated to: ${newStatus}`;
            }
            
            await db.collection('notifications').add({
                userId: userId,
                title: '📋 Service Request Updated',
                body: notificationBody,
                type: 'service',
                actionId: requestId,
                isRead: false,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        }
    });

// Trigger when supply borrow request is approved/rejected/returned
exports.onBorrowStatusUpdate = functions.firestore
    .document('borrowed_supplies/{borrowId}')
    .onUpdate(async (change, context) => {
        const before = change.before.data();
        const after = change.after.data();
        const borrowId = context.params.borrowId;
        
        if (before.status !== after.status) {
            const userId = after.userId;
            const serviceRequestId = after.serviceRequestId;
            
            // Get supply name
            const supplyDoc = await db.collection('supplies').doc(after.supplyId).get();
            const supplyName = supplyDoc.exists ? supplyDoc.data().name : 'supply';
            
            // Handle different status changes
            if (after.status === 'borrowed') {
                await db.collection('notifications').add({
                    userId: userId,
                    title: '✅ Borrow Request Approved',
                    body: `Your request to borrow ${after.quantity} x ${supplyName} has been approved!`,
                    type: 'supplies',
                    actionId: borrowId,
                    isRead: false,
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                });
            } else if (after.status === 'rejected') {
                const reason = after.rejectionReason || '';
                await db.collection('notifications').add({
                    userId: userId,
                    title: '❌ Borrow Request Rejected',
                    body: reason ? `Your request to borrow ${supplyName} was rejected. Reason: ${reason}` : `Your request to borrow ${supplyName} was rejected.`,
                    type: 'supplies',
                    actionId: borrowId,
                    isRead: false,
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                });
            } else if (after.status === 'returned') {
                // If linked to service request, check if all items are returned
                if (serviceRequestId) {
                    // Get all borrowed items for this service request
                    const borrowedSnapshot = await db.collection('borrowed_supplies')
                        .where('serviceRequestId', '==', serviceRequestId)
                        .get();
                    
                    let allReturned = true;
                    borrowedSnapshot.forEach(doc => {
                        if (doc.data().status !== 'returned') {
                            allReturned = false;
                        }
                    });
                    
                    // If all items returned, get service request and check if completed
                    if (allReturned) {
                        const serviceDoc = await db.collection('service_requests').doc(serviceRequestId).get();
                        if (serviceDoc.exists && serviceDoc.data().status === 'completed') {
                            // Mark service as resolved
                            await db.collection('service_requests').doc(serviceRequestId).update({
                                status: 'resolved',
                                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                            });
                            
                            // Send unified notification
                            await db.collection('notifications').add({
                                userId: userId,
                                title: '✅ Service Request Completed',
                                body: 'All borrowed items have been returned and your funeral assistance service has been completed. Thank you!',
                                type: 'service',
                                actionId: serviceRequestId,
                                isRead: false,
                                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                            });
                            
                            console.log(`Service request ${serviceRequestId} marked as resolved - all items returned`);
                        }
                    }
                }
                
                // Send return notification
                await db.collection('notifications').add({
                    userId: userId,
                    title: '📦 Item Returned',
                    body: `${supplyName} has been marked as returned. Thank you!`,
                    type: 'supplies',
                    actionId: borrowId,
                    isRead: false,
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                });
            }
        }
    });

// Trigger when new announcement is created
exports.onAnnouncementCreate = functions.firestore
    .document('announcements/{announcementId}')
    .onCreate(async (snap, context) => {
        const announcement = snap.data();
        
        // Get all approved users
        const usersSnapshot = await db.collection('users')
            .where('accountStatus', 'in', ['approved', 'active'])
            .get();
        
        // Create notification for each user
        const batch = db.batch();
        usersSnapshot.docs.forEach(userDoc => {
            const notifRef = db.collection('notifications').doc();
            batch.set(notifRef, {
                userId: userDoc.id,
                title: `📢 New ${announcement.category} Announcement`,
                body: announcement.title,
                type: 'news',
                isRead: false,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        });
        
        await batch.commit();
        console.log(`Created ${usersSnapshot.size} notifications for new announcement`);
    });
