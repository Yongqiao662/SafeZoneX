#!/bin/bash

echo "🚀 Setting up SafeZoneX Backend & Frontend"
echo "=========================================="

# Setup Backend
echo "📦 Installing Backend Dependencies..."
cd backend
npm install
echo "✅ Backend dependencies installed"

# Setup Web Frontend  
echo "📱 Installing Web Frontend Dependencies..."
cd ../frontend/web
flutter pub get
echo "✅ Web frontend dependencies installed"

# Setup Mobile Frontend
echo "📱 Installing Mobile Frontend Dependencies..."
cd ../mobile
flutter pub get
echo "✅ Mobile frontend dependencies installed"

echo ""
echo "🎉 Setup Complete!"
echo ""
echo "🚀 To start the system:"
echo "1. Start Backend:    cd backend && npm start"
echo "2. Start Web:        cd frontend/web && flutter run -d chrome"  
echo "3. Start Mobile:     cd frontend/mobile && flutter run"
echo ""
echo "📡 WebSocket Server: ws://localhost:8080"
echo "🌐 Web Dashboard:    http://localhost:8080"
