# Jasho App - Quick Setup Guide

## Prerequisites

- Flutter SDK 3.9.2 or higher
- Node.js 18.0.0 or higher
- Firebase account with Firestore enabled
- Git

---

## 🚀 Quick Start

### 1. Clone the Repository
```bash
git clone <repository-url>
cd Jasho-1
```

### 2. Backend Setup

```bash
# Navigate to backend
cd jashoo-backend

# Install dependencies
npm install

# Create .env file
cat > .env << EOF
PORT=3000
NODE_ENV=development
FIREBASE_PROJECT_ID=your_firebase_project_id
STRIPE_SECRET_KEY=your_stripe_secret_key
PAYPAL_CLIENT_ID=your_paypal_client_id
PAYPAL_SECRET=your_paypal_secret
SMS_API_KEY=your_sms_api_key
OPENAI_API_KEY=your_openai_api_key
JWT_SECRET=your_jwt_secret_key_here
EOF

# Place your Firebase service account JSON
# Copy secrets/service-account.json to the root

# Start the server
npm start
# Or for development with auto-reload:
npm run dev
```

The backend will start on `http://localhost:3000`

### 3. Frontend Setup

```bash
# Navigate to Flutter app
cd ../jashoo

# Get dependencies
flutter pub get

# Update API endpoint (if needed)
# Edit lib/services/api_service.dart
# Change baseUrl to your backend URL

# Run the app
flutter run

# Or for specific platform:
flutter run -d chrome  # Web
flutter run -d android  # Android
flutter run -d ios      # iOS
```

---

## 🔧 Configuration

### Firebase Setup

1. Create a Firebase project at https://console.firebase.google.com
2. Enable Firestore Database
3. Enable Authentication (Email/Password, Phone)
4. Download service account JSON:
   - Go to Project Settings → Service Accounts
   - Click "Generate New Private Key"
   - Save as `secrets/service-account.json`

### Stripe Setup (Optional)

1. Create account at https://stripe.com
2. Get API keys from Dashboard
3. Add to `.env`: `STRIPE_SECRET_KEY=sk_test_...`

### PayPal Setup (Optional)

1. Create developer account at https://developer.paypal.com
2. Create REST API app
3. Add to `.env`:
   ```
   PAYPAL_CLIENT_ID=your_client_id
   PAYPAL_SECRET=your_secret
   ```

### SMS Setup (Optional)

For SMS notifications, integrate with providers like:
- Africa's Talking
- Twilio
- AWS SNS

Add API key to `.env`: `SMS_API_KEY=your_key`

---

## 📱 Running the App

### Development Mode

```bash
# Backend
cd jashoo-backend
npm run dev

# Frontend (new terminal)
cd jashoo
flutter run
```

### Production Build

```bash
# Android APK
flutter build apk --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

---

## 🧪 Testing

### Test Backend

```bash
cd jashoo-backend
npm test
```

### Test Frontend

```bash
cd jashoo
flutter test
```

### Manual Testing Checklist

- [ ] Splash screen appears for 1.5s
- [ ] Welcome page shows with features
- [ ] Login with email/phone works
- [ ] Signup with GDPR consent works
- [ ] Accessible login (voice/face) works
- [ ] Chatbot responds in English & Swahili
- [ ] Notifications appear for transactions
- [ ] Fraud report dialog works
- [ ] Savings goals creation works
- [ ] Standing orders can be set up
- [ ] Job posting and rating works
- [ ] Wallet balances are masked by default
- [ ] Payment methods can be added
- [ ] USSD endpoints respond correctly

---

## 🔑 Default Credentials

For testing, you can create accounts through the signup screen.
No default credentials are provided for security.

---

## 📂 Important Files

### Frontend
- `lib/main.dart` - App entry point
- `lib/routes.dart` - All app routes
- `lib/services/api_service.dart` - API client
- `lib/screens/` - All screens
- `pubspec.yaml` - Dependencies

### Backend
- `server.js` - Server entry point
- `routes/` - API route handlers
- `models/` - Data models
- `middleware/` - Auth, validation, security

---

## 🐛 Troubleshooting

### Backend won't start
- Check if port 3000 is available
- Verify `.env` file exists with all variables
- Check Firebase service account JSON is present

### Flutter won't build
- Run `flutter clean` then `flutter pub get`
- Check Flutter SDK version: `flutter --version`
- Update dependencies: `flutter pub upgrade`

### API calls fail
- Check backend is running
- Verify `baseUrl` in `api_service.dart`
- Check Firebase rules allow read/write
- Enable CORS in backend if needed

### Stripe/PayPal not working
- Verify API keys are correct
- Check if in test mode or live mode
- Verify webhook endpoints are configured

---

## 📊 Database Structure

### Firestore Collections

- `users` - User profiles
- `wallets` - Wallet data
- `transactions` - Transaction history
- `jobs` - Job postings
- `job_applications` - Applications
- `savings_goals` - Savings goals
- `contributions` - Savings contributions
- `loan_requests` - Loan applications
- `ratings` - User and job ratings
- `fraud_reports` - Fraud reports
- `access_logs` - Access logs
- `notifications` - User notifications

---

## 🔒 Security Notes

1. **Never commit**:
   - `.env` file
   - `service-account.json`
   - API keys or secrets

2. **Production**:
   - Use environment variables
   - Enable Firebase security rules
   - Use HTTPS only
   - Implement rate limiting
   - Regular security audits

3. **GDPR**:
   - Log all data access
   - Implement data export
   - Allow account deletion
   - Regular data cleanup

---

## 📞 Support

- **Documentation**: See `IMPLEMENTATION_SUMMARY.md`
- **Issues**: Create GitHub issue
- **Email**: support@jasho.com

---

## ✅ Feature Checklist

- [x] Splash screen → Welcome → Login flow
- [x] Accessibility (voice/face login)
- [x] GDPR compliance with terms
- [x] Enhanced chatbot (voice + EN/SW)
- [x] Notifications & access logs
- [x] Fraud detection & reporting
- [x] Two-tier savings system
- [x] Ratings system (0-5 stars)
- [x] Enhanced wallet (masked + payments)
- [x] USSD integration
- [x] All backend APIs
- [x] No errors

---

**Status**: ✅ Ready for Development/Testing
**Version**: 1.0.0
**Last Updated**: October 11, 2025

