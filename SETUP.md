# SafeZoneX Setup Guide 🛠️

## Quick Setup (5 Minutes)

### Prerequisites
- **Flutter SDK** (3.0+) - [Download](https://flutter.dev/docs/get-started/install)
- **Android Studio** - [Download](https://developer.android.com/studio)
- **Google Maps API Key** - [Get API Key](https://console.cloud.google.com/)

### Installation

1. **Clone Repository**
   ```bash
   git clone https://github.com/Yongqiao662/SafeZoneX.git
   cd SafeZoneX
   ```

2. **Setup Google Maps API Key**
   ```bash
   # Get API key from Google Cloud Console
   # Enable: Maps SDK for Android, Directions API, Geocoding API
   
   cd frontend/mobile/android
   cp local.properties.example local.properties
   
   # Edit local.properties and add:
   GOOGLE_MAPS_API_KEY=your_actual_api_key_here
   ```

3. **Install Dependencies & Run**
   ```bash
   cd frontend/mobile
   flutter pub get
   flutter run
   ```

## Detailed Setup Instructions

### Google Maps API Setup
1. Visit [Google Cloud Console](https://console.cloud.google.com/)
2. Create or select a project
3. Enable these APIs:
   - Maps SDK for Android
   - Directions API
   - Geocoding API
4. Create API key and restrict to your app
5. Add to `local.properties`

### Troubleshooting

**Maps not loading?**
- Check API key is valid
- Ensure APIs are enabled
- Verify billing is set up

**Route not showing?**
- Enable Directions API
- Check API quotas
- Monitor usage limits

**Face verification not working?**
- Grant camera permissions
- Test on physical device
- Check AndroidManifest permissions

**Flutter SDK issues?**
- Install to `C:\flutter` (not in project folder)
- Update `local.properties` with correct path
- Run `flutter doctor` to verify setup

## Platform Support

| Platform | Status | Features |
|----------|--------|----------|
| Android | ✅ Full | All features |
| iOS | ✅ Full | All features |
| Web | ✅ Dashboard | Monitoring only |

## Security Notes

- ✅ Keep API key in `local.properties`
- ✅ Restrict API key to specific apps
- ❌ Never commit `local.properties`
- ❌ Don't share API keys publicly
