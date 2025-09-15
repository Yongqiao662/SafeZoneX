# SafeZoneX Cleanup Script
# Run these commands one by one to clean up redundant files

# === BACKEND CLEANUP ===
# Remove duplicate server files
Remove-Item "e:\SafeZoneX\backend\server_new.js" -Force
Remove-Item "e:\SafeZoneX\backend\server-test.js" -Force
Remove-Item "e:\SafeZoneX\backend\package-simple.json" -Force

# Keep only one install script (choose bat or sh based on your OS)
# Remove-Item "e:\SafeZoneX\backend\install.bat" -Force
# Remove-Item "e:\SafeZoneX\backend\install.sh" -Force

# === ROOT LEVEL CLEANUP ===
# Remove duplicate platform folders (keep only in frontend/mobile/)
Remove-Item "e:\SafeZoneX\android" -Recurse -Force
Remove-Item "e:\SafeZoneX\ios" -Recurse -Force  
Remove-Item "e:\SafeZoneX\linux" -Recurse -Force
Remove-Item "e:\SafeZoneX\macos" -Recurse -Force
Remove-Item "e:\SafeZoneX\windows" -Recurse -Force

# Remove duplicate config files
Remove-Item "e:\SafeZoneX\pubspec.yaml" -Force
Remove-Item "e:\SafeZoneX\pubspec.lock" -Force
Remove-Item "e:\SafeZoneX\package.json" -Force
Remove-Item "e:\SafeZoneX\package-lock.json" -Force
Remove-Item "e:\SafeZoneX\node_modules" -Recurse -Force

# Remove redundant frontend lib
Remove-Item "e:\SafeZoneX\frontend\lib" -Recurse -Force

# === AFTER CLEANUP STRUCTURE ===
# ✅ backend/ (main server files)
# ✅ frontend/mobile/ (Flutter app)
# ✅ frontend/web/ (Web app)
# ✅ frontend/shared/ (Shared models)
# ✅ scripts/ (Build scripts)