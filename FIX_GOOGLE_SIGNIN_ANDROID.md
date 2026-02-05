# Fix Google Sign-In on Android

## The Problem
Google Sign-In works on Chrome but fails on Android with error:
```
ApiException: 10 - Google Sign-in failed
```

This means **your app is not properly registered with Google** for Android.

## Solution: Add SHA-1 Certificate to Firebase

### Step 1: Get Your SHA-1 Certificate

#### Option A: Debug SHA-1 (For Development/Testing)
Run this command in your project root:

**Windows (PowerShell):**
```powershell
cd android
./gradlew signingReport
```

**Or using keytool directly:**
```powershell
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

#### Option B: If gradlew doesn't work
```powershell
cd "C:\Users\YOUR_USERNAME\.android"
keytool -list -v -keystore debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Look for the **SHA-1** line, it will look like:
```
SHA1: A1:B2:C3:D4:E5:F6:G7:H8:I9:J0:K1:L2:M3:N4:O5:P6:Q7:R8:S9:T0
```

**Copy that entire SHA-1 value!**

### Step 2: Add SHA-1 to Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: **komunidad**
3. Click the ⚙️ **Settings** icon → **Project settings**
4. Scroll down to **Your apps** section
5. Find your Android app (com.example.komunidadapp)
6. Click **Add fingerprint**
7. Paste your SHA-1 certificate
8. Click **Save**

### Step 3: Download Updated google-services.json

1. After adding SHA-1, Firebase will generate a new config
2. In the same page, click **Download google-services.json**
3. Replace the file at: `android/app/google-services.json`
4. Make sure to replace the old one!

### Step 4: Clean and Rebuild

```powershell
# Clean the project
flutter clean

# Get dependencies
flutter pub get

# Rebuild and run
flutter run
```

### Step 5: Test Google Sign-In

1. Open the app on your Android device
2. Try "Continue with Google"
3. It should now work! ✅

## Alternative: Quick Test Command

To quickly get SHA-1, run:
```powershell
cd android; ./gradlew signingReport | Select-String "SHA1"
```

## Troubleshooting

### If gradlew doesn't exist or fails:
The `gradlew` file should be at `android/gradlew`. If it's missing, you can create it by running:
```powershell
cd android
flutter create --platforms=android .
```

### If keytool command not found:
The `keytool` command comes with Java JDK. Make sure you have Android Studio or JDK installed.

### If still not working after adding SHA-1:
1. Make sure you added SHA-1 to the **correct** Firebase project
2. Make sure you downloaded the **new** google-services.json
3. Make sure the package name matches: `com.example.komunidadapp`
4. Try uninstalling the app and reinstalling:
   ```powershell
   flutter clean
   flutter run --release
   ```

## Important Notes

- **Debug SHA-1**: For development/testing
- **Release SHA-1**: For production apps (you'll need this when publishing)
- You need to add **both** if you want to test in debug mode AND release builds
- Each computer you develop on will have a different debug SHA-1

## Why This Happens

- Chrome/Web uses OAuth flow that doesn't require SHA-1
- Android uses Google Play Services which requires SHA-1 for security
- Firebase needs to know which apps are authorized to use Google Sign-In

## After Fixing

Once you add the SHA-1 and download the new google-services.json:
- ✅ Google Sign-In will work on Android
- ✅ Email/Password login still works
- ✅ Everything works the same as Chrome/Web
