# 🚀 Quick Test Guide

## Test Your New Features in 5 Minutes!

### ✅ 1. Test Gemini AI Chatbot (2 min)

**Open Chatbot**:
```
Dashboard → Menu → Support/Help
```

**Try These Questions**:
```
English:
- "How do I save money in Jasho?"
- "Tell me about standing orders"
- "How do I post a job?"

Swahili:
- "Nisaidie kuhusu akiba"
- "Naweza kupata mkopo?"
- "Jinsi ya kutumia mkoba"
```

**Test Voice Mode**:
1. Tap 🎤 microphone icon
2. Speak: "How do I apply for insurance?"
3. Listen to response (feminine Kenyan voice)
4. Tap language switcher for Swahili voice

---

### ✅ 2. Test Balance Masking (1 min)

**Dashboard**:
1. Look at wallet card → See `KES ••••••`
2. Tap 👁️ eye icon → See `KES 12,500.00`
3. Wait 10 seconds → Balance auto-hides

**AI Insights**:
1. Navigate to AI Insights screen
2. See wallet balance card
3. Tap eye icon → See balance
4. Timer auto-hides after 10s

---

### ✅ 3. Test Spending Notifications (1 min)

**Simulate Large Withdrawal**:
1. Go to Wallet → Withdraw
2. Enter: `6000` (exceeds KES 5,000 threshold)
3. Enter PIN
4. See notification: "⚠️ Large Withdrawal Alert"

---

### ✅ 4. Test Responsiveness (1 min)

**Resize Window (Web)**:
1. Make browser narrow → Text & buttons resize
2. Make browser wide → Layout expands
3. Check: Dashboard, AI Insights, Chatbot

**Mobile/Tablet**:
- Test on actual device or emulator
- All elements should scale beautifully

---

## 🎯 Expected Results

### Gemini AI Chatbot
- ✅ Responds intelligently (not just keywords)
- ✅ Switches language smoothly
- ✅ Speaks with feminine Kenyan voice
- ✅ Provides detailed, helpful answers

### Balance Masking
- ✅ Default hidden (`••••••`)
- ✅ Shows `12,500.00` when revealed
- ✅ Auto-hides after 10 seconds
- ✅ Visual "Auto-hides in 10s" indicator

### Notifications
- ✅ Large withdrawal alert (> KES 5,000)
- ✅ Unusual spending alert (3x average)
- ✅ Beautiful in-app notifications
- ✅ Clear, actionable messages

### Responsiveness
- ✅ Text scales (12-20pt)
- ✅ Icons resize (22-28px)
- ✅ Padding adapts
- ✅ No overflow errors

---

## 🐛 Troubleshooting

### Gemini AI Not Responding
**Check**:
1. API key is in `lib/config/api_keys.dart`
2. Internet connection active
3. Console for error messages
4. Fallback responses still work

**Fix**: AI falls back to local responses if API fails

### Notifications Not Showing
**Check**:
1. Withdrawal amount > KES 5,000
2. Permissions granted
3. `NotificationService` initialized

### Balance Not Auto-Hiding
**Check**:
1. Timer is set (10 seconds)
2. Component still mounted
3. No interference from user interactions

---

## 📋 Test Checklist

- [ ] Chatbot responds intelligently in English
- [ ] Chatbot responds intelligently in Swahili
- [ ] Voice mode works (mic + speaker)
- [ ] Language switcher changes voice accent
- [ ] Balance shows KES 12,500
- [ ] Balance is masked by default
- [ ] Eye icon toggles visibility
- [ ] Balance auto-hides after 10s
- [ ] Large withdrawal triggers notification
- [ ] All screens are responsive
- [ ] Brand color (green) consistent throughout

---

## 🎉 All Working?

**Congratulations!** 🎊

Your Jasho app now has:
- 🤖 Google Gemini AI chatbot
- 🔔 Smart spending notifications
- 🔒 Secure balance masking
- 🌍 Full bilingual support
- 📱 Perfect responsiveness

**Ready for real users!** 🚀

---

*Next Steps*:
1. Test on real devices
2. Get user feedback
3. Monitor Gemini API usage
4. Deploy to production


