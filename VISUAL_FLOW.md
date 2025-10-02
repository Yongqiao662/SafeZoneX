# 🎨 Visual Authentication Flow

## Complete User Journey with Smart Authentication

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          USER OPENS APP                                 │
└─────────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
                    ┌─────────────────────────┐
                    │    SPLASH SCREEN        │
                    │  (Checking auth...)     │
                    └─────────────────────────┘
                                  │
                                  ▼
                    ┌─────────────────────────┐
                    │   Is User Logged In?    │
                    │  (Check SharedPrefs)    │
                    └─────────────────────────┘
                            ╱          ╲
                          ╱              ╲
                        ╱                  ╲
                      ╱                      ╲
              ┌────────┐                ┌──────────┐
              │  YES   │                │    NO    │
              └────────┘                └──────────┘
                  │                          │
                  ▼                          ▼
    ┌──────────────────────────┐   ┌──────────────────────────┐
    │   MAIN DASHBOARD         │   │    LOGIN SCREEN          │
    │   (Auto-Login!)          │   │  "Welcome to SafeZoneX"  │
    │   ✅ Skip all auth       │   │                          │
    └──────────────────────────┘   └──────────────────────────┘
                                              │
                                              ▼
                                    ┌──────────────────────────┐
                                    │  Click "Sign In with     │
                                    │  Google"                 │
                                    └──────────────────────────┘
                                              │
                                              ▼
                                    ┌──────────────────────────┐
                                    │  Google Account Picker   │
                                    │  (Select UM Account)     │
                                    └──────────────────────────┘
                                              │
                                              ▼
                                    ┌──────────────────────────┐
                                    │  Validate Email Domain   │
                                    │  (@siswa.um.edu.my)     │
                                    └──────────────────────────┘
                                          ╱          ╲
                                        ╱              ╲
                                      ╱                  ╲
                              ┌──────────┐          ┌─────────┐
                              │  Valid   │          │ Invalid │
                              └──────────┘          └─────────┘
                                    │                     │
                                    │                     ▼
                                    │           ┌──────────────────┐
                                    │           │  ❌ Error:       │
                                    │           │  "Only UM emails │
                                    │           │   allowed"       │
                                    │           └──────────────────┘
                                    │
                                    ▼
                          ┌──────────────────────────┐
                          │  🔍 CHECK DATABASE       │
                          │  API: /api/users/check   │
                          │  Does user exist?        │
                          └──────────────────────────┘
                                ╱              ╲
                              ╱                  ╲
                            ╱                      ╲
                    ┌──────────┐              ┌──────────┐
                    │   YES    │              │    NO    │
                    │ (Exists) │              │  (New)   │
                    └──────────┘              └──────────┘
                          │                         │
                          ▼                         ▼
        ┌──────────────────────────┐   ┌──────────────────────────┐
        │  ✅ AUTO-LOGIN!          │   │  PERSONAL DETAILS SCREEN │
        │  - Save credentials      │   │  "Complete your profile" │
        │  - "Welcome back, [Name]"│   │                          │
        │  - Skip registration     │   │  Fields:                 │
        └──────────────────────────┘   │  • Phone Number          │
                    │                   │  • Student ID            │
                    │                   │  • Year                  │
                    │                   │  • Faculty               │
                    │                   └──────────────────────────┘
                    │                               │
                    │                               ▼
                    │                   ┌──────────────────────────┐
                    │                   │  Click "Complete         │
                    │                   │  Registration"           │
                    │                   └──────────────────────────┘
                    │                               │
                    │                               ▼
                    │                   ┌──────────────────────────┐
                    │                   │  API: /api/users/register│
                    │                   │  - Check duplicates      │
                    │                   │  - Create new user       │
                    │                   │  - Save to MongoDB       │
                    │                   └──────────────────────────┘
                    │                               │
                    │                               ▼
                    │                   ┌──────────────────────────┐
                    │                   │  ✅ Registration Success │
                    │                   │  - Save credentials      │
                    │                   │  - Set isLoggedIn=true   │
                    │                   └──────────────────────────┘
                    │                               │
                    └───────────────┬───────────────┘
                                    ▼
                      ┌──────────────────────────┐
                      │    MAIN DASHBOARD        │
                      │  • Home                  │
                      │  • Walk with Me          │
                      │  • Friends               │
                      │  • Reports               │
                      │  • Profile               │
                      └──────────────────────────┘
                                    │
                                    │ (User navigates to Profile)
                                    │
                                    ▼
                      ┌──────────────────────────┐
                      │   PROFILE SCREEN         │
                      │  • User Info             │
                      │  • Settings              │
                      │  • 🚪 Sign Out           │
                      └──────────────────────────┘
                                    │
                                    │ (Click Sign Out)
                                    │
                                    ▼
                      ┌──────────────────────────┐
                      │  Confirmation Dialog     │
                      │  "Are you sure?"         │
                      └──────────────────────────┘
                                    │
                                    ▼
                      ┌──────────────────────────┐
                      │  📤 LOGOUT PROCESS       │
                      │  1. Google sign out      │
                      │  2. Clear credentials    │
                      │  3. Set isLoggedIn=false │
                      └──────────────────────────┘
                                    │
                                    ▼
                      ┌──────────────────────────┐
                      │    LOGIN SCREEN          │
                      │  (Can sign in again)     │
                      └──────────────────────────┘
                                    │
                                    └────────────────┐
                                                     │
                          (Loop back to "Sign In with Google")
```

---

## 🎯 Key Decision Points

### Decision 1: Is User Logged In?
- **Check:** `SharedPreferences` → `is_logged_in` flag
- **YES:** Direct to Dashboard (skip auth)
- **NO:** Show Login Screen

### Decision 2: Valid Email Domain?
- **Check:** Email ends with `@siswa.um.edu.my`
- **YES:** Continue to database check
- **NO:** Show error, reject sign in

### Decision 3: Does User Exist in Database?
- **Check:** API call to `/api/users/check?email={email}`
- **EXISTS:** Auto-login (skip registration)
- **NEW:** Show Personal Details Screen

---

## 🔄 State Management

```
┌─────────────────────────────────────────────────────────┐
│                   SHARED PREFERENCES                    │
├─────────────────────────────────────────────────────────┤
│  • user_id: "uuid"                                      │
│  • user_email: "student@siswa.um.edu.my"               │
│  • user_name: "Student Name"                            │
│  • is_logged_in: true/false                             │
└─────────────────────────────────────────────────────────┘
         │                                    │
         │ (On Login)                         │ (On Logout)
         ▼                                    ▼
    Save All Data                         Clear All Data
    Set is_logged_in = true               Set is_logged_in = false
```

---

## 📊 API Flow

### Check User Exists
```
Frontend                    Backend                   MongoDB
   │                           │                         │
   ├──── GET /api/users/check ─┤                         │
   │        ?email=xxx         │                         │
   │                           ├─── Find by email ───────┤
   │                           │                         │
   │                           ├─────── Result ──────────┤
   │                           │                         │
   │◄─── Response: exists=true/false + user data ────────┤
   │                           │                         │
```

### Register User
```
Frontend                    Backend                   MongoDB
   │                           │                         │
   ├─ POST /api/users/register┤                         │
   │     {email, name, etc}   │                         │
   │                           ├─ Check email exists ────┤
   │                           │                         │
   │                           ├─ Check studentId exists ┤
   │                           │                         │
   │                           ├─ If both unique ────────┤
   │                           │   Create new user       │
   │                           │                         │
   │◄─── Response: user object ─────────────────────────┤
   │                           │                         │
```

---

## 🎨 UI States

### Splash Screen States
```
Loading → Checking Auth → Navigate
   │            │              │
   └─ Progress Bar            └─ Fade Transition
        └─ Status Text
```

### Login Screen States
```
Idle → Loading → Success/Error
 │        │           │
 └─ Show Form        └─ Navigate/Show Error
     └─ Google Button
```

### Registration Flow States
```
Personal Details → Validating → Saving → Success
       │               │          │         │
       └─ Form Input   └─ API    └─ DB    └─ Navigate
```

---

## 🎉 Success Indicators

### ✅ First Time User
```
Google Sign-In ✅
  ↓
Personal Details ✅
  ↓
Registration ✅ "Account created successfully!"
  ↓
Dashboard ✅
```

### ✅ Returning User
```
Google Sign-In ✅
  ↓
Database Check ✅ User found!
  ↓
Auto-Login ✅ "Welcome back, [Name]!"
  ↓
Dashboard ✅
```

### ✅ After Sign Out
```
Sign Out ✅ "Signed out successfully"
  ↓
Login Screen ✅
  ↓
Google Sign-In ✅
  ↓
Auto-Login ✅ "Welcome back!"
```

---

## 📱 Device Scenarios

### Same Device - App Restart
```
Close App → Reopen App
     ↓
Check is_logged_in = true
     ↓
Auto-Login to Dashboard ✅
```

### Different Device - Same Account
```
New Device → Sign In with Google
     ↓
Check Database → User Exists
     ↓
Auto-Login to Dashboard ✅
(No duplicate created!)
```

---

**Visual Flow Version:** 2.0  
**Last Updated:** October 2, 2025  
**Status:** ✅ Complete Implementation
