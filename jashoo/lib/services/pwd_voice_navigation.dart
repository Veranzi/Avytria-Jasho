import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

/// PWD Voice Navigation Service
/// Specifically designed for people with disabilities
/// Provides hands-free navigation from welcome screen
class PWDVoiceNavigation {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _isListening = false;
  bool _isInitialized = false;
  String _currentLanguage = 'en-KE';

  // Voice settings for PWD (clear, slow, feminine)
  static const double VOICE_PITCH = 1.2; // Feminine
  static const double VOICE_RATE = 0.4; // Slow and clear
  static const double VOICE_VOLUME = 1.0; // Maximum volume

  /// Initialize voice services
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Initialize Speech Recognition
      bool available = await _speech.initialize(
        onError: (error) => debugPrint('[PWD Voice] Speech error: $error'),
        onStatus: (status) => debugPrint('[PWD Voice] Speech status: $status'),
      );

      if (!available) {
        debugPrint('[PWD Voice] Speech recognition not available');
        return false;
      }

      // Initialize Text-to-Speech
      await _tts.setLanguage(_currentLanguage);
      await _tts.setPitch(VOICE_PITCH);
      await _tts.setSpeechRate(VOICE_RATE);
      await _tts.setVolume(VOICE_VOLUME);

      _isInitialized = true;
      debugPrint('[PWD Voice] ✅ Initialized successfully');
      return true;
    } catch (e) {
      debugPrint('[PWD Voice] ❌ Initialization failed: $e');
      return false;
    }
  }

  /// Speak welcome message for PWD users
  Future<void> speakWelcome() async {
    if (!_isInitialized) await initialize();

    final message = _currentLanguage == 'sw-KE'
        ? 'Karibu kwenye Jasho. Sema "Ingia" ili kuingia, au "Jiandikishe" ili kutengeneza akaunti'
        : 'Welcome to Jasho. Say "Login" to log in, or say "Sign up" to create an account';

    await _tts.speak(message);
  }

  /// Start listening for voice commands
  Future<void> startListening({
    required Function(String) onNavigate,
    required Function(String) onCommand,
  }) async {
    if (!_isInitialized) await initialize();
    if (_isListening) return;

    _isListening = true;

    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          final command = result.recognizedWords.toLowerCase();
          debugPrint('[PWD Voice] Command heard: $command');

          // Process command
          _processCommand(command, onNavigate, onCommand);

          // Continue listening for next command
          if (_isListening) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (_isListening)
                startListening(onNavigate: onNavigate, onCommand: onCommand);
            });
          }
        }
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      partialResults: false,
      localeId: _currentLanguage,
    );
  }

  /// Process voice command
  void _processCommand(
    String command,
    Function(String) onNavigate,
    Function(String) onCommand,
  ) {
    // English commands
    if (command.contains('login') || command.contains('log in')) {
      _confirmAndNavigate('login', onNavigate);
    } else if (command.contains('sign up') ||
        command.contains('signup') ||
        command.contains('register') ||
        command.contains('get started')) {
      _confirmAndNavigate('signup', onNavigate);
    } else if (command.contains('help') || command.contains('assist')) {
      onCommand('help');
      speakWelcome();
    } else if (command.contains('turn off') ||
        command.contains('stop') ||
        command.contains('exit')) {
      onCommand('exit');
      _speak('Voice navigation turned off');
      stopListening();
    }
    // Swahili commands
    else if (command.contains('ingia')) {
      _confirmAndNavigate('login', onNavigate);
    } else if (command.contains('jiandikishe') || command.contains('anza')) {
      _confirmAndNavigate('signup', onNavigate);
    } else if (command.contains('msaada')) {
      onCommand('help');
      speakWelcome();
    } else if (command.contains('zima')) {
      onCommand('exit');
      _speak('Sauti imezimwa');
      stopListening();
    }
    // Unknown command
    else {
      _speak('Sorry, I did not understand. Please say Login, Sign up, or Help');
    }
  }

  /// Confirm and navigate
  void _confirmAndNavigate(
    String destination,
    Function(String) onNavigate,
  ) async {
    final message = destination == 'login'
        ? 'Navigating to login'
        : 'Navigating to sign up';

    await _speak(message);
    await Future.delayed(const Duration(milliseconds: 800));
    onNavigate(destination);
  }

  /// Speak a message
  Future<void> _speak(String message) async {
    await _tts.speak(message);
  }

  /// Stop listening
  void stopListening() {
    _isListening = false;
    _speech.stop();
  }

  /// Change language
  Future<void> setLanguage(String language) async {
    _currentLanguage = language;
    await _tts.setLanguage(language);
  }

  /// Check if listening
  bool get isListening => _isListening;

  /// Clean up
  void dispose() {
    stopListening();
    _speech.cancel();
  }
}
