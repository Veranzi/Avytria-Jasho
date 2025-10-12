# 🚀 START YOUR JASHO APP - Complete Guide

## ✅ Backend is NOW WORKING!

### Quick Test (Backend Running):
```bash
curl http://localhost:8000/health
# Should return: {"status":"running"}
```

---

## 📋 Step-by-Step Startup

### 1️⃣ START BACKEND (Choose ONE method):

#### Method A - Double-click (Easiest):
```
Navigate to: python-backend/
Double-click: start_backend.bat
```

#### Method B - PowerShell:
```powershell
cd E:\flutterdev\Jasho-1\python-backend
.\start_backend.ps1
```

#### Method C - Command Line:
```bash
cd E:\flutterdev\Jasho-1\python-backend
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

**What you should see:**
```
✅ Firebase initialized...
INFO:     Uvicorn running on http://0.0.0.0:8000
INFO:     Application startup complete.
```

**Test Backend:**
Open browser: http://localhost:8000/docs (FastAPI Swagger UI)

---

### 2️⃣ START FLUTTER APP:

```bash
cd E:\flutterdev\Jasho-1\jashoo
flutter run
```

**Or for Chrome:**
```bash
flutter run -d chrome
```

**Or for specific device:**
```bash
# List devices
flutter devices

# Run on specific device
flutter run -d <device-id>
```

---

## 🔗 Verify Frontend ↔ Backend Connection

### Test Registration Endpoint:

1. Open browser: http://localhost:8000/docs
2. Find: **POST /api/auth/register**
3. Click "Try it out"
4. Use this test data:
```json
{
  "email": "test@example.com",
  "password": "Test123!@#",
  "fullName": "Test User",
  "phoneNumber": "+254712345678",
  "location": "Nairobi, Kenya",
  "skills": ["Boda Rider"],
  "hasBiometricAuth": false
}
```
5. Click "Execute"
6. Should return: `{"success": true, ...}`

### Test Login Endpoint:

1. Find: **POST /api/auth/login**
2. Click "Try it out"
3. Use:
```json
{
  "email": "test@example.com",
  "password": "Test123!@#"
}
```
4. Should return: `{"success": true, "data": {"token": "...", ...}}`

---

## 🎯 All API Endpoints Available:

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/health` | GET | Check backend status |
| `/api/auth/register` | POST | User registration |
| `/api/auth/login` | POST | User login |
| `/api/auth/biometric-login` | POST | Voice/Face login |
| `/api/user/profile` | GET | Get user profile |
| `/api/wallet/balance` | GET | Get wallet balance |
| `/api/jobs/gigs` | GET | Get available gigs |
| `/api/fraud/report` | POST | Report fraud |
| `/api/ratings/submit` | POST | Submit rating |
| `/api/ussd/session` | POST | USSD interface |

**Full API Docs:** http://localhost:8000/docs

---

## 🐛 Troubleshooting

### Backend Won't Start?

**Check Python:**
```bash
python --version
# Should show Python 3.10+
```

**Install Dependencies:**
```bash
cd python-backend
pip install -r requirements.txt
```

**Check Port 8000:**
```bash
netstat -ano | findstr :8000
# If something is using port 8000, kill it:
# taskkill /PID <process-id> /F
```

### Frontend Can't Connect?

**Check Flutter API Service:**
- Open: `jashoo/lib/services/api_service.dart`
- Verify: `baseUrl = 'http://localhost:8000/api'`
- If using emulator: change to `http://10.0.2.2:8000/api`

**For Android Emulator:**
```dart
static const String baseUrl = 'http://10.0.2.2:8000/api';
```

**For Physical Device:**
```dart
// Replace with your computer's IP
static const String baseUrl = 'http://192.168.x.x:8000/api';
```

### Firebase Not Working?

```
⚠️  Firebase not initialized
```

**This is OK!** App will run with limited functionality. To enable:
1. Get your Firebase service account JSON
2. Place in: `secrets/service-account.json`
3. Restart backend

---

## ✅ Everything Fixed!

### Login Screen
- **Title:** Reduced from massive 30sp to normal 18px ✅
- **Buttons:** All 16px with consistent weight ✅
- **Responsive:** Adapts to all screen sizes ✅

### Backend
- **Running:** http://localhost:8000 ✅
- **Tested:** Health check passes ✅
- **CORS:** Enabled for Flutter ✅
- **API Docs:** Available at /docs ✅

### Frontend → Backend
- **baseUrl:** Correctly set to Python backend ✅
- **Endpoints:** All mapped correctly ✅
- **Auth:** JWT token system working ✅
- **Biometrics:** Integrated with backend ✅

---

## 🎉 Ready to Test!

1. **Start Backend:** `start_backend.bat` or `start_backend.ps1`
2. **Start Frontend:** `flutter run`
3. **Test:** Try registering a user in the app!

### Quick Test Flow:
1. Open app → Welcome screen
2. Tap "Get Started"
3. Fill signup form
4. (Optional) Enroll voice/face biometrics
5. Tap "Register"
6. **Should succeed and log you in!** ✅

---

**Need More Help?**
- Backend logs: Check the terminal where backend is running
- Frontend logs: Check Flutter debug console
- API testing: Use http://localhost:8000/docs

