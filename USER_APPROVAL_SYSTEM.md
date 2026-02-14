# User Approval System

## Overview
The app now has a user approval system where newly registered users must be approved by an admin before they can access the application.

## How It Works

### For New Users:
1. **Registration**: When a user registers, their account is created with `accountStatus: pending`
2. **Pending Page**: After registration, users see a "Pending Approval" page explaining their account is under review
3. **Waiting for Approval**: Users can check their approval status by clicking the "Check Status" button
4. **Access Granted**: Once approved by an admin, users can access the full application

### For Admins:
1. **Access**: Admins can access User Management from their Profile page
2. **Review Pending Users**: See all users waiting for approval with their details
3. **Approve/Reject**: Approve or reject users with a single tap
4. **Monitor All Users**: View all users and their account status
5. **Delete Users**: Permanently delete user accounts and all their records (reports, service requests, lost & found items)

## Files Modified/Created

### New Files:
- `lib/pending_approval.dart` - Page shown to users awaiting approval
- `lib/admin_user_management.dart` - Admin panel for managing user approvals
- `USER_APPROVAL_SYSTEM.md` - This documentation file

### Modified Files:
- `lib/register.dart` - Sets new users to pending status
- `lib/auth_wrapper.dart` - Checks account status and routes accordingly
- `lib/profile.dart` - Added admin panel access for admin users
- `lib/services/user_service.dart` - Added methods for approval management:
  - `getAccountStatus()` - Get user's account status
  - `streamAccountStatus()` - Stream user's account status
  - `streamPendingUsers()` - Get all pending users
  - `approveUser()` - Approve a user
  - `rejectUser()` - Reject a user
  - `streamAllUsers()` - Get all users
  - `deleteUserAndRecords()` - Delete user and all their records (reports, service requests, lost & found items)

## Setting Up the First Admin

Since all new users require approval, you need to manually set up the first admin user in your Firestore database:

### Option 1: Firestore Console (Recommended)
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to Firestore Database
4. Find the `users` collection
5. Select a user document (by their UID)
6. Add/Edit the following fields:
   ```
   isAdmin: true (boolean)
   accountStatus: "approved" (string)
   ```
7. Save the changes

### Option 2: Using a Script
You can temporarily modify the registration to make the first user an admin:

In `lib/services/user_service.dart`, temporarily modify `createUserProfile()`:
```dart
Map<String, dynamic> userData = {
  'email': email,
  'displayName': displayName ?? email.split('@')[0],
  'photoUrl': photoUrl,
  'username': finalUsername,
  'createdAt': FieldValue.serverTimestamp(),
  'updatedAt': FieldValue.serverTimestamp(),
  'isAdmin': true,  // ADD THIS LINE TEMPORARILY
  'accountStatus': 'approved',  // ADD THIS LINE TEMPORARILY
};
```

**Important**: Remove these lines after creating your first admin account!

## Account Status Values

- `pending` - User registered but not yet approved
- `approved` - User can access the application  
- `rejected` - User registration was rejected (still shows pending page)

## User Experience Flow

```
Register → Pending Page → Admin Approves → Full Access
      ↓            ↓
   Creates      Can check      
   account      status &
   (pending)    logout
```

## Admin Features

### Pending Users Tab
- Shows all users with `accountStatus: pending`
- Displays user information (name, email, phone, registration date)
- Quick approve/reject buttons
- Real-time updates when users are approved/rejected

### All Users Tab
- Shows all registered users regardless of status
- Color-coded status indicators:
  - 🟢 Green (Approved)
  - 🟠 Orange (Pending)
  - 🔴 Red (Rejected)
- Admin badges for admin users
- Sorted by registration date (newest first)
- **Delete Button**: Permanently delete user accounts and all their data
  - Shows confirmation dialog with warning about what will be deleted
  - Cannot delete admin accounts (delete button not shown)
  - Deletes all user records including:
    - Reports
    - Service requests
    - Lost items
    - Found items
    - User profile

## Security Considerations

1. **Admin Check**: User management page checks if the user is an admin before showing content
2. **Firestore Rules**: You should add Firestore security rules to protect user data:

```javascript
// In Firestore Rules
match /users/{userId} {
  // Users can read their own data
  allow read: if request.auth != null && request.auth.uid == userId;
  
  // Only admins can approve/reject users
  allow update: if request.auth != null && 
                get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
}
```

## Testing the System

1. **Create a test user**: Register a new account
2. **Verify pending state**: You should see the pending approval page
3. **Login as admin**: Use your admin account
4. **Navigate to User Management**: Profile → User Management
5. **Approve the test user**: Click approve on the pending user
6. **Verify access**: The test user should now have full access

## Troubleshooting

### Users stuck on pending page even after approval:
- The page uses real-time listeners, so it should update automatically
- Users can click "Check Status" to manually refresh
- If still stuck, check Firestore to verify `accountStatus: approved` is set

### Admin can't see User Management:
- Verify `isAdmin: true` is set in Firestore
- Check the profile page is loading correctly
- Try logging out and back in

### New users don't go to pending page:
- Check that `accountStatus: pending` is being set during registration
- Verify auth_wrapper.dart is checking account status
- Check for any errors in the console

- Soft delete with data retention period

## Delete User Feature

### How It Works
Admins can permanently delete user accounts from the "All Users" tab. When a user is deleted:

1. **Confirmation Dialog**: Shows a clear warning about what will be permanently deleted
2. **Cascade Deletion**: Automatically deletes all associated records:
   - All reports submitted by the user
   - All service requests
   - All lost items reported
   - All found items submitted
   - User profile document
3. **Safety Measures**:
   - Cannot delete admin accounts (button not shown for admins)
   - Requires explicit confirmation
   - Shows clear warning message about data loss

### Using the Delete Feature

1. Navigate to **Profile → User Management → All Users**
2. Find the user you want to delete
3. Click **"Delete Account & All Records"** button
4. Review the confirmation dialog
5. Click **"Delete"** to confirm or **"Cancel"** to abort

⚠️ **Warning**: Deletion is permanent and cannot be undone. All user data will be permanently removed from the database.
## Future Enhancements

Possible improvements to the system:
- Email notifications when users are approved/rejected
- Rejection reason field
- Bulk approve/reject
- User search and filtering
- Admin notes on user accounts
- Approval history and audit log
