# Admin Action Notes Implementation

## Overview
This document describes the implementation of admin action notes for service requests and borrowed items, allowing admins to add notes when approving/rejecting requests that users will see.

## ✅ What Was Completed (Flutter App)

### 1. Service Requests - Action Notes Display
**File: `lib/view_my_reports.dart`**

- Added `actionNotes` field extraction in `_showServiceRequestDetails()` dialog
- Displays action notes in a blue box labeled "Admin Action Notes:" (separate from green "Admin Response" box)
- Shows when admin has added notes during approval/rejection
- Located before the "Admin Response" (solutionDescription) section

**Visual Design:**
```
┌─────────────────────────────────┐
│ Admin Action Notes:             │
│ ┌─────────────────────────────┐ │
│ │ [Blue background box]       │ │
│ │ Admin's action notes here   │ │
│ └─────────────────────────────┘ │
└─────────────────────────────────┘
```

### 2. Borrowed Items - Action Notes Display
**File: `lib/view_my_reports.dart`**

- Added `actionNotes` field extraction in `_buildBorrowedItemCard()`
- Added "ACTIONED" status badge support (blue badge for approved items)
- Displays action notes in a blue container with admin icon when item is borrowed/actioned
- Shows below rejection reason (if rejected) and above item details

**Visual Design:**
```
┌─────────────────────────────────────┐
│ 📦 Supply Name      [ACTIONED]      │
│ ┌───────────────────────────────┐   │
│ │ 👤 Admin Action Notes:        │   │
│ │ Please return by Dec 31, 2024 │   │
│ └───────────────────────────────┘   │
│ Quantity: 5                         │
│ Purpose: Community event            │
└─────────────────────────────────────┘
```

### 3. Status Badge Updates
**File: `lib/view_my_reports.dart`**

Updated `_buildStatusBadge()` to handle multiple status variations:
- `pending` → Orange "Pending" badge
- `actioned`, `in-progress`, `in_progress` → Blue "Actioned" badge  
- `resolved`, `completed`, `solved` → Green "Resolved" badge

### 4. Borrowed Items - Admin Approval with Action Notes
**Files:**
- `lib/admin_borrowed_supplies.dart`
- `lib/services/supplies_service.dart`

**Changes:**
- Added TextField for action notes in `_confirmApprove()` dialog
- Updated `approveBorrow()` method to accept optional `actionNotes` parameter
- Saves `actionNotes` to Firestore when provided
- Placeholder text: "e.g., 'Please return by Dec 31, 2024'"

**Admin Flow:**
1. Admin clicks "Approve" on a borrow request
2. Dialog shows with action notes text field (optional)
3. Admin can add notes like return dates, special instructions, etc.
4. Notes saved to `borrowed_supplies` collection
5. User sees notes in blue box when viewing borrowed item

## 📋 Implementation Details

### Firestore Schema Changes

**`borrowed_supplies` collection:**
```javascript
{
  userId: string,
  supplyId: string,
  supplyName: string,
  quantity: number,
  purpose: string,
  status: 'pending' | 'borrowed' | 'rejected' | 'returned' | 'actioned',
  requestedAt: timestamp,
  borrowedAt: timestamp,
  approvedAt: timestamp,
  returnedAt: timestamp,
  rejectedAt: timestamp,
  rejectionReason: string,     // existing
  actionNotes: string,          // NEW - added for admin approval notes
}
```

**`service_requests` collection:**
```javascript
{
  userId: string,
  category: string,
  location: string,
  description: string,
  status: 'pending' | 'actioned' | 'in-progress' | 'resolved' | 'completed',
  assignedToName: string,
  solutionDescription: string,  // existing - final resolution
  actionNotes: string,          // NEW - admin's action notes
  rating: number,
  feedbackComment: string,
}
```

### Code Flow

**Borrowed Items Approval:**
```
User submits borrow request
    ↓
Admin opens approval dialog (admin_borrowed_supplies.dart)
    ↓
Admin enters action notes (optional) + clicks Approve
    ↓
supplies_service.approveBorrow(borrowId, actionNotes: "...")
    ↓
Firestore: borrowed_supplies doc updated with status='borrowed', actionNotes
    ↓
Cloud Function (onBorrowStatusUpdate) creates notification
    ↓
User sees notification → Opens "My Reports & Borrowed Items"
    ↓
view_my_reports.dart displays action notes in blue box
```

## 🔧 What Needs to Be Done (React Admin Dashboard)

### Service Requests Admin Panel

**Update the web admin dashboard to include action notes when updating service request status:**

1. Add an "Action Notes" text field when admin changes status to "actioned" or "in-progress"
2. Save the actionNotes to Firestore:
   ```javascript
   await firebase.firestore()
     .collection('service_requests')
     .doc(requestId)
     .update({
       status: 'actioned',
       actionNotes: actionNotesValue,  // NEW field
       updatedAt: firebase.firestore.FieldValue.serverTimestamp(),
     });
   ```

3. Display existing actionNotes in the admin view so admins can see what they previously wrote

**Example React Component Update:**
```jsx
// When admin clicks "Action" or "In Progress" button
const handleActionRequest = async (requestId) => {
  const actionNotes = prompt("Enter action notes (optional):");
  
  await db.collection('service_requests').doc(requestId).update({
    status: 'actioned',
    actionNotes: actionNotes || null,
    actionedAt: firebase.firestore.FieldValue.serverTimestamp(),
    updatedAt: firebase.firestore.FieldValue.serverTimestamp(),
  });
};
```

### Borrowed Supplies Admin Panel

**The Flutter admin app already has actionNotes support**, but if you're also managing borrowed supplies from the React web dashboard:

1. Add an "Action Notes" field when approving borrow requests
2. Save to Firestore:
   ```javascript
   await firebase.firestore()
     .collection('borrowed_supplies')
     .doc(borrowId)
     .update({
       status: 'borrowed',
       actionNotes: actionNotesValue,  // NEW field
       approvedAt: firebase.firestore.FieldValue.serverTimestamp(),
       borrowedAt: firebase.firestore.FieldValue.serverTimestamp(),
     });
   ```

### Cloud Functions Verification

**Check `functions/index.js` - the Cloud Functions already handle notifications, but you may want to include action notes in the notification body:**

**Current onBorrowStatusUpdate:**
```javascript
if (after.status === 'borrowed') {
  await db.collection('notifications').add({
    title: '✅ Borrow Request Approved',
    body: `Your request to borrow ${after.quantity} x ${supplyName} has been approved!`,
    type: 'supplies',
    actionId: borrowId,
    userId: after.userId,
    isRead: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}
```

**Optional Enhancement:**
```javascript
if (after.status === 'borrowed') {
  let body = `Your request to borrow ${after.quantity} x ${supplyName} has been approved!`;
  if (after.actionNotes) {
    body += ` Note: ${after.actionNotes}`;
  }
  
  await db.collection('notifications').add({
    title: '✅ Borrow Request Approved',
    body: body,
    type: 'supplies',
    actionId: borrowId,
    userId: after.userId,
    isRead: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}
```

Similarly for **onServiceRequestStatusUpdate:**
```javascript
if (after.actionNotes && after.status !== before.status) {
  let body = `Your service request status has been updated to: ${after.status}`;
  if (after.actionNotes) {
    body += ` - ${after.actionNotes}`;
  }
  // ... create notification with enhanced body
}
```

## 🧪 Testing Instructions

### Test 1: Borrowed Items Action Notes
1. **Admin (Flutter App):**
   - Go to Profile → Admin Borrowed Supplies
   - Find a pending borrow request
   - Click "Approve"
   - Enter action notes: "Please return by December 31, 2024"
   - Click Approve

2. **User (Flutter App):**
   - Should receive notification "✅ Borrow Request Approved"
   - Click notification → Goes to "My Reports & Borrowed Items" tab
   - Click "Borrowed Items" tab
   - Should see blue "ACTIONED" or "BORROWED" badge
   - Should see blue box with admin icon and text:
     ```
     👤 Admin Action Notes:
     Please return by December 31, 2024
     ```

### Test 2: Service Request Action Notes (When Web Admin is Updated)
1. **Admin (React Web Dashboard):**
   - Open a pending service request
   - Change status to "In Progress" or "Actioned"
   - Enter action notes: "Assigned to Team A, will visit on Monday"
   - Save

2. **User (Flutter App):**
   - Should receive notification
   - Open service request in "Services" tab
   - Tap to view details
   - Should see:
     ```
     Admin Action Notes:
     [Blue box]
     Assigned to Team A, will visit on Monday
     ```

### Test 3: Status Badges
1. Create service requests and borrowed items with different statuses
2. Verify badges display correctly:
   - Pending → Orange "Pending"
   - In-progress/Actioned → Blue "Actioned"
   - Resolved/Completed → Green "Resolved"
   - Rejected (borrowed only) → Red "REJECTED"
   - Returned (borrowed only) → Green "RETURNED"

## 📝 Summary

### Flutter App Status: ✅ READY
- Borrowed items admin UI updated with action notes field
- Service requests and borrowed items display action notes correctly
- Status badges updated to show "Actioned" properly
- All UI components styled consistently

### React Admin Dashboard Status: ⏳ NEEDS UPDATE
- Service requests: Need to add actionNotes field when updating status
- Borrowed supplies: If managed from web, needs actionNotes field
- See "What Needs to Be Done" section above

### Cloud Functions Status: ✅ WORKING (Optional Enhancement Available)
- Current functions create notifications correctly
- Optional: Can enhance notification body to include action notes
- See Cloud Functions Verification section for code examples

## 🎯 User Experience

**Before:**
- User sees generic "Borrow request approved" notification
- No details on return dates or special instructions
- Service requests show status change without context

**After:**
- User sees action notes from admin with specific instructions
- Clear communication about expectations (e.g., return dates)
- Better transparency on service request progress
- Unified "Actioned" status across both request types
