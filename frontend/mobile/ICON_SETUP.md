Steps to update the mobile app icon

1. Copy the repo-level icon into the mobile assets folder:

   Open a PowerShell terminal at the project root and run:

   ./frontend/mobile/copy_icon_to_assets.ps1

   This will copy `../../assets/icon.png` -> `frontend/mobile/assets/app_icon.png`.

2. Install dependencies and generate icons:

   cd frontend/mobile
   flutter pub get
   flutter pub run flutter_launcher_icons:main

3. Rebuild the app:

   flutter build apk

Notes:
- The `pubspec.yaml` contains a `flutter_icons` section pointing to `assets/app_icon.png`.
- If you already have an `assets/app_icon.png` you can replace it directly.
- For iOS builds, open Xcode and verify the AppIcon asset if needed.
