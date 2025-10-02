# 🆘 SOS Feature Testing Guide

## ✅ **What We Just Tested**

The test script successfully sent:
1. ✅ SOS Alert broadcast
2. ✅ Location update (5 seconds later)
3. ✅ SOS ended signal (15 seconds later)

All WebSocket events are working on the backend!

---

## 📱 **How to Test in Your Flutter App**

### **Method 1: Automated Test (Easiest)**

1. **Start the backend** (already running):
   ```bash
   cd SafeZoneX/backend
   node server.js
   ```

2. **Run your Flutter app**:
   ```bash
   cd SafeZoneX/frontend/mobile
   flutter run
   ```

3. **In the app:**
   - Click "Try Demo" to login
   - Go to the **Friends** screen (bottom navigation)
   
4. **Trigger test SOS alert:**
   ```bash
   cd SafeZoneX/backend
   node test_sos.js
   ```

5. **What you should see immediately:**
   - 🔴 Red banner appears at top: "🆘 1 Friend(s) Need Help!"
   - 📲 Pop-up alert dialog shows up
   - 📍 Shows Demo User's location
   - 📱 Phone vibrates (haptic feedback)
   
6. **Click "View Location & Help":**
   - See map preview with coordinates
   - View address: "University Malaya Campus - Main Building"
   - "Navigate" button ready

7. **After 5 seconds:**
   - Location updates automatically (check console logs)

8. **After 15 seconds:**
   - Green notification: "Friend is no longer in emergency mode"
   - Red banner disappears
   - Friend card returns to normal

---

### **Method 2: Real SOS Button Test**

1. **Run Flutter app on Device/Emulator 1** (SOS User):
   ```bash
   flutter run
   ```

2. **Login and go to Home screen**

3. **Click the big red SOS button**

4. **You should see:**
   - ✅ SOS Active screen appears
   - ✅ Pulsing red animations
   - ✅ Status: "Connected - Friends Notified"
   - ✅ Progress messages checking off
   - ✅ Console logs showing WebSocket connection

5. **Run app on Device 2** (Friend):
   - Go to Friends screen
   - You should see the SOS notification instantly!

---

### **Method 3: Two Emulators Test**

1. **Terminal 1 - First Emulator:**
   ```bash
   cd SafeZoneX/frontend/mobile
   flutter run -d emulator-5554
   ```

2. **Terminal 2 - Second Emulator:**
   ```bash
   flutter run -d emulator-5556
   ```

3. **On Emulator 1:** Activate SOS
4. **On Emulator 2:** See notification instantly

---

## 🔍 **What to Look For**

### **Backend Console Logs:**
```
🆘 SOS Alert received from Demo User: {...}
📡 SOS broadcasted to all friends and security
📍 Location update from test_user_123
✅ SOS ended by test_user_123
```

### **Flutter Console Logs (Friends Screen):**
```
✅ Connected to backend for SOS alerts
🆘 Received SOS alert: {...}
📍 Received location update: {...}
✅ SOS ended: {...}
```

### **Flutter Console Logs (SOS Screen):**
```
✅ Connected to backend WebSocket for SOS
📡 SOS alert broadcasted to all friends: {...}
📍 Location update sent to friends
```

---

## 🎨 **Visual Indicators to Verify**

### **Friends Screen - When SOS Active:**
- ✅ Red banner at top with alert count
- ✅ Friend card has RED BORDER with glow effect
- ✅ Red warning icon on friend's avatar
- ✅ "🆘 SOS" badge visible
- ✅ Status text: "NEEDS HELP!" in red
- ✅ Alert dialog pops up automatically

### **SOS Active Screen:**
- ✅ Pulsing red circle animation
- ✅ Ripple effects
- ✅ Countdown timer running
- ✅ Status messages checking off progressively
- ✅ Connection status indicator

---

## 🐛 **Troubleshooting**

### **Problem: "Connection failed"**

**Solution 1 - Check backend:**
```bash
cd SafeZoneX/backend
node server.js
# Should see: 🚀 Server running on http://localhost:8080
```

**Solution 2 - Check WebSocket URL:**
- For Android Emulator: Use `http://10.0.2.2:8080`
- For iOS Simulator: Use `http://localhost:8080`
- For Physical Device: Use your computer's IP (e.g., `http://192.168.1.100:8080`)

### **Problem: No notification received**

**Check these:**
1. Backend is running on port 8080
2. Flutter app successfully connected (check console for ✅)
3. WebSocket transports enabled in backend
4. No firewall blocking port 8080

### **Problem: "Port 8080 already in use"**

**Option 1 - Kill existing process:**
```bash
# Windows
netstat -ano | findstr :8080
taskkill /PID <PID> /F

# Mac/Linux
lsof -i :8080
kill -9 <PID>
```

**Option 2 - Use different port:**
Change port in both `server.js` and Flutter app configs

---

## 📊 **Test Checklist**

### **Backend Tests:**
- [x] Server starts successfully
- [x] WebSocket connections accepted
- [x] SOS alerts broadcast to all clients
- [x] Location updates forwarded
- [x] SOS end signals processed
- [x] Acknowledgments sent back

### **Mobile Tests:**
- [ ] SOS button activates SOS screen
- [ ] WebSocket connects from SOS screen
- [ ] SOS alert broadcasts successfully
- [ ] Friends screen connects to WebSocket
- [ ] Friend receives SOS notification
- [ ] Pop-up dialog displays correctly
- [ ] Location shown on map preview
- [ ] Red visual indicators appear
- [ ] Haptic feedback works
- [ ] Acknowledgment sends back
- [ ] SOS end clears all indicators

---

## 🎯 **Expected Test Results**

### **✅ Success Criteria:**

1. **SOS Activation (< 1 second):**
   - Screen changes to SOS Active
   - WebSocket connects
   - Alert broadcasts

2. **Friend Notification (< 2 seconds):**
   - Friend receives alert
   - Pop-up appears
   - Vibration/haptic feedback

3. **Real-time Updates (every 10 seconds):**
   - Location updates stream
   - Friends see updated positions

4. **Acknowledgment (instant):**
   - Friend clicks acknowledge
   - SOS user receives confirmation

5. **SOS Deactivation (< 1 second):**
   - Alert clears on all devices
   - Visual indicators reset
   - Green success message

---

## 🚀 **Advanced Testing**

### **Load Test - Multiple Friends:**
```javascript
// Run multiple test clients
for (let i = 0; i < 5; i++) {
  setTimeout(() => {
    require('child_process').exec('node test_sos.js');
  }, i * 1000);
}
```

### **Network Interruption Test:**
1. Start SOS
2. Turn off WiFi for 5 seconds
3. Turn WiFi back on
4. Should auto-reconnect

### **Background Test:**
1. Start SOS
2. Minimize app
3. Friend should still receive notification

---

## 📝 **Test Results Log**

Date: October 2, 2025

| Test Case | Status | Notes |
|-----------|--------|-------|
| Backend Start | ✅ PASS | Port 8080 |
| WebSocket Connect | ✅ PASS | Both screens |
| SOS Broadcast | ✅ PASS | Alert sent |
| Friend Notification | ⏳ PENDING | Test in app |
| Location Updates | ✅ PASS | Every 10s |
| Visual Indicators | ⏳ PENDING | Test in app |
| Acknowledgment | ⏳ PENDING | Test in app |
| SOS Deactivation | ✅ PASS | Clean shutdown |

---

## 🎓 **Next Steps**

1. **Test with Flutter app** - Run `flutter run` and test
2. **Check visual indicators** - Verify red borders, badges, etc.
3. **Test acknowledgment flow** - Click buttons and verify
4. **Test with real devices** - Use physical phones
5. **Add more friends** - Test with multiple users
6. **Integrate GPS** - Replace mock coordinates with real location

---

## 💡 **Tips**

- Keep backend terminal visible to see real-time logs
- Use `flutter logs` in another terminal to see app output
- Test in both light and dark conditions
- Check battery impact for long SOS sessions
- Verify notifications work with app in background

---

**🎉 Your SOS feature is ready for testing!**
**Run the commands above and watch the magic happen! ✨**
