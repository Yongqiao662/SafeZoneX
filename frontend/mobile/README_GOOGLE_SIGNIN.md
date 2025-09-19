# Google Sign-In Setup Guide for SafeZoneX

This guide explains how to set up Google Sign-In for the SafeZoneX mobile app. Follow these steps to get Google Sign-In working on your development environment.

## Prerequisites

- Flutter development environment set up
- Android Studio or VS Code with Flutter extensions
- Google account with access to Google Cloud Console
- Firebase project access

## 🚀 Quick Setup for Teammates

**If you're a teammate joining the project, here's the simplified setup:**

1. **Get the `google-services.json` file** from the project maintainer
2. **Place the file** in `frontend/mobile/android/app/google-services.json`
3. **Run the app** - Google Sign-In should work immediately!

**That's it!** The OAuth client IDs and SHA-1 fingerprints are already configured and working.

### 📁 Sharing the google-services.json File

**For Project Maintainers:**

You can share the `google-services.json` file with your teammates in several ways:

1. **Git Repository** (Recommended):
   - Add the file to your repository
   - Teammates can pull the latest version
   - Always up-to-date configuration

2. **Direct File Sharing**:
   - Send via email, Slack, or file sharing service
   - Ensure they place it in the correct location

3. **Team Communication**:
   - Share the file through your team's communication channel
   - Include instructions on where to place it

**File Location**: `frontend/mobile/android/app/google-services.json`

## Step 1: Firebase Project Setup

### 1.1 Access Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `safezonex-maps`
3. If you don't have access, ask the project owner to add you

### 1.2 Add Android App to Firebase
1. In Firebase Console, click "Add app" → Android
2. Use package name: `com.example.safezonex`
3. Download the `google-services.json` file
4. Place it in: `frontend/mobile/android/app/google-services.json`

## Step 2: Google Cloud Console Setup

### 2.1 Access Google Cloud Console
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select project: `safezonex-maps`
3. Navigate to "APIs & Services" → "Credentials"

### 2.2 OAuth 2.0 Client IDs (Already Configured)

**✅ Good News: The OAuth client IDs are already set up and working!**

Your teammates can use the existing OAuth client IDs:

#### Android OAuth Client (Already Created):
- **Client ID**: `413218401489-15aalmfsibsh6fn2pcbh36a94un5ev5q.apps.googleusercontent.com`
- **Package Name**: `com.example.safezonex`
- **Status**: ✅ Ready to use

#### Web OAuth Client (Already Created):
- **Client ID**: `413218401489-td2q4g9cnvoudh69fm0tketpobb7g5ah.apps.googleusercontent.com`
- **Name**: "SafeZoneX Web Client"
- **Status**: ✅ Ready to use

**Note**: Your teammates don't need to create new OAuth clients. They can use the existing ones that are already configured and working.

### 2.3 SHA-1 Fingerprints (Already Configured)

**✅ Good News: The SHA-1 fingerprints are already configured!**

The existing Android OAuth client already includes the necessary SHA-1 fingerprints for development. Your teammates can use the same `google-services.json` file without needing to add their own SHA-1 fingerprints.

**Current SHA-1 Fingerprint in OAuth Client:**
- `3861ee1d14644b4fd45eac212e8eacea4439bad6` (Development/Debug)

**Note**: If teammates encounter issues, they can add their own SHA-1 fingerprints following the steps below, but it's usually not necessary.

#### Optional: Add Your Own SHA-1 Fingerprint (If Needed)

**Only if you encounter Google Sign-In errors:**

1. **Get Your SHA-1 Fingerprint:**
   ```bash
   cd frontend/mobile
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```

2. **Add to OAuth Client:**
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Navigate to "APIs & Services" → "Credentials"
   - Find Android OAuth client: `413218401489-15aalmfsibsh6fn2pcbh36a94un5ev5q.apps.googleusercontent.com`
   - Click "Edit" → "Add fingerprint" → Paste your SHA-1 → "Save"

## Step 3: Update google-services.json

The `google-services.json` file should contain both Android and Web OAuth clients. Here's the structure:

```json
{
  "project_info": {
    "project_number": "413218401489",
    "project_id": "safezonex-maps",
    "storage_bucket": "safezonex-maps.firebasestorage.app"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:413218401489:android:ab0353073af930761b29f0",
        "android_client_info": {
          "package_name": "com.example.safezonex"
        }
      },
      "oauth_client": [
        {
          "client_id": "413218401489-15aalmfsibsh6fn2pcbh36a94un5ev5q.apps.googleusercontent.com",
          "client_type": 1,
          "android_info": {
            "package_name": "com.example.safezonex",
            "certificate_hash": "YOUR_SHA1_FINGERPRINT"
          }
        },
        {
          "client_id": "413218401489-td2q4g9cnvoudh69fm0tketpobb7g5ah.apps.googleusercontent.com",
          "client_type": 3
        }
      ],
      "api_key": [
        {
          "current_key": "AIzaSyBOFGvG-_LPgrYBiy1q1Fc8z47EyWMYlZM"
        }
      ],
      "services": {
        "appinvite_service": {
          "other_platform_oauth_client": [
            {
              "client_id": "413218401489-td2q4g9cnvoudh69fm0tketpobb7g5ah.apps.googleusercontent.com",
              "client_type": 3
            }
          ]
        }
      }
    }
  ],
  "configuration_version": "1"
}
```

## Step 4: Verify Flutter Configuration

### 4.1 Check Dependencies
Ensure these are in `pubspec.yaml`:
```yaml
dependencies:
  google_sign_in: ^6.3.0
  shared_preferences: ^2.2.2
```

### 4.2 Check Android Configuration
Verify these files exist and are configured:

**android/settings.gradle.kts:**
```kotlin
plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.9.1" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
    id("com.google.gms.google-services") version "4.4.0" apply false
}
```

**android/app/build.gradle.kts:**
```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}
```

## Step 5: Test Google Sign-In

### 5.1 Run the App
```bash
cd frontend/mobile
flutter clean
flutter pub get
flutter run
```

### 5.2 Test Sign-In
1. Tap "Sign in with Google" button
2. You should see Google account picker
3. Select your account
4. Should navigate to dashboard

## Troubleshooting

### Common Issues:

#### 1. "PlatformException(channel-error, Unable to establish connection...)"
- **Solution**: Ensure `google-services.json` is in the correct location
- **Check**: `android/app/google-services.json` exists

#### 2. "ApiException: 10" (Google Sign-In Error Code 10)
- **Solution**: Verify SHA-1 fingerprint in Google Cloud Console
- **Check**: Package name matches in Firebase and Google Cloud Console

#### 3. "FormatException: Unexpected character <!DOCTYPE html>"
- **Solution**: Backend server not running (this is expected for now)
- **Status**: App uses fallback authentication with Google data

#### 4. Account picker not showing
- **Solution**: App now forces interactive sign-in
- **Check**: Should see account selection screen every time

### Debug Commands:

```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run

# Check SHA-1 fingerprint
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# Verify google-services.json
cat android/app/google-services.json
```

## Current Configuration

- **Package Name**: `com.example.safezonex`
- **Project ID**: `safezonex-maps`
- **Project Number**: `413218401489`
- **Android Client ID**: `413218401489-15aalmfsibsh6fn2pcbh36a94un5ev5q.apps.googleusercontent.com`
- **Web Client ID**: `413218401489-td2q4g9cnvoudh69fm0tketpobb7g5ah.apps.googleusercontent.com`

## Notes

- **Domain Validation**: Currently disabled for testing
- **Backend Authentication**: Currently bypassed (uses Google data directly)
- **Account Selection**: Always shows account picker
- **Email Support**: Any Google email works (domain validation disabled)

## Support

If you encounter issues:
1. Check this README first
2. Verify all configuration files
3. Check console logs for error messages
4. Contact the project maintainer

---

**Last Updated**: December 2024
**Version**: 1.0
