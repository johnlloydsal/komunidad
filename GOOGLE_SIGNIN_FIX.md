# Fix Google Sign-In Error (ApiException: 10)

## Problem
The app shows: `PlatformException(sign_in_failed, com.google.android.gms.common.api.ApiException: 10: , null, null)`

Error code 10 = DEVELOPER_ERROR - This means the SHA-1 fingerprint is not registered in Firebase Console.

## Solution: Add SHA-1 Fingerprint to Firebase

### Step 1: Get Your Debug SHA-1 Fingerprint

**Option A - Using Command Prompt (Easiest):**
```bash
cd %USERPROFILE%\.android
keytool -list -v -keystore debug.keystore -alias androiddebugkey -storepass android -keypass android
```

**Option B - Using PowerShell:**
```powershell
cd $env:USERPROFILE\.android
keytool -list -v -keystore debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Look for the line that says:
```
SHA1: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
```

Copy this SHA-1 fingerprint.

### Step 2: Add SHA-1 to Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **komunidad-36f9b**
3. Click the gear icon ⚙️ > **Project settings**
4. Scroll down to **Your apps** section
5. Find your Android app: `com.example.komunidadapp`
6. Click **Add fingerprint** button
7. Paste your SHA-1 fingerprint
8. Click **Save**

### Step 3: Download Updated google-services.json

1. Still in Firebase Console, on the same page
2. Click **Download google-services.json** button
3. Replace the old file at: `android/app/google-services.json`
4. The new file should have an `oauth_client` with `client_type: 1` (Android client)

### Step 4: Rebuild the App

```bash
flutter clean
flutter pub get
flutter run
```

## Alternative: Use Email/Password Login

If you want to skip Google Sign-In for now, users can create accounts using:
- Email and Password registration (already working)
- Then login with email/password

The Report Issue, Service Request, and all other features will work fine with email/password authentication.

## Verify the Fix

After adding SHA-1 and downloading new google-services.json, your file should look like:

```json
"oauth_client": [
  {
    "client_id": "YOUR-ANDROID-CLIENT-ID.apps.googleusercontent.com",
    "client_type": 1
  },
  {
    "client_id": "888930015901-mcave30gor9qeg98tda2sm58rvop5tsg.apps.googleusercontent.com",
    "client_type": 3
  }
]
```

The `client_type: 1` is the Android OAuth client that's currently missing.
