# URGENT: Deploy Firestore Security Rules

## Problem Identified
Your app has NO Firestore security rules in the project, which likely means:
- Users **cannot read their own account status** from Firestore
- Real-time streams **cannot detect approval changes**
- This is why users stay stuck on pending page even after approval!

## Solution: Deploy the Rules

### Step 1: Login to Firebase
```powershell
firebase login
```
This will open your browser. Log in with your Google account that has access to your Firebase project.

### Step 2: Initialize Firebase (if needed)
If the login asks you to initialize, run:
```powershell
firebase init firestore
```
Select your Firebase project when prompted.

### Step 3: Deploy the Firestore Rules
```powershell
firebase deploy --only firestore:rules
```

### Step 4: Test the App
After deployment:
1. Register a new test user
2. Admin approves the user
3. User should **automatically redirect to homepage within 3-5 seconds**

## What the Rules Do

The new `firestore.rules` file allows:
- ✅ Users can **read** their own user document (enables real-time status updates)
- ✅ Users can create their own profile during registration
- ✅ Users can update their profile (except accountStatus and isAdmin)
- ✅ Admins can read/write all user documents
- ✅ Proper security for reports, service requests, lost/found items

## Why This Fixes the Issue

Before: User's StreamBuilder tries to read `/users/{uid}/accountStatus` but Firestore blocks it → stream never triggers → no redirect

After: User can read their own document → stream detects approval → AuthWrapper rebuilds → redirects to homepage

## Alternative: Deploy via Firebase Console

If you prefer not to use CLI:
1. Go to https://console.firebase.google.com
2. Select your project
3. Go to **Firestore Database** → **Rules** tab
4. Copy the contents of `firestore.rules` 
5. Paste and **Publish**
