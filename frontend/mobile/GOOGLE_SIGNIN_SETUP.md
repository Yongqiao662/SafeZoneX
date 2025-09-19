# Google Sign-In Setup Guide

## Issue
The error `PlatformException(channel-error, Unable to establish connection on channel: "dev.flutter.pigeon.google_sign_in_android.GoogleSignInApi.init"., null, null)` occurs because Google Sign-In is not properly configured for Android.

## Solution Steps

### 1. Google Cloud Console Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the Google Sign-In API:
   - Go to "APIs & Services" > "Library"
   - Search for "Google Sign-In API" and enable it

### 2. Create OAuth 2.0 Credentials

1. Go to "APIs & Services" > "Credentials"
2. Click "Create Credentials" > "OAuth 2.0 Client IDs"
3. Create credentials for:
   - **Android application**:
     - Package name: `com.example.safezonex`
     - SHA-1 certificate fingerprint: Get this by running:
       ```bash
       keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
       ```
   - **Web application** (for server-side verification)

### 3. Download google-services.json

1. Go to "Project Settings" in Firebase Console
2. Add your Android app with package name `com.example.safezonex`
3. Download the `google-services.json` file
4. Place it in `frontend/mobile/android/app/google-services.json`

### 4. Update Package Name (Optional)

If you want to use a different package name:
1. Update `applicationId` in `frontend/mobile/android/app/build.gradle.kts`
2. Update package name in `frontend/mobile/android/app/src/main/AndroidManifest.xml`
3. Update the OAuth client configuration in Google Cloud Console

### 5. Test the Configuration

After completing the setup:
1. Clean and rebuild the project:
   ```bash
   cd frontend/mobile
   flutter clean
   flutter pub get
   flutter run
   ```

## Files Modified

- ✅ `frontend/mobile/android/settings.gradle.kts` - Added Google Services plugin
- ✅ `frontend/mobile/android/app/build.gradle.kts` - Applied Google Services plugin
- 📝 `frontend/mobile/android/app/google-services.json` - **YOU NEED TO ADD THIS FILE**

## Important Notes

- The `google-services.json` file contains sensitive information and should not be committed to version control
- Make sure the package name in the OAuth client matches your app's package name exactly
- The SHA-1 fingerprint must match your debug keystore for development
- For production, you'll need to create a release keystore and update the OAuth client configuration

## Troubleshooting

If you still get errors after setup:
1. Verify the package name matches exactly
2. Check that the SHA-1 fingerprint is correct
3. Ensure the `google-services.json` file is in the correct location
4. Clean and rebuild the project
5. Check that Google Sign-In API is enabled in Google Cloud Console
