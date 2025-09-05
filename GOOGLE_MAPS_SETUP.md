# Google Maps API Setup Instructions for SafeZoneX

## 📋 Prerequisites
- Google Cloud Platform account
- Flutter project with SafeZoneX

## 🔧 Step-by-Step Setup

### 1. Get Google Maps API Key

1. **Go to Google Cloud Console**: https://console.cloud.google.com/
2. **Create or Select a Project**
3. **Enable APIs**:
   - Go to "APIs & Services" > "Library"
   - Search and enable:
     - Maps SDK for Android
     - Maps SDK for iOS
     - Geocoding API
     - Places API

4. **Create API Key**:
   - Go to "APIs & Services" > "Credentials"
   - Click "Create Credentials" > "API Key"
   - Copy the API key

5. **Secure the API Key** (Optional but recommended):
   - Click on your API key to edit
   - Under "Application restrictions", select:
     - For Android: "Android apps" and add your package name
     - For iOS: "iOS apps" and add your bundle identifier

### 2. Configure Android

1. **Open**: `android/app/src/main/AndroidManifest.xml`
2. **Replace** `YOUR_GOOGLE_MAPS_API_KEY_HERE` with your actual API key:

```xml
<meta-data android:name="com.google.android.geo.API_KEY"
           android:value="YOUR_ACTUAL_API_KEY_HERE"/>
```

### 3. Configure iOS

1. **Open**: `ios/Runner/AppDelegate.swift`
2. **Add** this import at the top:
```swift
import GoogleMaps
```

3. **Add** this line in the `application` method:
```swift
GMSServices.provideAPIKey("YOUR_ACTUAL_API_KEY_HERE")
```

### 4. Update Dependencies

The `google_maps_flutter: ^2.5.0` package is already added to `pubspec.yaml`.

Run:
```bash
flutter pub get
```

### 5. Activate Google Maps in Code

In `lib/screens/map_screen.dart`:

1. **Uncomment** the imports:
```dart
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
```

2. **Uncomment** the Google Maps variables:
```dart
Completer<GoogleMapController> _controller = Completer();
static const CameraPosition _universityMalaya = CameraPosition(
  target: LatLng(3.1225, 101.6532),
  zoom: 16.0,
);
Set<Marker> _markers = {};
```

3. **Uncomment** the marker creation methods in `initState()`:
```dart
_createMarkers();
```

4. **Replace** `_buildMapSection()` with the Google Maps widget (commented code is provided).

### 6. Test the Integration

1. **Run** the app:
```bash
flutter run
```

2. **Navigate** to "Campus Safe Zones" from the home screen
3. **Verify** that the Google Map loads with University Malaya location
4. **Check** that safe zone markers appear on the map

## 🎯 University Malaya Coordinates

- **Latitude**: 3.1225
- **Longitude**: 101.6532
- **Zoom Level**: 16.0 (optimal for campus view)

## 🛡️ Safe Zone Locations Configured

1. **UM Security Office** - Main Campus (9.8/10)
2. **Perpustakaan Utama UM** - Library (9.2/10)
3. **Dewan Tunku Canselor** - Event Hall (8.9/10)
4. **Faculty of Engineering** - Academic (8.7/10)
5. **UM Medical Centre** - Medical (9.9/10)
6. **Student Affairs Division** - Services (8.5/10)
7. **Kolej Kediaman 4th College** - Residential (8.3/10)
8. **UM Sports Centre** - Sports (8.1/10)

## 🎨 Features Ready

- ✅ **Interactive Campus Map** with real coordinates
- ✅ **Color-coded Safety Markers** (Green: 9.0+, Blue: 8.5+, Orange: 8.0+)
- ✅ **Marker Info Windows** with safety scores
- ✅ **Dark Theme Integration** matching SafeZoneX design
- ✅ **Real-time Location** support
- ✅ **Custom Map Styling** options available

## 🔍 Troubleshooting

### Common Issues:
1. **Map not loading**: Check API key configuration
2. **Markers not showing**: Verify marker creation code is uncommented
3. **Location permission**: Ensure location permissions are granted
4. **Build errors**: Run `flutter clean` then `flutter pub get`

### Debug Steps:
1. Check Android/iOS logs for API key errors
2. Verify API key has correct restrictions
3. Ensure all required APIs are enabled in Google Cloud Console

## 🚀 Ready to Use!

Once configured, your SafeZoneX app will have:
- **Real Google Maps** integration
- **University Malaya campus** view
- **Interactive safe zone markers**
- **Professional campus safety mapping**

Your users can now see real-time campus safety information on an actual Google Map! 🗺️✨
