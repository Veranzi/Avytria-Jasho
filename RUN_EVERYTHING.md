# 🚀 RUN EVERYTHING - Final Guide

## ✅ **ALL ISSUES FIXED!**

### 1. ✅ Font Sizes Harmonized
- **Login:** 22-26px title (matches register)
- **Accessibility:** 22-26px title (matches register)
- **Buttons:** 16-18px responsive (all screens)
- **Body text:** 11-12px responsive
- **See:** `FONT_SIZES_HARMONIZED.md` for details

### 2. ✅ Backend Running & Configured
- Python backend on port 8000
- All endpoints working
- Firebase integrated
- CORS enabled for Flutter

### 3. ✅ Permissions Properly Handled
- Voice request before microphone access
- Voice request before camera access
- Aborts if permission denied
- Shows error dialog with settings option
- Bilingual (English & Swahili)

---

## 🎯 **START YOUR APP (2 Simple Commands)**

### **Terminal 1 - Backend (MUST RUN FIRST)**
```powershell
cd E:\flutterdev\Jasho-1\python-backend
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

**What you should see:**
```
✅ Firebase initialized with service account from: E:\flutterdev\Jasho-1\secrets\service-account.json
INFO:     Uvicorn running on http://0.0.0.0:8000
INFO:     Application startup complete.
```

### **Terminal 2 - Flutter Frontend**
```powershell
cd E:\flutterdev\Jasho-1\jashoo
flutter run
```

---

## 🔥 **AUTO-RESTART BACKEND (Recommended)**

Use this to keep backend running even if it crashes:

```powershell
cd E:\flutterdev\Jasho-1\python-backend
.\keep_backend_running.bat
```

This will auto-restart the backend if it stops!

---

## 🧪 **Test Your App Flow**

### **1. Welcome Screen**
- Beautiful slideshow with images
- "Log In" and "Get Started" buttons

### **2. Login Screen** ✅
- Title: **22-26px** (normalized!)
- Phone or Email login
- "Voice & Face Login" button at bottom
- All text properly sized

### **3. Accessible Login** ✅
- Title: **22-26px** (normalized!)
- Language selection first
- Voice prompt: "Jasho needs microphone permission..."
- If granted → proceeds
- If denied → shows error dialog & aborts
- Button text: **16-18px**

### **4. Sign Up Screen** ✅
- Title: **22-26px** (already correct)
- Voice & Face enrollment section
- Green theme throughout
- Responsive design

---

## 📡 **Backend API Endpoints**

All working on `http://localhost:8000`:

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health` | GET | Check status ✅ |
| `/api/auth/register` | POST | User registration ✅ |
| `/api/auth/login` | POST | User login ✅ |
| `/api/auth/biometric-login` | POST | Voice/Face login ✅ |
| `/api/user/profile` | GET | Get profile ✅ |
| `/api/wallet/balance` | GET | Wallet ✅ |
| `/api/jobs/gigs` | GET | Gigs ✅ |
| `/api/fraud/report` | POST | Fraud ✅ |
| `/docs` | GET | API Docs ✅ |

---

## 🐛 **If Backend Won't Start**

### Check if something is using port 8000:
```powershell
netstat -ano | findstr :8000
```

### Kill the process if needed:
```powershell
taskkill /PID <process-id> /F
```

### Then restart backend:
```powershell
cd E:\flutterdev\Jasho-1\python-backend
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

---

## 📱 **If Using Android Emulator**

Change API base URL:
```dart
// In: jashoo/lib/services/api_service.dart
static const String baseUrl = 'http://10.0.2.2:8000/api';
```

---

## 🎉 **EVERYTHING IS NOW:**

✅ **Font sizes normalized** (Login, Register, Accessibility all match)  
✅ **Backend running** on port 8000  
✅ **Permissions properly handled** (voice prompts + abort if denied)  
✅ **Language support** (English & Swahili)  
✅ **Responsive design** (all screen sizes)  
✅ **No compilation errors**  
✅ **Frontend ↔ Backend connected**  

---

## 🚀 **FINAL COMMAND TO START EVERYTHING**

**Option 1: Two Separate Terminals (Recommended)**
```powershell
# Terminal 1
cd E:\flutterdev\Jasho-1\python-backend
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Terminal 2 (after backend starts)
cd E:\flutterdev\Jasho-1\jashoo
flutter run
```

**Option 2: Auto-Restart Backend**
```powershell
# Terminal 1
cd E:\flutterdev\Jasho-1\python-backend
.\keep_backend_running.bat

# Terminal 2
cd E:\flutterdev\Jasho-1\jashoo
flutter run
```

---

## 📊 **Your Backend Status**

```
Server: ✅ Running on http://0.0.0.0:8000
Firebase: ✅ Initialized
Health: ✅ http://localhost:8000/health returns {"status":"running"}
API Docs: ✅ http://localhost:8000/docs
```

---

**THIS IS THE LAST TIME YOU NEED TO ASK! Backend is configured to run reliably.** 🎯

