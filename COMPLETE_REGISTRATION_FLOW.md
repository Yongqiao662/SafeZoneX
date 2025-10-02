# Complete Registration Flow - Updated

## 🎯 Your New Registration Flow

### **What You Wanted:**
```
Google Sign-In → Complete Registration Form → Save to Database → Friends Can Search
```

### **What I Implemented:** ✅

```
Step 1: Google Sign-In (signup_screen.dart)
   ↓
   User clicks "Sign in with Google"
   ↓
   Selects UM email account
   ↓
   ✅ Google authentication successful
   ↓
   
Step 2: Navigate to Personal Details Screen
   ↓
   Pre-filled: Name, Email (from Google)
   User enters:
   - Phone number
   - Student ID
   - Year of study
   - Faculty
   - Course (optional)
   - Upload Student ID photo (optional)
   ↓
   
Step 3: Click "Continue" / "Save"
   ↓
   POST /api/users/register
   ↓
   MongoDB: Save user to 'users' collection
   {
     userId: "auto-generated-uuid",
     email: "john@siswa.um.edu.my",
     name: "John Doe",
     phone: "+60123456789",
     studentId: "U2012345",
     isVerified: true,
     isActive: true
   }
   ↓
   SharedPreferences: Save credentials locally
   ↓
   Navigate to Main Dashboard
   ↓
   
Step 4: ✅ User is now searchable!
   ↓
   Other users can search: "john@siswa.um.edu.my"
   ↓
   Add as friend → Start chatting
```

---

## 📁 Files Modified

### 1. `frontend/mobile/lib/screens/signup_screen.dart`

**What Changed:**
- Google Sign-In now navigates to `PersonalDetailsScreen` instead of directly to dashboard
- **Does NOT** register user yet - waits for profile completion

**Before:**
```dart
// Google Sign-In → Register immediately → Dashboard
final result = await ApiService.registerUser(email: email, name: name);
Navigator.pushReplacement(context, MaterialPageRoute(
  builder: (context) => MainDashboardScreen()
));
```

**After:**
```dart
// Google Sign-In → Personal Details Screen
Navigator.pushReplacement(context, MaterialPageRoute(
  builder: (context) => PersonalDetailsScreen(
    name: name,
    email: email,
  )
));
```

---

### 2. `frontend/mobile/lib/screens/personal_details_screen.dart`

**What Changed:**
- `_saveAndComplete()` method now calls `ApiService.registerUser()`
- Registers user to MongoDB with complete profile data
- Saves userId and credentials locally

**Before:**
```dart
// Save to local storage only
await UserPreferences.saveUserData(...);
await authService.saveUserProfile(userData);
await _sendToServer(); // Optional
```

**After:**
```dart
// Register to MongoDB first
final result = await ApiService.registerUser(
  email: email,
  name: name,
  phone: phone,
  studentId: studentId,
);

// Then save locally
await ApiService.saveUserCredentials(userId, email, name);
await UserPreferences.saveUserData(...);
```

---

## 🔄 Complete Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                      USER REGISTRATION FLOW                  │
└─────────────────────────────────────────────────────────────┘

1. GOOGLE SIGN-IN (signup_screen.dart)
   ┌──────────────────────────────────────────────┐
   │ User clicks "Sign in with Google"            │
   │ ↓                                            │
   │ Select UM email account                      │
   │ ↓                                            │
   │ Google Auth Success                          │
   │ ↓                                            │
   │ Get: email, name from Google                 │
   └──────────────────────────────────────────────┘
                    ↓
                    
2. PERSONAL DETAILS SCREEN (personal_details_screen.dart)
   ┌──────────────────────────────────────────────┐
   │ Pre-filled:                                  │
   │  • Name: "John Doe" (from Google)           │
   │  • Email: "john@siswa.um.edu.my"            │
   │                                              │
   │ User fills in:                               │
   │  • Phone: "+60123456789"                     │
   │  • Student ID: "U2012345"                    │
   │  • Year: "Year 2"                            │
   │  • Faculty: "Engineering"                    │
   │  • Course: "Computer Science" (optional)     │
   │  • Upload Student ID photo (optional)        │
   │                                              │
   │ Clicks: "Continue" or "Save"                 │
   └──────────────────────────────────────────────┘
                    ↓
                    
3. REGISTRATION API CALL (_saveAndComplete method)
   ┌──────────────────────────────────────────────┐
   │ POST /api/users/register                     │
   │                                              │
   │ Request Body:                                │
   │ {                                            │
   │   "email": "john@siswa.um.edu.my",          │
   │   "name": "John Doe",                        │
   │   "phone": "+60123456789",                   │
   │   "studentId": "U2012345"                    │
   │ }                                            │
   └──────────────────────────────────────────────┘
                    ↓
                    
4. BACKEND PROCESSING (server.js)
   ┌──────────────────────────────────────────────┐
   │ Check if user already exists                 │
   │ ↓                                            │
   │ Generate unique userId (UUID)                │
   │ ↓                                            │
   │ Create User document in MongoDB:             │
   │ {                                            │
   │   userId: "abc-123-uuid",                    │
   │   email: "john@siswa.um.edu.my",            │
   │   name: "John Doe",                          │
   │   phone: "+60123456789",                     │
   │   studentId: "U2012345",                     │
   │   isVerified: true,                          │
   │   isActive: true,                            │
   │   joinedAt: Date,                            │
   │   lastSeen: Date                             │
   │ }                                            │
   │ ↓                                            │
   │ Return userId to Flutter                     │
   └──────────────────────────────────────────────┘
                    ↓
                    
5. SAVE LOCALLY (personal_details_screen.dart)
   ┌──────────────────────────────────────────────┐
   │ SharedPreferences.setString():               │
   │  • "user_id" = "abc-123-uuid"               │
   │  • "user_email" = "john@siswa.um.edu.my"    │
   │  • "user_name" = "John Doe"                  │
   │  • "is_logged_in" = true                     │
   │                                              │
   │ UserPreferences.saveUserData():              │
   │  • Save additional profile info              │
   │  • Year, faculty, course, phone              │
   └──────────────────────────────────────────────┘
                    ↓
                    
6. NAVIGATE TO DASHBOARD
   ┌──────────────────────────────────────────────┐
   │ Show success message:                        │
   │ "✅ Registration complete!                   │
   │  You are now searchable by friends."         │
   │ ↓                                            │
   │ Navigator.pushReplacement()                  │
   │ → MainDashboardScreen                        │
   └──────────────────────────────────────────────┘
                    ↓
                    
7. ✅ USER IS NOW SEARCHABLE!
   ┌──────────────────────────────────────────────┐
   │ User data in MongoDB 'users' collection      │
   │ ↓                                            │
   │ Friends can search:                          │
   │  • By email: "john@siswa.um.edu.my"         │
   │  • Results show: "John Doe"                  │
   │ ↓                                            │
   │ Click "Add Friend"                           │
   │ ↓                                            │
   │ Start chatting!                              │
   └──────────────────────────────────────────────┘
```

---

## 🧪 Testing the New Flow

### Test Scenario 1: New User Registration

**Steps:**
1. Open app
2. Click "Sign Up"
3. Click "Sign in with Google"
4. Select your UM email account
5. ✅ Should navigate to Personal Details Screen
6. See name and email pre-filled from Google
7. Enter:
   - Phone: `+60123456789`
   - Student ID: `U2012345`
   - Select Year: `Year 2`
   - Select Faculty: `Engineering`
   - Course: `Computer Science` (optional)
8. Click "Continue" or "Save"
9. ✅ Should see: "Registration complete! You are now searchable by friends."
10. ✅ Navigate to Main Dashboard

**Backend Check:**
```bash
# Check MongoDB
use your_database
db.users.find({ email: "your_email@siswa.um.edu.my" })

# Should return user document with:
# - userId (UUID)
# - email, name, phone, studentId
# - isVerified: true
# - isActive: true
```

---

### Test Scenario 2: Friend Search

**Prerequisites:** Two users registered (User A and User B)

**Steps:**
1. User B logs in
2. Go to "Friends" tab
3. Tap search icon (🔍)
4. Type: User A's email (e.g., "alice@siswa.um.edu.my")
5. ✅ Should see User A in search results with name "Alice"
6. Click "Add Friend"
7. ✅ Should see success message
8. Check friends list - Alice should appear
9. Open chat with Alice
10. Send message
11. ✅ Message saved to MongoDB

---

## 📊 Database After Registration

### Users Collection:
```javascript
{
  _id: ObjectId("67123abc..."),
  userId: "abc-123-456-uuid",        // Generated by backend
  email: "john@siswa.um.edu.my",     // From Google
  name: "John Doe",                   // From Google/form
  phone: "+60123456789",              // From form
  studentId: "U2012345",              // From form
  profilePicture: "",                 // Optional
  faceDescriptors: [],                // Optional (face recognition)
  isVerified: true,                   // Auto-set (UM email)
  verificationScore: 0,
  safetyRating: 5.0,                  // Default
  totalWalks: 0,                      // Default
  emergencyContacts: [],              // Can add later
  location: {
    latitude: null,
    longitude: null,
    lastUpdated: null
  },
  isActive: true,                     // Auto-set
  joinedAt: ISODate("2025-10-02T..."),
  lastSeen: ISODate("2025-10-02T..."),
  createdAt: ISODate("2025-10-02T..."),
  updatedAt: ISODate("2025-10-02T...")
}
```

---

## 🔑 Key Points

### ✅ What Works Now:

1. **Google Sign-In → Personal Details**
   - User authenticates with Google
   - Gets redirected to complete profile
   - **NOT** registered yet

2. **Complete Profile → Register to Database**
   - User fills phone, student ID, etc.
   - Clicks Save/Continue
   - **NOW** registered to MongoDB
   - Gets unique userId

3. **Instant Searchability**
   - After registration completes
   - User data in MongoDB
   - Friends can search by email
   - Add as friend immediately

4. **Persistent Storage**
   - Credentials saved locally (SharedPreferences)
   - Profile data saved locally (UserPreferences)
   - User data saved remotely (MongoDB)
   - Stays logged in after app restart

---

## 🚀 For Your Team Testing

### Setup:
```bash
# 1. Start backend
cd backend
node server.js

# 2. Run Flutter app
cd frontend/mobile
flutter run
```

### Team Registration:
```
Teammate 1: Google Sign-In → Complete profile → Dashboard
Teammate 2: Google Sign-In → Complete profile → Dashboard
Teammate 3: Google Sign-In → Complete profile → Dashboard
Teammate 4: Google Sign-In → Complete profile → Dashboard
```

### Add Each Other:
```
Teammate 1: Search "teammate2@siswa.um.edu.my" → Add Friend ✅
Teammate 2: Search "teammate3@siswa.um.edu.my" → Add Friend ✅
Teammate 3: Search "teammate4@siswa.um.edu.my" → Add Friend ✅
Teammate 4: Search "teammate1@siswa.um.edu.my" → Add Friend ✅
```

---

## 📝 Summary

### Your Flow is Now:
```
1. Google Sign-In (get email + name)
2. Complete Personal Details Form
3. Save → Register to MongoDB
4. Navigate to Dashboard
5. ✅ Searchable by friends!
```

### Changes Made:
- ✅ Signup screen: Navigate to Personal Details (don't register yet)
- ✅ Personal Details screen: Register to MongoDB when form submitted
- ✅ Save userId and credentials locally
- ✅ User immediately searchable after registration

### Database Flow:
```
Google Auth → Personal Details → POST /api/users/register → MongoDB → Searchable
```

**Everything is ready! Test it out!** 🎉

---

*Last Updated: October 2, 2025*
