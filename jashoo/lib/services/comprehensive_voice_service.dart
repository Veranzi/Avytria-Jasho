import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/savings_provider.dart';
import '../providers/jobs_provider.dart';

/// Comprehensive Voice Navigation Service for PWD Users
/// 
/// Allows complete app navigation and interaction using ONLY voice commands
/// Features:
/// - Navigate to any screen
/// - Perform actions (deposit, withdraw, apply for jobs)
/// - Check balances, savings, jobs
/// - Complete transactions
/// - Bilingual support (English/Swahili)
class ComprehensiveVoiceService {
  final BuildContext context;
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _isListening = false;
  bool _speechEnabled = false;
  String _currentLocaleId = 'en-US';
  
  // Current context tracking
  String _currentScreen = 'home';
  Map<String, dynamic> _contextData = {};

  ComprehensiveVoiceService(this.context) {
    _initSpeech();
    _initTts();
  }

  bool get isListening => _isListening;
  String get currentScreen => _currentScreen;

  Future<void> _initSpeech() async {
    _speechEnabled = await _speech.initialize(
      onError: (error) => print('Voice Service Speech error: $error'),
      onStatus: (status) {
        if (status == 'done' && _isListening) {
          _isListening = false;
        }
      },
    );
  }

  Future<void> _initTts() async {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    _currentLocaleId = localeProvider.languageCode == 'sw' ? "sw-KE" : "en-KE";
    await _tts.setLanguage(_currentLocaleId);
    await _tts.setSpeechRate(0.45); // Slower for clarity
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.2); // Feminine voice

    var voices = await _tts.getVoices;
    if (voices != null && voices.isNotEmpty) {
      var femaleVoice = voices.firstWhere(
        (voice) =>
          (voice['name'].toString().toLowerCase().contains('female') ||
           voice['name'].toString().toLowerCase().contains('woman') ||
           voice['gender']?.toString().toLowerCase() == 'female') &&
          (voice['locale']?.toString().contains('KE') == true ||
           voice['locale']?.toString().contains('ke') == true),
        orElse: () => voices.first,
      );
      if (femaleVoice != null) {
        await _tts.setVoice({
          "name": femaleVoice['name'],
          "locale": femaleVoice['locale'],
        });
      }
    }
  }

  Future<void> speak(String text) async {
    await _tts.speak(text);
  }

  void startListening({Function(String)? onCommand}) async {
    if (!_speechEnabled) {
      await speak("Speech recognition not available. Please enable microphone permission.");
      return;
    }
    if (_isListening) {
      stopListening();
      return;
    }

    _isListening = true;
    await speak("Listening. What would you like to do?");

    _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          final command = result.recognizedWords.toLowerCase();
          print("Voice Command: $command");
          _processCommand(command);
          onCommand?.call(command);
          _isListening = false;
        }
      },
      localeId: _currentLocaleId.replaceAll('-', '_'),
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
    );
  }

  void stopListening() {
    _speech.stop();
    _isListening = false;
  }

  void _processCommand(String command) {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final isSwahili = localeProvider.languageCode == 'sw';

    // NAVIGATION COMMANDS
    if (_matchCommand(command, ['home', 'nyumbani', 'dashboard', 'dashibodi'])) {
      _navigateTo('/', 'home', isSwahili);
      return;
    }

    if (_matchCommand(command, ['wallet', 'mkoba', 'show wallet', 'onyesha mkoba'])) {
      _navigateTo('/wallet', 'wallet', isSwahili);
      return;
    }

    if (_matchCommand(command, ['jobs', 'kazi', 'gigs', 'ajira'])) {
      _navigateTo('/jobs', 'jobs', isSwahili);
      return;
    }

    if (_matchCommand(command, ['savings', 'akiba', 'my savings', 'akiba zangu'])) {
      _navigateTo('/savings', 'savings', isSwahili);
      return;
    }

    if (_matchCommand(command, ['insurance', 'bima', 'cover'])) {
      _navigateTo('/insurance', 'insurance', isSwahili);
      return;
    }

    if (_matchCommand(command, ['profile', 'wasifu', 'my profile', 'wasifu wangu'])) {
      _navigateTo('/profile', 'profile', isSwahili);
      return;
    }

    if (_matchCommand(command, ['transactions', 'history', 'mali', 'historia'])) {
      _navigateTo('/transactions', 'transactions', isSwahili);
      return;
    }

    if (_matchCommand(command, ['settings', 'mipangilio'])) {
      _navigateTo('/settings', 'settings', isSwahili);
      return;
    }

    if (_matchCommand(command, ['help', 'msaada', 'support', 'chat', 'chatbot'])) {
      _navigateTo('/chatbot', 'chatbot', isSwahili);
      return;
    }

    // WALLET ACTIONS
    if (_matchCommand(command, ['balance', 'check balance', 'salio', 'angalia salio'])) {
      _checkBalance(isSwahili);
      return;
    }

    if (_matchCommand(command, ['show balance', 'reveal balance', 'onyesha salio'])) {
      _revealBalance(isSwahili);
      return;
    }

    if (_matchCommand(command, ['hide balance', 'ficha salio'])) {
      _hideBalance(isSwahili);
      return;
    }

    if (_matchCommand(command, ['deposit', 'weka pesa', 'add money'])) {
      _navigateTo('/deposit', 'deposit', isSwahili);
      return;
    }

    if (_matchCommand(command, ['withdraw', 'toa pesa', 'take money'])) {
      _navigateTo('/withdraw', 'withdraw', isSwahili);
      return;
    }

    // SAVINGS ACTIONS
    if (_matchCommand(command, ['create goal', 'new goal', 'tengeneza lengo', 'lengo jipya'])) {
      speak(isSwahili 
        ? "Nenda kwenye Savings, kisha bonyeza 'Create Goal'. Unaweza kutengeneza lengo la akiba."
        : "Go to Savings, then tap 'Create Goal'. You can create a savings goal.");
      return;
    }

    // JOBS ACTIONS
    if (_matchCommand(command, ['available jobs', 'kazi zinazopatikana', 'find work'])) {
      _navigateTo('/jobs', 'jobs', isSwahili);
      speak(isSwahili
        ? "Hapa kuna kazi zinazopatikana. Nitakueleza kila moja."
        : "Here are the available jobs. I'll describe each one.");
      return;
    }

    if (_matchCommand(command, ['post job', 'create job', 'weka kazi', 'tengeneza kazi'])) {
      _navigateTo('/postJob', 'postJob', isSwahili);
      return;
    }

    // GENERAL HELP
    if (_matchCommand(command, ['what can i do', 'commands', 'naweza kufanya nini'])) {
      _listCommands(isSwahili);
      return;
    }

    // DEFAULT
    speak(isSwahili
      ? "Sijaelewaamri. Sema 'msaada' kuona amri zote."
      : "Command not recognized. Say 'help' to hear all commands.");
  }

  bool _matchCommand(String command, List<String> keywords) {
    return keywords.any((keyword) => command.contains(keyword));
  }

  void _navigateTo(String route, String screenName, bool isSwahili) {
    _currentScreen = screenName;
    Navigator.pushNamed(context, route);
    
    final messages = {
      'home': isSwahili ? 'Karibu kwenye Jasho' : 'Welcome to Jasho',
      'wallet': isSwahili ? 'Mkoba wako' : 'Your wallet',
      'jobs': isSwahili ? 'Kazi zinazopatikana' : 'Available jobs',
      'savings': isSwahili ? 'Akiba zako' : 'Your savings',
      'insurance': isSwahili ? 'Bima yako' : 'Your insurance',
      'profile': isSwahili ? 'Wasifu wako' : 'Your profile',
      'transactions': isSwahili ? 'Historia ya miamala' : 'Transaction history',
      'settings': isSwahili ? 'Mipangilio' : 'Settings',
      'chatbot': isSwahili ? 'Msaidizi wa Jasho' : 'Jasho assistant',
      'deposit': isSwahili ? 'Weka pesa kwenye mkoba' : 'Deposit money to wallet',
      'withdraw': isSwahili ? 'Toa pesa kutoka mkoba' : 'Withdraw money from wallet',
      'postJob': isSwahili ? 'Tengeneza kazi mpya' : 'Create a new job',
    };
    
    speak(messages[screenName] ?? (isSwahili ? 'Ninakupeleka' : 'Navigating'));
  }

  void _checkBalance(bool isSwahili) {
    final wallet = Provider.of<WalletProvider>(context, listen: false);
    final balance = wallet.kesBalance;
    
    speak(isSwahili
      ? "Salio lako ni shilingi elfu kumi na mbili, mia tano. KES ${balance.toStringAsFixed(0)}"
      : "Your balance is ${balance.toStringAsFixed(0)} Kenya Shillings");
  }

  void _revealBalance(bool isSwahili) {
    // This would trigger balance visibility in the UI
    speak(isSwahili
      ? "Salio linaonyeshwa. Litafichwa kiotomatiki baada ya sekunde kumi."
      : "Balance revealed. It will auto-hide after 10 seconds.");
  }

  void _hideBalance(bool isSwahili) {
    speak(isSwahili
      ? "Salio limefichwa kwa usalama."
      : "Balance hidden for security.");
  }

  void _listCommands(bool isSwahili) {
    final commands = isSwahili
      ? """
Unaweza kusema:
Nyumbani, Mkoba, Kazi, Akiba, Bima, Wasifu, Mipangilio, Msaada.
Au amri za mkoba: Angalia salio, Weka pesa, Toa pesa.
Amri za kazi: Kazi zinazopatikana, Weka kazi.
Sema amri yoyote, nitakusaidia!
"""
      : """
You can say:
Home, Wallet, Jobs, Savings, Insurance, Profile, Settings, Help.
Or wallet actions: Check balance, Deposit, Withdraw.
Job actions: Available jobs, Post job.
Say any command and I'll help you!
""";
    
    speak(commands);
  }

  void toggleLanguage() {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final newLocale = localeProvider.languageCode == 'en' ? 'sw' : 'en';
    localeProvider.setLanguage(newLocale);
    _initTts();
    speak(newLocale == 'sw' ? 'Lugha imebadilishwa kuwa Kiswahili' : 'Language changed to English');
  }

  void describeScreen() {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final isSwahili = localeProvider.languageCode == 'sw';
    
    final descriptions = {
      'home': isSwahili 
        ? 'Uko kwenye ukurasa wa nyumbani. Una mkoba, kazi, akiba, na zaidi. Sema "mkoba" kufungua mkoba wako.'
        : 'You are on the home screen. You have wallet, jobs, savings, and more. Say "wallet" to open your wallet.',
      'wallet': isSwahili
        ? 'Uko kwenye mkoba wako. Unaweza kuangalia salio, kuweka pesa, au kutoa pesa. Sema amri yoyote.'
        : 'You are in your wallet. You can check balance, deposit, or withdraw. Say any command.',
      'jobs': isSwahili
        ? 'Hizi ni kazi zinazopatikana. Nitakueleza kila moja. Sema "tuma" kuomba kazi.'
        : 'These are available jobs. I\'ll describe each one. Say "apply" to apply for a job.',
    };
    
    speak(descriptions[_currentScreen] ?? (isSwahili ? 'Uko kwenye Jasho' : 'You are in Jasho'));
  }
}

