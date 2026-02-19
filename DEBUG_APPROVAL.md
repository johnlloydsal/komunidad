# Debug Approval Issue

## Test Steps:

### 1. Open Terminal and Run App with Logs
```bash
flutter run
```

### 2. Register a New User
- Fill all fields
- Upload ID image
- Click Register
- Should see: "Account Pending Approval" page

### 3. Check Console Logs
Look for these logs after registration:
```
📄 Creating user profile for UID: [uid]
✅ User profile created successfully
⏳ Account pending, showing PendingApprovalPage
```

### 4. On Pending Approval Page
- You'll see "Current Status: pending" text
- Click "Refresh Status" button
- Check console for:
```
🔍 CHECKING STATUS NOW for user: [uid]
📄 Full user document: {email: ..., accountStatus: pending, ...}
📊 Current accountStatus field: pending
```

### 5. Approve User in Admin Panel
- Log in as admin (different device/browser)
- Go to User Management → Pending Users tab  
- Click "Approve" on the user
- Check console for:
```
🔄 Approving user: [uid]
✅ User [uid] approved successfully
✔️ Verified status in Firestore: approved
```

### 6. Watch User's Screen
Within 1-5 seconds, you should see:

**Console logs:**
```
📡 Stream update received for [uid] - exists: true
📊 Stream emitting status for [uid]: approved
✅✅✅ STATUS APPROVED! User should be redirected to HomePage
🔄 Status changed from pending to approved
✅ Account approved, showing HomePage
```

**On Screen:**
- "Current Status" changes from "pending" to "approved"
- Green snackbar appears: "✅ Your account has been approved!"
- **Automatic redirect to HomePage**

### 7. If Still Stuck on Pending Page

Click the "Refresh Status" button and check console:
```
🔍 CHECKING STATUS NOW for user: [uid]
📄 Full user document: {...}
📊 Current accountStatus field: [what is shown here?]
```

## Debugging Checklist:

### ❌ If status shows "pending" after approval:
**Problem**: Firestore update not working
**Solution**: Check Firestore rules, check admin permissions

### ❌ If status shows "approved" but no redirect:
**Problem**: Stream not triggering widget rebuild
**Solution**: Check AuthWrapper StreamBuilder logs

### ❌ If status in document is "approved" but display shows "pending":
**Problem**: Cache issue or stream not updating
**Solution**: Force close app and restart

### ❌ If approval button doesn't work:
**Problem**: Admin permission or Firestore error
**Solution**: Check console for error messages

## Manual Firestore Check:

1. Go to Firebase Console
2. Navigate to Firestore Database
3. Find collection "users"
4. Find the user document by UID
5. Check the "accountStatus" field
6. Should be "approved" after admin clicks approve

## Expected Timeline:

- Admin clicks "Approve": **0 seconds**
- Firestore updates: **< 1 second**
- Stream detects change: **< 2 seconds**
- User sees redirect: **< 3 seconds**
- Backup poll triggers: **5 seconds** (failsafe)

## Common Issues:

1. **Firestore Rules**: Make sure users can read their own document
2. **Network**: Both devices need internet connection
3. **Cache**: Try clearing app data and re-registering
4. **Auth**: Make sure user is actually logged in
