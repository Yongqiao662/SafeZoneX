# Fix Google Sign-In Error Code 10

## Current Configuration
- **Package Name**: `com.example.safezonex`
- **SHA-1 Fingerprint**: `38:61:EE:1D:14:64:4B:4F:D4:5E:AC:21:2E:8E:AC:EA:44:39:BA:D6`
- **Project ID**: `safezonex-maps`
- **Client ID**: `413218401489-15aalmfsibsh6fn2pcbh36a94un5ev5q.apps.googleusercontent.com`

## Error Code 10 Fix Steps

### Step 1: Update OAuth Client in Google Cloud Console

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project: `safezonex-maps`
3. Navigate to **APIs & Services** > **Credentials**
4. Find your OAuth 2.0 Client ID: `413218401489-15aalmfsibsh6fn2pcbh36a94un5ev5q.apps.googleusercontent.com`
5. Click on it to edit

### Step 2: Update Android Client Configuration

In the OAuth client settings:

1. **Package name**: `com.example.safezonex`
2. **SHA-1 certificate fingerprint**: `38:61:EE:1D:14:64:4B:4F:D4:5E:AC:21:2E:8E:AC:EA:44:39:BA:D6`

**Important**: Make sure there are NO spaces in the SHA-1 fingerprint when you paste it.

### Step 3: Download Updated google-services.json

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `safezonex-maps`
3. Go to **Project Settings** (gear icon)
4. Scroll down to **Your apps** section
5. Find your Android app with package name `com.example.safezonex`
6. Click **Download google-services.json**
7. Replace the existing file at `frontend/mobile/android/app/google-services.json`

### Step 4: Alternative - Create New OAuth Client

If the above doesn't work, create a new OAuth client:

1. In Google Cloud Console, go to **APIs & Services** > **Credentials**
2. Click **Create Credentials** > **OAuth 2.0 Client IDs**
3. Select **Android** as application type
4. Enter:
   - **Name**: SafeZoneX Android
   - **Package name**: `com.example.safezonex`
   - **SHA-1 certificate fingerprint**: `38:61:EE:1D:14:64:4B:4F:D4:5E:AC:21:2E:8E:AC:EA:44:39:BA:D6`
5. Click **Create**

### Step 5: Test the Fix

After updating the configuration:

1. Clean and rebuild the app:
   ```bash
   cd frontend/mobile
   flutter clean
   flutter pub get
   flutter run
   ```

2. Test Google Sign-In with a `.siswa.um.edu.my` email

## Common Issues

- **SHA-1 mismatch**: Double-check the fingerprint is exactly `38:61:EE:1D:14:64:4B:4F:D4:5E:AC:21:2E:8E:AC:EA:44:39:BA:D6`
- **Package name mismatch**: Ensure it's exactly `com.example.safezonex`
- **Caching**: Sometimes Google services cache the old configuration - wait a few minutes after updating
- **Multiple OAuth clients**: Make sure you're using the correct client ID

## Verification

To verify your configuration is correct:
1. The OAuth client should show "Verified" status
2. The SHA-1 fingerprint should match exactly
3. The package name should match exactly
4. The google-services.json should be in the correct location

## Still Having Issues?

If you're still getting error code 10:
1. Try creating a completely new OAuth client
2. Make sure Google Sign-In API is enabled in your project
3. Check that the google-services.json file is properly formatted
4. Verify the package name in AndroidManifest.xml matches the OAuth client
