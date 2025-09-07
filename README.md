# SafeZoneX 🛡️

**Your Campus Safety in One Tap**

SafeZoneX is a comprehensive campus safety application designed to provide students, faculty, and staff with immediate access to emergency services, real-time safety features, and community support systems.

---

## 🚨 Problem Statement

Campus safety is a critical concern for educational institutions worldwide. Traditional safety systems often suffer from:

- **Slow Response Times**: Emergency calls can take precious minutes to connect
- **Location Uncertainty**: Responders struggle to locate individuals in distress
- **Isolation During Emergencies**: Students feel unsafe walking alone, especially at night
- **Communication Barriers**: Difficulty reaching help when unable to speak
- **Lack of Real-Time Monitoring**: Security teams can't track active emergencies effectively
- **Limited Community Support**: No easy way to find walking companions or safety buddies

---

## 💡 How SafeZoneX Solves These Problems

### 🎯 **Instant Emergency Response**
- **One-Tap SOS**: Emergency alerts sent with GPS location in under 2 seconds
- **Real-Time Tracking**: Live location sharing with security teams and emergency contacts
- **Silent Alerts**: Discrete emergency notifications when unable to speak

### 📍 **Precision Location Services**
- **GPS Integration**: Exact coordinates sent automatically with every alert
- **Campus Mapping**: Detailed indoor/outdoor location identification
- **Address Translation**: Human-readable location descriptions for responders

### 👥 **Community Safety Network**
- **Walking Partners**: Find verified companions for safe campus navigation
- **Buddy System**: Connect with other students for mutual safety support
- **Real-Time Matching**: Instant partner matching based on location and destination

### 🔄 **Comprehensive Monitoring**
- **Multi-Platform Sync**: Real-time alerts across mobile and web dashboards
- **Status Tracking**: Emergency acknowledgment and resolution workflows
- **Response Analytics**: Track response times and safety metrics

---

## 🚀 Core Features

### 📱 **Mobile Application**

#### 🆘 **Emergency SOS System**
- **Guardian Pulse**: Large, accessible SOS button with red alert theming
- **Instant Alerts**: Send emergency notifications with real-time GPS location
- **End-to-End Location Tracking**: Continuous location monitoring during emergencies
- **Emergency Contacts**: Automatic notification to pre-configured contacts and authorities
- **Active Emergency Screen**: Real-time status updates during emergencies
- **Public Safety Dispatch**: Direct alerts to campus security and emergency services

#### � **Advanced Location Tracking & Monitoring**
- **Real-Time GPS Tracking**: Continuous location updates with high accuracy
- **Emergency Location Broadcasting**: Automatic location sharing during SOS alerts
- **Background Location Monitoring**: Location tracking continues even when app is backgrounded
- **Geofencing & Safe Zones**: Monitor entry/exit from designated safe areas
- **Location History**: Track movement patterns for safety analysis
- **Multi-Platform Location Sync**: Location data shared across mobile and web platforms
- **Permission Management**: Granular control over location sharing preferences

#### 🚨 **Campus Security Integration**
- **Authority Alerting System**: Direct notifications to campus security and police
- **Suspicious Activity Reporting**: Report and tip off security about concerning behavior
- **Real-Time Monitoring Dashboard**: Security teams can track all active emergencies
- **Response Coordination**: Tools for authorities to manage and respond to incidents
- **Evidence Collection**: Automatic capture of location and time data for investigations

#### �🚶‍♂️ **Walk With Me Partnership**
- **Partner Finding**: Search for walking companions by destination
- **Profile Matching**: View partner profiles with safety ratings
- **Request System**: Send and receive walking partner requests
- **Active Tracking**: Real-time location sharing during walks
- **Completion Confirmation**: Safe arrival notifications
- **Route Monitoring**: Track walking routes for safety verification

#### 💬 **Live Chat Support**
- **Floating Chat Window**: Overlay chat without leaving current screen
- **24/7 Support**: Connect with campus security or counselors
- **Emergency Chat**: Silent communication during crisis situations
- **Multi-Language Support**: Accessibility support for diverse campus populations

#### 🎨 **Enhanced User Experience & Accessibility**
- **Dark Theme Design**: Consistent, professional interface
- **Smooth Animations**: Polished transitions and micro-interactions
- **Splash Screen**: Branded loading experience with progress indicators
- **Intuitive Navigation**: Simplified 3-tab bottom navigation
- **Text-to-Speech Support**: Accessibility features for visually impaired users
- **High Contrast Mode**: Enhanced visibility options
- **Large Text Support**: Adjustable font sizes for better readability

### 🖥️ **Web Dashboard (Real-Time Monitoring)**

#### 📊 **Emergency Command Center**
- **Live Alert Feed**: Real-time SOS notifications from mobile users with GPS coordinates
- **Interactive Location Maps**: Visual representation of emergency locations
- **Status Management**: Acknowledge and resolve emergency alerts
- **Statistics Dashboard**: Track active, acknowledged, and resolved emergencies
- **Connection Monitoring**: WebSocket connection status indicators
- **Authority Coordination**: Tools for dispatching and coordinating emergency response

#### 🔔 **Notification System**
- **Browser Alerts**: Instant pop-up notifications for new emergencies
- **Visual Indicators**: Color-coded alert status (Red/Orange/Green)
- **Audio Alerts**: Sound notifications for critical emergencies
- **Auto-Focus**: Automatic tab focus on emergency notifications

#### 🗺️ **Location Services**
- **GPS Coordinates**: Exact latitude/longitude display
- **Address Information**: Human-readable location descriptions
- **Map Integration**: Quick access to location visualization
- **Multi-User Tracking**: Monitor multiple active emergencies

---

## ⭐ Extra Features

### 🔐 **Security & Privacy**
- **Data Encryption**: All communications encrypted in transit
- **Privacy Controls**: User control over location sharing permissions
- **Secure Authentication**: Protected login and profile management
- **Anonymous Options**: Anonymous chat and reporting capabilities

### 🌐 **Cross-Platform Synchronization**
- **Real-Time WebSocket**: Instant communication between mobile and web
- **Multi-Device Support**: Access from phones, tablets, and computers
- **Cloud Backup**: Secure profile and preference synchronization
- **Offline Capabilities**: Core features work without internet connection

### 📈 **Analytics & Insights**
- **Response Time Tracking**: Monitor emergency response effectiveness
- **Usage Statistics**: Track feature utilization and user engagement
- **Safety Reports**: Generate campus safety analytics and trends
- **Performance Metrics**: System uptime and reliability monitoring

### 🎨 **Customization**
- **Campus Branding**: Customizable colors and logos for institutions
- **Feature Toggles**: Enable/disable features based on campus needs
- **Language Support**: Multi-language interface options
- **Accessibility**: Screen reader support and high contrast modes

---

## � Quick Start Guide

### �📋 Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK** (3.0+) - [Download](https://flutter.dev/docs/get-started/install)
- **Dart SDK** (included with Flutter)
- **Android Studio** - [Download](https://developer.android.com/studio)
- **VS Code** (recommended) - [Download](https://code.visualstudio.com/)
- **Google Maps API Key** - [Get API Key](#-google-maps-api-setup)

### ⚡ Quick Setup (5 Minutes)

1. **Clone the Repository**
   ```bash
   git clone https://github.com/yourusername/SafeZoneX.git
   cd SafeZoneX
   ```

2. **Setup Google Maps API Key** 🗺️
   ```bash
   # Step 1: Get your API key from Google Cloud Console
   # Visit: https://console.cloud.google.com/
   
   # Step 2: Copy the API key configuration file
   cd frontend/mobile/android
   cp local.properties.example local.properties
   
   # Step 3: Edit local.properties and add your API key
   # Replace 'your_google_maps_api_key_here' with your actual key
   ```

3. **Install Dependencies**
   ```bash
   cd frontend/mobile
   C:\flutter\bin\flutter pub get
   ```

4. **Run the App**
   ```bash
   C:\flutter\bin\flutter run
   ```

🎉 **That's it!** The app should now be running on your device/emulator.

**Note:** If you haven't installed Flutter properly, see the [detailed setup instructions](#-detailed-setup-instructions) below.

---

## 🔧 Detailed Setup Instructions

### 🗺️ **Google Maps API Setup** (Required)

**⚠️ IMPORTANT: This step is required for the app to work properly**

#### Step 1: Get Your API Key
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Enable these APIs:
   ```
   ✓ Maps SDK for Android
   ✓ Maps SDK for iOS
   ✓ Geocoding API
   ✓ Directions API
   ✓ Places API (optional)
   ```
4. Go to "Credentials" → "Create Credentials" → "API Key"
5. Copy your API key (starts with `AIza...`)

#### Step 2: Add API Key to Project
1. Navigate to the Android configuration:
   ```bash
   cd SafeZoneX/frontend/mobile/android
   ```

2. Copy the example file:
   ```bash
   cp local.properties.example local.properties
   ```

3. Edit `local.properties` and replace the placeholder:
   ```properties
   GOOGLE_MAPS_API_KEY=your_actual_api_key_here
   ```

4. **NEVER commit this file to git** - it contains your secret API key!

#### Step 3: Secure Your API Key
1. In Google Cloud Console → Credentials
2. Click on your API key to edit it
3. Set "Application restrictions" → "Android apps"
4. Add your app's SHA-1 fingerprint:
   ```bash
   # Get SHA-1 fingerprint
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```

#### Step 4: For iOS (Optional)
If you plan to build for iOS, add your API key to `ios/Runner/AppDelegate.swift`:
```swift
GMSServices.provideAPIKey("YOUR_API_KEY_HERE")
```

### 📁 **Local Properties Configuration** (Critical Setup)

The `local.properties` file contains essential configuration for Android builds and Google Maps integration. This file is **required** for the app to compile and function properly.

#### Step 1: Create local.properties File
```bash
cd SafeZoneX/frontend/mobile/android
cp local.properties.example local.properties
```

#### Step 2: Configure Required Properties
Edit the `local.properties` file with your system-specific paths and API key:

```properties
# Android SDK path (required for compilation)
sdk.dir=C:\\Users\\YourUsername\\AppData\\Local\\Android\\sdk

# Flutter SDK path (must match your Flutter installation)
flutter.sdk=C:\\flutter

# Build configuration
flutter.buildMode=debug
flutter.versionName=1.0.0
flutter.versionCode=1

# Google Maps API Key (REQUIRED - replace with your actual key)
GOOGLE_MAPS_API_KEY=''
```

#### Step 3: Find Your SDK Paths

**For Android SDK:**
- **Windows**: `C:\Users\[Username]\AppData\Local\Android\sdk`
- **macOS**: `~/Library/Android/sdk`
- **Linux**: `~/Android/Sdk`

**For Flutter SDK:**
- **Recommended**: Download and extract to `C:\flutter` from https://docs.flutter.dev/get-started/install/windows
- **Windows (typical)**: `C:\flutter`
- **Alternative locations**: `C:\src\flutter`
- **macOS**: `/usr/local/flutter` or `~/flutter`
- **Linux**: `/usr/local/flutter` or `~/flutter`
- **⚠️ DO NOT** install Flutter inside project folders

#### Step 4: Proper Flutter Installation
If you haven't installed Flutter properly:

1. **Download Flutter SDK:**
   ```bash
   # Download from: https://docs.flutter.dev/get-started/install/windows
   # Extract the ZIP file to C:\flutter (NOT inside any project folder)
   ```

2. **Add to System PATH (Optional but recommended):**
   - Search "Environment Variables" in Windows
   - Edit system PATH variable
   - Add: `C:\flutter\bin`

3. **Verify Installation:**
   ```bash
   C:\flutter\bin\flutter --version
   C:\flutter\bin\flutter doctor
   ```

#### Step 5: Verify Configuration
Run these commands to verify everything is set up correctly:

```bash
# Check Flutter configuration
C:\flutter\bin\flutter doctor

# Navigate to project directory
cd SafeZoneX/frontend/mobile

# Verify dependencies
C:\flutter\bin\flutter pub get

# Test compilation
C:\flutter\bin\flutter build apk --debug
```

#### ⚠️ **Important Notes:**

1. **Never commit `local.properties` to version control** - it contains sensitive information
2. **Use double backslashes** (`\\`) in Windows paths
3. **Replace placeholder API key** with your actual Google Maps API key
4. **Ensure paths exist** on your system before running the app
5. **Flutter must be in a system location** - NOT inside project folders

#### 🔧 **Troubleshooting:**

**If you see "Target file not found" errors:**
- Verify your Flutter SDK path is correct in `local.properties`
- Ensure Flutter is installed at `C:\flutter`, not inside a project folder
- Run `C:\flutter\bin\flutter clean` and `C:\flutter\bin\flutter pub get`

**If you see "flutter.sdk=E:\AngelGuide\..." path:**
- This indicates Flutter is incorrectly installed inside another project
- Download proper Flutter installation and extract to `C:\flutter`
- Update `local.properties` with `flutter.sdk=C:\\flutter`

**If Google Maps doesn't load or shows blank with Google logo:**
- Check your Google Maps API key is valid and properly formatted
- Ensure Maps SDK for Android is enabled in Google Cloud Console
- Verify your API key has no restrictions that block your app
- Add your app's package name and SHA-1 fingerprint to API key restrictions

**If map markers/pins don't appear:**
- Ensure Flutter SDK path is correct (common cause of missing markers)
- Check console for marker creation debug messages
- Verify location permissions are granted

**If you see "ImageReader_JNI" warnings:**
- These are harmless warnings related to camera/image processing
- App functionality is not affected
- Warnings may appear when using Google Maps or camera features

**If compilation fails:**
- Update Android SDK path to match your installation
- Ensure all required dependencies are installed

#### Step 5: Location Configuration (Important)
The app currently uses demo coordinates for testing. For production:
1. Update campus location coordinates in `lib/screens/walk_with_me.dart`
2. Replace demo coordinates with your actual campus coordinates
3. Configure campus buildings and landmarks
4. Test location services work correctly in your area

---

## 🚨 **Common Setup Issues & Solutions**

### Issue 1: "Target file lib\main.dart not found"
**Cause:** Incorrect Flutter SDK path in `local.properties`
**Solution:**
```bash
# Check your Flutter installation
C:\flutter\bin\flutter --version

# Update local.properties
flutter.sdk=C:\\flutter

# Clean and rebuild
C:\flutter\bin\flutter clean
C:\flutter\bin\flutter pub get
```

### Issue 2: Google Maps shows blank with only Google logo
**Cause:** Missing or invalid Google Maps API key
**Solution:**
1. Get API key from Google Cloud Console
2. Enable Maps SDK for Android
3. Add key to `local.properties`: `GOOGLE_MAPS_API_KEY=YOUR_KEY_HERE`
4. Add app package name to API key restrictions

### Issue 3: Map markers/pins not visible
**Cause:** Flutter compilation issues due to incorrect SDK path
**Solution:**
```bash
# Ensure proper Flutter installation
flutter.sdk=C:\\flutter  # NOT inside project folders

# Force marker refresh
C:\flutter\bin\flutter clean
C:\flutter\bin\flutter pub get
```

### Issue 4: "ImageReader_JNI" warnings in console
**Cause:** Normal warnings from camera/image processing
**Solution:** These are harmless warnings - app functionality is not affected

### Issue 5: Flutter installed in project folder (AngelGuide path)
**Cause:** Flutter incorrectly installed inside another project
**Solution:**
1. Download Flutter from https://docs.flutter.dev/get-started/install/windows
2. Extract to `C:\flutter` (system location)
3. Update `local.properties` with correct path
4. Clean and rebuild project

---

### 🔒 **Security Best Practices**

- ✅ **DO**: Keep your API key in `local.properties`
- ✅ **DO**: Restrict your API key to specific apps and APIs
- ✅ **DO**: Monitor your API usage in Google Cloud Console
- ❌ **DON'T**: Commit `local.properties` to version control
- ❌ **DON'T**: Share your API key publicly
- ❌ **DON'T**: Use unrestricted API keys

---

## 📱 Platform-Specific Setup

### 🛠️ **Development Environment**

#### **Flutter SDK**
```bash
# Download from: https://flutter.dev/docs/get-started/install
# Version: 3.0.0 or higher
flutter --version
```

#### **IDE Setup**
- **Visual Studio Code** with Flutter extension
- **Android Studio** with Flutter plugin
- **Xcode** (for iOS development on macOS)

#### **Platform SDKs**
- **Android SDK** (API level 21+)
- **iOS SDK** (iOS 11.0+)
- **Web Browser** (Chrome recommended for development)

#### **Google Maps API Setup** 🗺️
**Required for location services and mapping features**

1. **Get Google Maps API Key**:
   ```bash
   # Visit Google Cloud Console
   https://console.cloud.google.com/
   
   # Create or select a project
   # Enable these APIs:
   - Maps SDK for Android
   - Maps SDK for iOS 
   - Geocoding API
   - Directions API
   - Places API
   ```

2. **Configure API Key**:
   ```bash
   # Copy local.properties.example to local.properties
   cd SafeZoneX/frontend/mobile/android
   cp local.properties.example local.properties
   
   # Edit local.properties and add your API key:
   GOOGLE_MAPS_API_KEY=your_actual_api_key_here
   ```

3. **Security Setup**:
   ```bash
   # In Google Cloud Console > Credentials:
   # 1. Restrict API key by application (Android apps)
   # 2. Add your app's SHA-1 fingerprint
   # 3. Restrict APIs to only needed services
   
   # Get your SHA-1 fingerprint:
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```

4. **iOS Configuration** (if developing for iOS):
   ```bash
   # Add API key to ios/Runner/AppDelegate.swift:
   GMSServices.provideAPIKey("YOUR_API_KEY_HERE")
   ```

⚠️ **Security Note**: Never commit your actual API key to version control. The app uses placeholders that read from local.properties.

### 📦 **Dependencies**

#### **Mobile App Dependencies**
```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.2
  # Location services
  geolocator: ^9.0.2
  geocoding: ^2.1.0
  # State management
  provider: ^6.0.5
  # HTTP requests
  http: ^1.1.0
  # Local storage
  shared_preferences: ^2.2.0
  # Permissions
  permission_handler: ^10.4.3
```

#### **Web Dashboard Dependencies**
```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.2
  # WebSocket communication
  web_socket_channel: ^2.4.0
  # HTTP requests
  http: ^1.1.0
```

### 🌐 **Backend Requirements**

#### **WebSocket Server**
```bash
# Node.js + Socket.io (Recommended)
npm install socket.io express cors

# Python + WebSockets
pip install websockets fastapi uvicorn

# Go + Gorilla WebSocket
go get github.com/gorilla/websocket
```

#### **Database Options**
- **Firebase Realtime Database** (Managed solution)
- **PostgreSQL** (Self-hosted)
- **MongoDB** (Document-based)
- **SQLite** (Local development)

---

## 🚀 Quick Start

### 1. **Clone Repository**
```bash
git clone https://github.com/Yongqiao662/SafeZoneX.git
cd SafeZoneX
```

### 2. **Setup Mobile App**
```bash
cd SafeZoneX/frontend/mobile
flutter pub get
flutter run
```

### 3. **Setup Web Dashboard**
```bash
cd SafeZoneX/frontend/web
flutter pub get
flutter run -d chrome
```

### 4. **Setup Backend Server**
```bash
# Example Node.js WebSocket server
cd SafeZoneX/backend
npm install
npm start
```

---

## 📱 Platform Support

| Platform | Status | Features |
|----------|--------|----------|
| **Android** | ✅ Full Support | All features available |
| **iOS** | ✅ Full Support | All features available |
| **Web** | ✅ Dashboard Only | Monitoring & management |
| **Windows** | 🔄 In Development | Desktop monitoring app |
| **macOS** | 🔄 In Development | Desktop monitoring app |
| **Linux** | 🔄 In Development | Desktop monitoring app |

---

## 🏗️ System Architecture

```
┌─────────────────┐    WebSocket    ┌─────────────────┐
│  Mobile App     │◄──────────────►│  Backend Server │
│  (Flutter)      │                 │  (Node.js/Python)│
└─────────────────┘                 └─────────────────┘
                                             ▲
                                             │ WebSocket
                                             ▼
                                    ┌─────────────────┐
                                    │  Web Dashboard  │
                                    │  (Flutter Web)  │
                                    └─────────────────┘
```

---

## 🤝 Contributing

We welcome contributions to make SafeZoneX even better! Please read our [Contributing Guidelines](CONTRIBUTING.md) for details on:

- Code of Conduct
- Development Process
- Pull Request Process
- Issue Reporting

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 📞 Support

- **Documentation**: [docs.safezonex.com](https://docs.safezonex.com)
- **Issues**: [GitHub Issues](https://github.com/your-org/SafeZoneX/issues)
- **Discord**: [Community Chat](https://discord.gg/safezonex)
- **Email**: support@safezonex.com

---

## 🎯 Roadmap

### **Phase 1: Core Safety** ✅
- [x] SOS Emergency System
- [x] Real-time Monitoring Dashboard
- [x] Basic Chat Support

### **Phase 2: Community Features** ✅
- [x] Walking Partner System
- [x] Profile Management
- [x] Enhanced UI/UX

### **Phase 3: Advanced Features** 🔄
- [ ] Campus Integration APIs
- [ ] Advanced Analytics
- [ ] Multi-language Support
- [ ] Offline Mode

### **Phase 4: Enterprise** 📋
- [ ] Multi-campus Support
- [ ] Advanced Admin Controls
- [ ] Integration with Campus Security
- [ ] Custom Branding

---

## 🏆 Awards & Recognition

*Built for campus safety, designed for peace of mind.*

**SafeZoneX - Because every second counts in an emergency.**" 
