# Firebase Cloud Functions Setup for Notifications

## Why Do We Need This?

Your **web admin panel** updates Firestore directly (changes report status, approves users, etc.), but the Flutter app's `NotificationService` never runs. 

**Solution:** Firebase Cloud Functions automatically create notifications whenever Firestore documents are updated.

## 📋 What I Created:

1. **functions/index.js** - Cloud Functions that trigger on Firestore changes
2. **functions/package.json** - Dependencies for Cloud Functions

## 🚀 Setup Instructions:

### Step 1: Install Node.js (if not installed)
1. Download from: https://nodejs.org/ (LTS version recommended)
2. Install with default settings
3. Verify: Open PowerShell and run `node --version`

### Step 2: Initialize Firebase Functions
```powershell
# Navigate to your project
cd "C:\Flutter Projects\KOMUNIDAD"

# Initialize functions (if not already initialized)
firebase init functions

# When prompted:
# ✓ Use existing project: komunidad-36f9b
# ✓ Language: JavaScript
# ✓ ESLint: No (or Yes, up to you)
# ✓ Install dependencies: Yes
```

### Step 3: Install Dependencies
```powershell
cd functions
npm install
cd ..
```

### Step 4: Deploy Cloud Functions
```powershell
firebase deploy --only functions
```

You'll see output like:
```
✔  functions[onReportStatusUpdate]: Successful create operation.
✔  functions[onUserApprovalStatusUpdate]: Successful create operation.
✔  functions[onServiceRequestStatusUpdate]: Successful create operation.
✔  functions[onBorrowStatusUpdate]: Successful create operation.
✔  functions[onAnnouncementCreate]: Successful create operation.
```

### Step 5: Test It!
1. Go to your web admin panel
2. Change a report status from "pending" to "in-progress"3. Open the Flutter app
4. Check the notification bell - you should see a new notification! 🔔

## 📊 Cloud Functions Created:

| Function | Trigger | Creates Notification When |
|----------|---------|---------------------------|
| `onReportStatusUpdate` | Report document updated | Status changes (pending → in-progress → resolved) |
| `onUserApprovalStatusUpdate` | User document updated | Account approved or rejected |
| `onServiceRequestStatusUpdate` | Service request updated | Status changes |
| `onBorrowStatusUpdate` | Borrow request updated | Request approved or rejected |
| `onAnnouncementCreate` | New announcement | New post created |

## 💰 Pricing:

Firebase Cloud Functions require **Blaze (Pay as you go)** plan:
- **Free tier:** 2M invocations/month, 400K GB-seconds/month
- **Your usage:** Very low - only triggers when admin actions happen
- **Estimated cost:** $0/month (well within free tier)

To upgrade:
1. Firebase Console → Project Settings → Usage and Billing
2. Click "Modify plan" → Select "Blaze"
3. Set spending limit to prevent unexpected charges

## 🧪 Testing Without Deploying:

You can test locally first:

```powershell
# Start emulator
firebase emulators:start

# In another terminal, use your app with local emulator
```

Then configure your Flutter app to use the emulator (optional).

## 🔍 Monitoring & Debugging:

### View Function Logs:
```powershell
firebase functions:log
```

### View in Firebase Console:
1. Firebase Console → Functions
2. Click on a function name
3. View logs, metrics, and execution history

## ✅ Verification Checklist:

After deploying, verify in Firebase Console:

- [ ] Functions tab shows 5 deployed functions
- [ ] Each function shows "Healthy" status
- [ ] Update a test report status in web admin
- [ ] Check Firestore → notifications collection for new document
- [ ] Open Flutter app and see notification

## ⚠️ Troubleshooting:

### "Firebase CLI is not authenticated"
```powershell
firebase login
```

### "Functions not deploying"
Check `firebase.json`:
```json
{
  "functions": {
    "source": "functions"
  }
}
```

### "Permission denied"
Make sure you're logged in as the Firebase project owner.

### "Billing account required"
You need to upgrade to Blaze plan (see Pricing section above).

## 📝 Alternative: Quick Fix (No Cloud Functions Needed)

If you don't want to set up Cloud Functions right now, you can manually create notifications:

### When updating report status in web admin:
1. Also create a document in `notifications` collection:
```javascript
{
  userId: "USER_ID_WHO_CREATED_REPORT",
  title: "📋 Report Status Updated",
  body: "Your report is now being processed by the admin team.",
  type: "report",
  actionId: "REPORT_ID",
  isRead: false,
  createdAt: firebase.firestore.FieldValue.serverTimestamp()
}
```

This is tedious but works without Cloud Functions.

## 🎯 Recommendation:

**Set up Cloud Functions** - It's a one-time setup and then notifications work automatically forever!

## Need Help?

If you encounter any issues during setup, let me know which step is failing and I'll help troubleshoot.
