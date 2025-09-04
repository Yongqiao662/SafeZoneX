@echo off
echo 🚀 Setting up SafeZoneX Backend ^& Frontend
echo ==========================================

REM Setup Backend
echo 📦 Installing Backend Dependencies...
cd backend
call npm install
if %errorlevel% neq 0 (
    echo ❌ Failed to install backend dependencies
    pause
    exit /b 1
)
echo ✅ Backend dependencies installed

REM Setup Web Frontend  
echo 📱 Installing Web Frontend Dependencies...
cd ..\frontend\web
call flutter pub get
if %errorlevel% neq 0 (
    echo ❌ Failed to install web dependencies
    pause
    exit /b 1
)
echo ✅ Web frontend dependencies installed

REM Setup Mobile Frontend
echo 📱 Installing Mobile Frontend Dependencies...
cd ..\mobile
call flutter pub get
if %errorlevel% neq 0 (
    echo ❌ Failed to install mobile dependencies
    pause
    exit /b 1
)
echo ✅ Mobile frontend dependencies installed

echo.
echo 🎉 Setup Complete!
echo.
echo 🚀 To start the system:
echo 1. Start Backend:    cd backend ^&^& npm start
echo 2. Start Web:        cd frontend\web ^&^& flutter run -d chrome  
echo 3. Start Mobile:     cd frontend\mobile ^&^& flutter run
echo.
echo 📡 WebSocket Server: ws://localhost:8080
echo 🌐 Web Dashboard:    http://localhost:8080
echo.
pause
