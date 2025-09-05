## 🗝️ Quick Google Maps API Key Setup Guide

### Step 1: Get Your API Key (5 minutes)

1. **Visit Google Cloud Console**: https://console.cloud.google.com/

2. **Create or Select Project**:
   - Click "Select a project" → "New Project"
   - Name: "SafeZoneX-Maps" 
   - Click "Create"

3. **Enable Required APIs** (Click each link):
   - **Maps SDK for Android**: https://console.cloud.google.com/apis/library/maps-android-backend.googleapis.com
   - **Geocoding API**: https://console.cloud.google.com/apis/library/geocoding-backend.googleapis.com
   
   For each API:
   - Click "Enable"
   - Wait for activation

4. **Create API Key**:
   - Go to: https://console.cloud.google.com/apis/credentials
   - Click "Create Credentials" → "API key"
   - **Copy the generated key** (looks like: `AIzaSyBdVl-cTICSwYKpe92909884055EXAMPLE`)

### Step 2: Add Your API Key to SafeZoneX

Open: `android/app/src/main/AndroidManifest.xml`

Find this line:
```xml
<meta-data android:name="com.google.android.geo.API_KEY"
           android:value="YOUR_GOOGLE_MAPS_API_KEY_HERE"/>
```

Replace `YOUR_GOOGLE_MAPS_API_KEY_HERE` with your actual API key:
```xml
<meta-data android:name="com.google.android.geo.API_KEY"
           android:value="AIzaSyBdVl-cTICSwYKpe92909884055EXAMPLE"/>
```

### Step 3: Test Your Integration

1. **Run the app**:
   ```bash
   flutter run
   ```

2. **Navigate to**: Home → Campus Safe Zones

3. **You should see**:
   - ✅ Real Google Map of University Malaya
   - ✅ 8 safety markers on campus locations
   - ✅ Dark theme map styling
   - ✅ Interactive markers with safety scores

### 🛡️ Expected Results:

Your map will show University Malaya campus with these safe zones:
- 🟢 **UM Security Office** (9.8/10) - Green marker
- 🟢 **UM Medical Centre** (9.9/10) - Green marker  
- 🔵 **Perpustakaan Utama UM** (9.2/10) - Blue marker
- 🔵 **Dewan Tunku Canselor** (8.9/10) - Blue marker
- 🔵 **Faculty of Engineering** (8.7/10) - Blue marker
- 🟠 **Student Affairs** (8.5/10) - Orange marker
- 🟠 **4th College** (8.3/10) - Orange marker
- 🟠 **Sports Centre** (8.1/10) - Orange marker

### 🔧 Optional: Secure Your API Key

1. **Go back to**: https://console.cloud.google.com/apis/credentials
2. **Click your API key** to edit
3. **Under "Application restrictions"**:
   - Select "Android apps"
   - Add package name: `com.example.safezonex`
4. **Click "Save"**

### 🎯 Ready to Use!

Once you add your API key, SafeZoneX will have:
- ✅ **Real-time campus mapping**
- ✅ **Interactive safety zones**  
- ✅ **Professional dark theme**
- ✅ **University Malaya integration**

Your campus safety app is now complete! 🚀
