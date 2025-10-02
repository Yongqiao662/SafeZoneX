# Troubleshooting: FormatException HTML Error

## 🔴 Error You Saw:
```
Error: FormatException: Unexpected character (at character 1)
<!DOCTYPE html>
```

## 🔍 What This Means:
Your Flutter app tried to call the backend API and expected JSON response, but instead received an HTML error page. This happens when:

1. Backend server is not running
2. Backend is running but OLD version (before our changes)
3. Wrong URL in Flutter app
4. Network issue

---

## ✅ **SOLUTION** (What I Did):

### Step 1: Stopped Old Backend
```powershell
Get-Process -Name node | Stop-Process -Force
```
This killed the old backend server that didn't have the `/api/users/register` endpoint.

### Step 2: Started New Backend
```powershell
cd d:\hackathon\SafeZoneX-main\SafeZoneX\backend
node server.js
```

Expected output:
```
✅ 🚀 Server running on http://localhost:8080
✅ 📦 Connected to MongoDB successfully
```

### Step 3: Restart Flutter App
The Flutter app needs to reconnect to the updated backend.

---

## 📋 **How to Prevent This**:

### Always Check Backend Status:

```powershell
# 1. Go to backend folder
cd d:\hackathon\SafeZoneX-main\SafeZoneX\backend

# 2. Start server
node server.js

# You should see:
# ✅ Server running on http://localhost:8080
# ✅ Connected to MongoDB successfully
```

### Check Backend Logs:
When you submit the form in Flutter, you should see in backend console:
```
🔵 POST /api/users/register
✅ New user registered: yourname@siswa.um.edu.my
```

---

## 🧪 **Test Backend Manually**:

### Using Browser:
1. Open: `http://localhost:8080/dashboard.html`
2. If you see the dashboard → Backend is running ✅

### Using PowerShell:
```powershell
# Test registration endpoint
$body = @{
    email = "test@siswa.um.edu.my"
    name = "Test User"
    phone = "0123456789"
    studentId = "U123456"
} | ConvertTo-Json

Invoke-RestMethod -Uri http://localhost:8080/api/users/register `
  -Method POST `
  -ContentType "application/json" `
  -Body $body
```

Expected response:
```json
{
  "success": true,
  "user": {
    "userId": "some-uuid",
    "email": "test@siswa.um.edu.my",
    "name": "Test User"
  },
  "message": "Registration successful"
}
```

---

## 🔧 **Common Issues**:

### Issue 1: Port 8080 Already in Use
```
Error: listen EADDRINUSE: address already in use :::8080
```

**Solution:**
```powershell
# Kill all node processes
Get-Process -Name node | Stop-Process -Force

# Then restart
cd d:\hackathon\SafeZoneX-main\SafeZoneX\backend
node server.js
```

---

### Issue 2: MongoDB Not Connected
```
❌ MongoDB connection error
```

**Solution:**
1. Check `.env` file has `MONGODB_URI`
2. Make sure MongoDB is running (if local)
3. Check MongoDB Atlas connection string (if cloud)

---

### Issue 3: Flutter Can't Connect
```
SocketException: Connection refused
```

**Solutions:**

#### For Android Emulator:
```dart
// In api_service.dart
static const String baseUrl = 'http://10.0.2.2:8080';
```

#### For iOS Simulator:
```dart
static const String baseUrl = 'http://localhost:8080';
```

#### For Physical Device:
```dart
// Find your computer's IP address:
// Windows: ipconfig (look for IPv4)
// Mac: ifconfig | grep "inet "

static const String baseUrl = 'http://192.168.1.XXX:8080';
```

---

## 🎯 **Quick Fix Checklist**:

When you see the HTML error:

- [ ] 1. Check backend is running: `http://localhost:8080/dashboard.html`
- [ ] 2. Check backend logs for errors
- [ ] 3. Restart backend: Kill node → `node server.js`
- [ ] 4. Check Flutter is using correct URL (`10.0.2.2:8080` for emulator)
- [ ] 5. Hot restart Flutter app (press `R` in terminal)
- [ ] 6. Check backend logs when you submit form

---

## 📝 **Debugging Steps**:

### 1. Add Logging (Already Done ✅):
```dart
// In api_service.dart
print('🔵 Registering user: $email');
print('🔵 Backend URL: $baseUrl/api/users/register');
print('🔵 Response status: ${response.statusCode}');
print('🔵 Response body: ${response.body}');
```

### 2. Watch Backend Console:
When you submit form, you should see:
```
🔵 POST /api/users/register
{
  email: 'test@siswa.um.edu.my',
  name: 'Test User',
  phone: '0123456789',
  studentId: 'U123456'
}
✅ New user registered: test@siswa.um.edu.my
```

### 3. Watch Flutter Console:
You should see:
```
🔵 Registering user: test@siswa.um.edu.my
🔵 Backend URL: http://10.0.2.2:8080/api/users/register
🔵 Response status: 200
🔵 Response body: {"success":true,"user":{...}}
✅ User registered successfully: abc-123-uuid
```

---

## 🚀 **Current Status**:

✅ Backend: Running on port 8080 with updated code
✅ Registration endpoint: `/api/users/register` exists
✅ Better error logging: Added to api_service.dart
✅ Flutter app: Needs restart to reconnect

---

## 📞 **Next Steps**:

1. **Restart Flutter app** - Important to reconnect to updated backend
2. **Fill in the registration form**
3. **Watch both consoles** (Flutter & Backend)
4. **Should work now!** ✅

---

## 💡 **Pro Tips**:

### Keep Two Terminals Open:

**Terminal 1 - Backend:**
```powershell
cd d:\hackathon\SafeZoneX-main\SafeZoneX\backend
node server.js
# Leave running, watch logs
```

**Terminal 2 - Flutter:**
```powershell
cd d:\hackathon\SafeZoneX-main\SafeZoneX\frontend\mobile
flutter run
# Leave running, hot reload with 'r'
```

### Quick Restart Backend:
```powershell
# Press Ctrl+C to stop backend
# Then:
node server.js
```

### Quick Restart Flutter:
```
# In Flutter terminal, press:
R  # Hot restart (capital R)
r  # Hot reload (lowercase r)
q  # Quit
```

---

*Problem Fixed: October 2, 2025*
