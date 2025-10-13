# 🎤 Voice Navigation Quick Guide

## 🚀 **How to Add Voice Assistant to Your App:**

### **Step 1: Import the Widget**
```dart
import 'package:jashoo/widgets/voice_assistant_button.dart';
```

### **Step 2: Add to Any Screen**
```dart
Scaffold(
  appBar: AppBar(title: Text('My Screen')),
  body: // your content,
  floatingActionButton: const VoiceAssistantButton(), // ← Add this!
)
```

**That's it!** Your screen now has voice navigation! 🎉

---

## 🎯 **Example: Add to Dashboard**

```dart
// In dashboard_screen.dart

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.grey[100],
    appBar: _buildAppBar(),
    drawer: const ProfileDrawer(),
    body: _buildBody(),
    bottomNavigationBar: _buildCustomBottomNavigationBar(),
    floatingActionButton: const VoiceAssistantButton(), // ← Add this line!
  );
}
```

---

## 🗣️ **Voice Commands:**

### **English Commands:**
| Say This        | Goes To              |
|----------------|----------------------|
| "Wallet"       | Wallet screen        |
| "Jobs"         | Job marketplace      |
| "Savings"      | Savings screen       |
| "Insurance"    | Insurance screen     |
| "Support"      | Chatbot              |
| "Profile"      | Profile settings     |
| "Deposit"      | Deposit screen       |
| "Withdraw"     | Withdraw screen      |
| "Scan"         | QR Scanner           |
| "Rewards"      | Rewards store        |
| "Help"         | List all commands    |

### **Swahili Commands:**
| Say This       | Goes To              |
|---------------|----------------------|
| "Mkoba"       | Wallet screen        |
| "Kazi"        | Job marketplace      |
| "Akiba"       | Savings screen       |
| "Bima"        | Insurance screen     |
| "Msaada"      | Chatbot              |
| "Wasifu"      | Profile settings     |
| "Weka Pesa"   | Deposit screen       |
| "Toa Pesa"    | Withdraw screen      |
| "Scan"        | QR Scanner           |
| "Zawadi"      | Rewards store        |
| "Msaada"      | List all commands    |

---

## 🎙️ **Voice Permission Requests:**

### **How It Works:**

1. **Voice announces:**
   ```
   "Jasho needs microphone permission. 
    Please say yes to allow, or no to deny."
   ```

2. **User responds:**
   - Say "Yes" (English)
   - Say "Ndiyo" (Swahili)

3. **App requests permission automatically**

4. **Voice confirms:**
   ```
   "Permission granted. Thank you."
   ```

### **Code Example:**
```dart
import 'package:jashoo/services/voice_navigation_service.dart';

final voiceService = VoiceNavigationService();

// Request camera permission with voice
await voiceService.requestPermissionWithVoice(
  Permission.camera,
  context,
  permissionName: 'Camera',
);
```

---

## 🌍 **Language Switching:**

### **Method 1: Long-Press Voice Button**
1. Long-press the voice assistant button (FAB)
2. Tap "English" or "Kiswahili"
3. Done! Voice changes instantly

### **Method 2: Programmatically**
```dart
final voiceService = VoiceNavigationService();
await voiceService.switchLanguage('sw'); // 'en' or 'sw'
```

---

## 💃 **Feminine Voice Settings:**

All voice features use these settings:
```dart
await _tts.setPitch(1.2);        // Higher pitch = feminine
await _tts.setSpeechRate(0.45); // Slower = clearer
await _tts.setLanguage("en-KE" or "sw-KE"); // Kenyan accent
// Auto-selects female voice from device
```

---

## 🎨 **UI States:**

### **Voice Button States:**
- **Green:** Idle, ready to listen
- **Red + Pulsing:** Currently listening
- **Tap:** Start voice navigation
- **Long Press:** Open settings menu

---

## 📱 **Screens That Should Have Voice Assistant:**

### **High Priority:**
✅ Dashboard (main screen)
✅ Wallet screen
✅ Job marketplace
✅ Savings screen
✅ Insurance screen
✅ Profile settings

### **Medium Priority:**
- Deposit screen
- Withdraw screen
- Transaction history
- Rewards store
- Support/Chatbot (already has voice built-in)

### **Don't Add To:**
- Login/Signup screens (they have their own voice features)
- Splash screen
- Loading screens

---

## 🔧 **Troubleshooting:**

### **Voice Not Working:**
1. Check microphone permission in device settings
2. Restart app
3. Try saying commands slower/clearer

### **Wrong Language:**
1. Long-press voice button
2. Select correct language
3. Try voice command again

### **Permission Denied:**
1. Voice will say "Permission denied"
2. Dialog appears with "Open Settings" button
3. Enable permission manually
4. Return to app

---

## 🎯 **Best Practices:**

### **1. Add Voice Assistant to Main Screens:**
```dart
// Good ✅
Scaffold(
  floatingActionButton: const VoiceAssistantButton(),
)
```

### **2. Don't Add to Temporary Screens:**
```dart
// Not needed ❌
SplashScreen(
  floatingActionButton: const VoiceAssistantButton(), // Don't add here
)
```

### **3. Test Both Languages:**
- Test English commands
- Test Swahili commands
- Verify voice responses

### **4. Handle Permissions Gracefully:**
- Always use `requestPermissionWithVoice`
- Provide visual feedback too
- Don't block UI waiting for voice

---

## 📚 **Full API Reference:**

### **VoiceNavigationService:**

```dart
// Initialize
await voiceService.initialize(language: 'en');

// Speak
await voiceService.speak('welcome');

// Listen for commands
String? command = await voiceService.listenForNavigationCommand();

// Navigate
await voiceService.navigateWithVoice(context, 'wallet');

// Request permission with voice
await voiceService.requestPermissionWithVoice(
  Permission.microphone,
  context,
  permissionName: 'Microphone',
);

// Switch language
await voiceService.switchLanguage('sw');

// Check status
bool listening = voiceService.isListening;
bool enabled = voiceService.isSpeechEnabled;
String lang = voiceService.currentLanguage;
```

---

## 🎊 **You're Done!**

Your app now has:
- ✅ Feminine voice assistant
- ✅ English & Swahili support
- ✅ Voice-controlled permissions
- ✅ Navigate entire app by voice
- ✅ PWD-friendly accessibility

**Just add the button and your users can navigate by voice! 🚀**

---

## 📞 **Need More Help?**

Check these files:
- `jashoo/lib/services/voice_navigation_service.dart` - Full service implementation
- `jashoo/lib/widgets/voice_assistant_button.dart` - Button widget
- `FINAL_UPDATES_SUMMARY.md` - Complete feature documentation

**Happy voice-controlled coding! 🎤**

