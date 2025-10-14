# ♿ PWD Mode Toggle - Accessibility for People with Disabilities

## ✅ What Was Changed

Voice controls (microphone and speaker buttons) are now **ONLY visible to users who enable PWD mode**. Regular users won't see these controls unless they specifically need them.

---

## 🎯 How It Works

### **1. PWD Mode Toggle Button**
- **Location**: Bottom-left corner of Welcome Screen
- **Appearance**: 
  - Shows ♿ accessibility icon
  - Text: "Accessibility OFF" (gray) or "Accessibility ON" (green)
  - Semi-transparent white rounded pill button

### **2. When Disabled (Default)**
- ❌ No microphone button visible
- ❌ No speaker button visible
- ❌ No voice navigation active
- ✅ Normal user experience

### **3. When Enabled (PWD Users)**
- ✅ Microphone button appears (top-right)
- ✅ Speaker button appears (top-right)
- ✅ Voice navigation activates
- ✅ Text-to-speech announces screen content
- ✅ Speech-to-text listens for commands

---

## 🎨 Visual Design

### **PWD Toggle Button (Bottom-Left)**
```
┌─────────────────────────┐
│ ♿ Accessibility OFF     │  ← Gray when disabled
└─────────────────────────┘

┌─────────────────────────┐
│ ♿ Accessibility ON      │  ← Green when enabled
└─────────────────────────┘
```

### **Voice Controls (Top-Right, only when PWD ON)**
```
   🔊  🎤  ← Circular buttons
  (Speaker) (Microphone)
```

---

## 🔧 Technical Implementation

### **Files Created:**
1. **`jashoo/lib/services/pwd_service.dart`**
   - Manages PWD mode state using SharedPreferences
   - Persists setting across app restarts
   - Simple API: `enablePWDMode()`, `disablePWDMode()`, `togglePWDMode()`

### **Files Modified:**
2. **`jashoo/lib/screens/auth/welcome_screen.dart`**
   - Added `_isPWDMode` state variable
   - Conditionally shows voice controls based on PWD mode
   - Added PWD toggle button at bottom-left
   - Voice features only initialize when PWD mode is ON

---

## 📱 User Experience

### **Regular User Journey:**
1. Opens app → Sees normal welcome screen
2. No voice controls visible
3. Clean, simple interface
4. Can tap "Log In" or "Get Started"

### **PWD User Journey:**
1. Opens app → Sees normal welcome screen
2. Taps "♿ Accessibility OFF" button (bottom-left)
3. Button turns green "♿ Accessibility ON"
4. Voice controls appear (top-right)
5. Can now use voice to navigate
6. Screen content is announced automatically
7. Can say "login", "get started", "next slide", etc.

---

## 🎤 Voice Controls (When PWD Mode ON)

### **🔊 Speaker Button (Top-Right)**
- **Purpose**: Hear screen content read aloud
- **Action**: Tap to announce current screen
- **Voice**: Feminine Kenyan English voice
- **Content**: Reads welcome messages and slide descriptions

### **🎤 Microphone Button (Top-Right)**
- **Purpose**: Give voice commands
- **Appearance**: 
  - Gray outline when idle
  - Green filled when listening
- **Commands**:
  - "login" → Navigate to login
  - "get started" → Navigate to signup
  - "next" or "next slide" → Go to next slide
  - "previous" or "back" → Go to previous slide

---

## 💾 Persistence

### **PWD Mode Setting is Saved:**
- ✅ Persists across app restarts
- ✅ Uses SharedPreferences (local storage)
- ✅ No server storage needed
- ✅ User choice is remembered

**Example:**
```dart
// Check if PWD mode is enabled
final isPWD = await PWDService.isPWDModeEnabled();

// Enable PWD mode
await PWDService.enablePWDMode();

// Disable PWD mode  
await PWDService.disablePWDMode();

// Toggle PWD mode
final newState = await PWDService.togglePWDMode();
```

---

## 🎯 Why This Approach?

### **Benefits:**
1. **Privacy**: Voice controls only shown to those who need them
2. **Clean UI**: Regular users see simpler interface
3. **Accessibility**: PWD users get full voice support
4. **User Control**: Anyone can enable/disable at any time
5. **Discoverable**: Accessible button clearly visible
6. **Persistent**: Setting saved across sessions

### **Inclusive Design:**
- Anyone can enable PWD mode (not just registered users)
- No stigma - it's called "Accessibility Mode"
- Easy to toggle on/off
- Visual feedback (color changes)
- Toast messages confirm state changes

---

## 📊 Summary

| Feature | Before | After |
|---------|--------|-------|
| Voice Controls | Always visible | Only when PWD mode ON |
| Toggle Button | ❌ None | ✅ Bottom-left corner |
| User Control | ❌ No choice | ✅ Full control |
| Default State | Voice ON | Voice OFF |
| Persistence | ❌ None | ✅ Saved locally |
| UI Clutter | High (for regular users) | Low (clean by default) |
| PWD Support | Always on | On-demand |

---

## 🚀 How to Test

### **Test 1: Enable PWD Mode**
1. Open Jasho app
2. See "♿ Accessibility OFF" button (bottom-left)
3. Tap it
4. See green toast: "♿ Accessibility mode enabled"
5. Button turns green: "♿ Accessibility ON"
6. Voice controls appear (top-right)
7. Tap 🔊 to hear screen content
8. Tap 🎤 to start listening
9. Say "next" to change slide

### **Test 2: Disable PWD Mode**
1. With PWD mode ON
2. Tap "♿ Accessibility ON" button
3. See gray toast: "Accessibility mode disabled"
4. Button turns gray: "♿ Accessibility OFF"
5. Voice controls disappear
6. Clean interface restored

### **Test 3: Persistence**
1. Enable PWD mode
2. Close app completely
3. Reopen app
4. PWD mode still ON
5. Voice controls still visible

---

## ✅ Result

**Voice controls are now privacy-friendly and only visible to PWD users!** 🎉

Regular users enjoy a clean interface, while users with disabilities can easily enable full voice support with one tap.

