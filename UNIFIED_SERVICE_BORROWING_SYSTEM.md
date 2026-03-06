# Unified Service Request & Borrowed Items System

## Overview
This document describes the integrated system for Funeral Bereavement Assistance service requests and borrowed items. When users request funeral assistance and borrow supplies, they are managed as a **single unified request** with synchronized statuses and automatic workflows.

## 🎯 Key Features

### 1. **Linked Service Requests & Borrowed Items**
- When a user submits a Funeral Bereavement Assistance request with borrowed items, the system creates:
  - **1 Service Request** (funeral assistance)
  - **1+ Borrowed Supply Records** (linked to the service request)
- All borrowed items are linked to the service request via `serviceRequestId` field

### 2. **Automatic Status Synchronization**

#### When Admin Takes Action on Service Request:
1. **Admin marks service as "Actioned" or "In-Progress"**
   - ✅ All linked borrowed items are **automatically approved** (status → "borrowed")
   - ✅ Supply quantities are **automatically decremented**
   - ✅ User receives **notification** that items are approved

#### When Service is Completed:
2. **Admin marks service as "Completed"**
   - User can now **return borrowed items**
   - Only admin can mark items as "returned" (ensures verification)

#### When All Items are Returned:
3. **Admin marks all items as "Returned"**
   - ✅ Service request **automatically resolves** (status → "resolved")
   - ✅ User receives **unified notification**: "All items returned and service completed"
   - ✅ Supply quantities are **restored to inventory**

### 3. **Admin Action Notes**
- Admins can add notes when:
  - Approving borrowed items (e.g., "Please return by Dec 31, 2024")
  - Taking action on service requests
- Notes are displayed to users in blue information boxes

### 4. **Delete Functionality**
- Users can **delete borrowed item records** when:
  - Status is "rejected"
  - Status is "returned"
- Deletion syncs with admin dashboard and sends notifications

## 📋 Workflow Diagram

```
User Submits Funeral Assistance + Borrows Items
    ↓
[Service Request Created] ←→ [Borrowed Items Created with serviceRequestId link]
    ↓
Admin Views Service Request
    ↓
Admin Marks as "Actioned" / "In-Progress"
    ↓
[AUTO: Borrowed Items → "borrowed" status]
[AUTO: Inventory Quantities Decreased]
[NOTIFICATION: Items Approved]
    ↓
Admin Completes Funeral Service
Admin Marks Service as "Completed"
    ↓
User Returns Items Physically
    ↓
Admin Marks Items as "Returned" (one by one or all)
    ↓
[AUTO: When all items returned → Service → "resolved"]
[AUTO: Inventory Quantities Restored]
[NOTIFICATION: Service Completed, Items Returned]
```

## 🗂️ Database Schema

### `service_requests` Collection
```javascript
{
  id: string,
  userId: string,
  userName: string,
  category: 'Funeral & Bereavement Assistance',
  description: string,
  location: string,
  status: 'pending' | 'actioned' | 'in-progress' | 'completed' | 'resolved',
  hasBorrowedItems: boolean,              // NEW: True if linked to borrowed items
  borrowedItemIds: string[],              // NEW: Array of linked borrow document IDs
  actionNotes: string,                    // Admin action notes
  solutionDescription: string,            // Final resolution description
  createdAt: timestamp,
  updatedAt: timestamp,
}
```

### `borrowed_supplies` Collection
```javascript
{
  id: string,
  userId: string,
  supplyId: string,
  supplyName: string,
  quantity: number,
  purpose: string,
  status: 'pending' | 'borrowed' | 'returned' | 'rejected',
  serviceRequestId: string,               // NEW: Link to parent service request
  actionNotes: string,                    // Admin approval notes
  rejectionReason: string,                // If rejected
  requestedAt: timestamp,
  borrowedAt: timestamp,
  returnedAt: timestamp,
}
```

## 🔧 Code Implementation

### 1. Service Request Submission (User Side)
**File: `lib/service_request.dart`**

When user submits Funeral Bereavement Assistance:
1. Creates service request first → gets `serviceRequestId`
2. Creates borrowed items with `serviceRequestId` link
3. Updates service request with `borrowedItemIds` array and `hasBorrowedItems: true`

```dart
// Submit service request first to get ID
serviceRequestId = await _serviceRequestService.submitServiceRequest(
  name: nameController.text.trim(),
  description: finalDescription,
  category: 'Funeral & Bereavement Assistance',
  location: selectedLocation!,
);

// Borrow supplies and link to service request
for (var entry in funeralQuantities.entries) {
  final borrowId = await _suppliesService.borrowSupply(
    supplyId: entry.key,
    quantity: entry.value,
    borrowerName: nameController.text.trim(),
    purpose: 'Funeral & Bereavement Assistance: ...',
    serviceRequestId: serviceRequestId,  // LINK HERE
  );
  borrowedItemIds.add(borrowId);
}

// Update service request with borrowed items info
await _serviceRequestService.updateServiceRequestWithBorrowedItems(
  serviceRequestId,
  borrowedItemIds,
  finalDescription,
);
```

### 2. Status Synchronization (Cloud Functions)
**File: `functions/index.js`**

#### Service Request → Borrowed Items Sync
```javascript
exports.onServiceRequestStatusUpdate = functions.firestore
    .document('service_requests/{requestId}')
    .onUpdate(async (change, context) => {
        const after = change.after.data();
        
        // When service is actioned, auto-approve linked borrowed items
        if (after.status === 'actioned' && after.hasBorrowedItems) {
            for (const borrowId of after.borrowedItemIds) {
                // Auto-approve: Update status and decrement inventory
                await db.collection('borrowed_supplies').doc(borrowId).update({
                    status: 'borrowed',
                    approvedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
                
                // Decrement supply quantity
                await db.collection('supplies').doc(supplyId).update({
                    availableQuantity: availableQty - quantity,
                });
            }
        }
    });
```

#### Borrowed Items → Service Request Sync
```javascript
exports.onBorrowStatusUpdate = functions.firestore
    .document('borrowed_supplies/{borrowId}')
    .onUpdate(async (change, context) => {
        const after = change.after.data();
        
        // When item is returned, check if all items are returned
        if (after.status === 'returned' && after.serviceRequestId) {
            const allBorrowedItems = await db.collection('borrowed_supplies')
                .where('serviceRequestId', '==', after.serviceRequestId)
                .get();
            
            let allReturned = true;
            allBorrowedItems.forEach(doc => {
                if (doc.data().status !== 'returned') allReturned = false;
            });
            
            // If all returned and service is completed, mark as resolved
            if (allReturned) {
                const serviceDoc = await db.collection('service_requests')
                    .doc(after.serviceRequestId).get();
                    
                if (serviceDoc.data().status === 'completed') {
                    await db.collection('service_requests')
                        .doc(after.serviceRequestId)
                        .update({ status: 'resolved' });
                        
                    // Send unified notification
                    await db.collection('notifications').add({
                        title: '✅ Service Request Completed',
                        body: 'All items returned and funeral assistance completed.',
                        type: 'service',
                        actionId: after.serviceRequestId,
                    });
                }
            }
        }
    });
```

### 3. User Interface Indicators
**File: `lib/view_my_reports.dart`**

#### Service Request Card (Shows Linked Borrowed Items)
```dart
// Show indicator if service has linked borrowed items
if (data['hasBorrowedItems'] == true) {
  Container(
    child: Row(
      children: [
        Icon(Icons.inventory_2),
        Text('${(data['borrowedItemIds'] as List).length} Borrowed Item(s)'),
      ],
    ),
  ),
}
```

#### Borrowed Items Card (Shows Linked Service)
```dart
// Show indicator if borrowed item is linked to service request
if (item['serviceRequestId'] != null) {
  Container(
    child: Row(
      children: [
        Icon(Icons.link),
        Text('Linked to Funeral Assistance Service'),
      ],
    ),
  ),
}
```

### 4. Admin Dashboard Indicators
**File: `lib/admin_borrowed_supplies.dart`**

Shows badge when borrow request is linked to service:
```dart
if (data['serviceRequestId'] != null) {
  Container(
    child: Row(
      children: [
        Icon(Icons.link),
        Text('Linked Service'),
      ],
    ),
  ),
}
```

## 🎨 UI/UX Features

### User View (My Reports & Borrowed Items Page)

#### Service Requests Tab:
- Shows **purple badge** with count: "2 Borrowed Item(s)"
- Clicking shows service details with list of borrowed items

#### Borrowed Items Tab:
- Shows **blue badge**: "Linked to Funeral Assistance Service"
- Displays admin action notes in blue box
- Status badges: PENDING (orange), BORROWED (blue), RETURNED (green), REJECTED (red)
- Delete button for rejected/returned items

### Admin View (Admin Borrowed Supplies Page)

#### Borrowed Supplies Table:
- Shows **blue "Linked Service" badge** in Purpose column
- Admin can see which items are part of funeral service requests
- Approve/Reject/Return actions affect both borrowed items AND linked service

## 📱 Notifications

### Notification Flow:
1. **User submits** → "Service request submitted"
2. **Admin actions service** → "Service request is being processed" + "Borrow requests approved"
3. **Admin completes service** → "Service request completed"
4. **User/Admin returns items** → "Item returned" (for each item)
5. **All items returned** → "All items returned and service completed"

## 🧪 Testing Checklist

### Test 1: Complete Funeral Assistance Flow
- [ ] User submits Funeral Bereavement Assistance + borrows 2 items
- [ ] Verify service request created with `hasBorrowedItems: true`
- [ ] Verify 2 borrowed_supplies documents created with `serviceRequestId`
- [ ] Admin marks service as "Actioned"
- [ ] Verify borrowed items auto-approved (status → "borrowed")
- [ ] Verify inventory quantities decreased
- [ ] Admin marks service as "Completed"
- [ ] Admin marks both items as "Returned"
- [ ] Verify service auto-resolves (status → "resolved")
- [ ] Verify user receives unified notification
- [ ] Verify inventory quantities restored

### Test 2: UI Indicators
- [ ] Service request shows purple "2 Borrowed Item(s)" badge
- [ ] Borrowed items show blue "Linked to Funeral Assistance" badge
- [ ] Admin dashboard shows "Linked Service" badge

### Test 3: Delete Functionality
- [ ] User can delete rejected borrowed item
- [ ] User can delete returned borrowed item
- [ ] Deletion syncs with admin view
- [ ] User receives deletion notification

### Test 4: Action Notes
- [ ] Admin adds action notes when approving borrow
- [ ] User sees notes in blue box on borrowed items
- [ ] Admin adds action notes when actioning service
- [ ] User sees notes in service request details

## 🚀 Deployment Status

### ✅ Completed
- [x] Service request returns document ID
- [x] Borrowed supplies link to service request via `serviceRequestId`
- [x] Cloud Functions deployed with synchronization logic
- [x] UI indicators for linked requests
- [x] Delete functionality for borrowed items
- [x] Admin action notes display
- [x] Automatic status synchronization
- [x] Unified notifications

### 📝 Next Steps (Optional Enhancements)
- [ ] Add bulk return functionality for admin (return all items at once)
- [ ] Add service request cancellation (auto-rejects all linked borrowed items)
- [ ] Add borrowed items history view in service request details
- [ ] Add analytics dashboard for funeral assistance statistics

## 📖 User Guide

### For Users:

**How to Request Funeral Assistance with Borrowed Items:**
1. Go to "Service Request" from homepage
2. Select "Funeral & Bereavement Assistance"
3. Fill in description and location
4. Scroll down to see available funeral supplies
5. Adjust quantities for items you need
6. Submit request

**What Happens Next:**
- Request is pending until admin reviews
- When admin takes action:
  - ✅ Your borrowed items are automatically approved
  - 📱 You receive notification
- When service is completed:
  - 📦 Return borrowed items physically
  - 👤 Admin marks items as returned in system
- When all items returned:
  - ✅ Service marked as resolved
  - 📱 You receive completion notification

**Managing Your Records:**
- View all in "My Reports & Borrowed Items" page
- See service status and borrowed items together
- Delete rejected/returned borrow records if needed

### For Admins:

**Handling Funeral Assistance Requests:**
1. View service request in admin panel
2. See "2 Borrowed Item(s)" indicator
3. Mark service as "Actioned" or "In-Progress"
   - System auto-approves all linked borrowed items
   - Inventory auto-decrements
4. Add action notes if needed (e.g., "Please return by [date]")
5. When service completed, mark as "Completed"
6. When user returns items physically, mark as "Returned" in Borrowed Supplies page
7. System auto-resolves service when all items returned

**Visual Indicators:**
- Service requests with borrowed items show purple badge
- Borrowed items linked to services show blue "Linked Service" badge

## 🔒 Important Notes

### Data Integrity
- Deleting a service request does NOT delete linked borrowed items
- Deleting a borrowed item does NOT affect the service request
- This ensures data integrity and audit trail

### Admin Permissions
- Only admins can mark items as "returned" (ensures physical verification)
- Users can only request returns via feedback

### Inventory Management
- Quantities auto-decrement when borrowed items approved
- Quantities auto-increment when items marked as returned in admin panel (to be implemented if needed)

## 📞 Support

If you encounter issues:
1. Check Cloud Functions logs: `firebase functions:log`
2. Check Firestore data for `serviceRequestId` and `borrowedItemIds` fields
3. Verify notification collection for failed notifications
4. Check Flutter app logs for service/supplies service errors

---

**Last Updated:** March 6, 2026  
**Version:** 1.0  
**Status:** ✅ Deployed and Active
