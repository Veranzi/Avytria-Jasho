import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

/// Voice Navigation Service for PWD-friendly app navigation
/// 
/// This service enables users to navigate the entire app using voice commands
/// in both English and Swahili, with a feminine Kenyan voice assistant.
class VoiceNavigationService {
  static final VoiceNavigationService _instance = VoiceNavigationService._internal();
  factory VoiceNavigationService() => _instance;
  VoiceNavigationService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  
  bool _isListening = false;
  bool _speechEnabled = false;
  String _currentLanguage = 'en'; // 'en' or 'sw'
  
  // Voice command mappings (English and Swahili)
  final Map<String, Map<String, List<String>>> _commandMappings = {
    'en': {
      'wallet': ['wallet', 'balance', 'money', 'account'],
      'jobs': ['jobs', 'gigs', 'work', 'marketplace'],
      'savings': ['savings', 'save money', 'goals'],
      'insurance': ['insurance', 'cover', 'policy'],
      'support': ['help', 'support', 'chatbot', 'assistant'],
      'profile': ['profile', 'account', 'settings'],
      'deposit': ['deposit', 'add money', 'top up'],
      'withdraw': ['withdraw', 'send money', 'cash out'],
      'scan': ['scan', 'qr code', 'scanner'],
      'rewards': ['rewards', 'points', 'redeem'],
      'yes': ['yes', 'okay', 'sure', 'allow', 'accept'],
      'no': ['no', 'cancel', 'deny', 'reject'],
    },
    'sw': {
      'wallet': ['mkoba', 'salio', 'pesa', 'akaunti'],
      'jobs': ['kazi', 'ajira', 'jobs'],
      'savings': ['akiba', 'hifadhi pesa', 'malengo'],
      'insurance': ['bima', 'cover'],
      'support': ['msaada', 'usaidizi', 'chatbot'],
      'profile': ['wasifu', 'akaunti', 'mipangilio'],
      'deposit': ['weka pesa', 'ongeza pesa'],
      'withdraw': ['toa pesa', 'withdraw'],
      'scan': ['scan', 'msimbo wa qr'],
      'rewards': ['zawadi', 'pointi'],
      'yes': ['ndiyo', 'sawa', 'ndio', 'kubali'],
      'no': ['hapana', 'sitisha', 'kataa'],
    },
  };
  
  // Voice responses (English and Swahili)
  final Map<String, Map<String, String>> _responses = {
    'en': {
      'welcome': 'Welcome to Jasho. Say the name of any feature to navigate, or say help for assistance.',
      'help': 'You can say: Wallet, Jobs, Savings, Insurance, Support, Profile, Deposit, Withdraw, Scan, or Rewards. I will take you there.',
      'wallet': 'Opening wallet',
      'jobs': 'Opening job marketplace',
      'savings': 'Opening savings',
      'insurance': 'Opening insurance',
      'support': 'Opening support chat',
      'profile': 'Opening profile',
      'deposit': 'Opening deposit screen',
      'withdraw': 'Opening withdraw screen',
      'scan': 'Opening QR scanner',
      'rewards': 'Opening rewards store',
      'not_understood': 'Sorry, I did not understand. Please say that again, or say help for options.',
      'permission_granted': 'Permission granted. Thank you.',
      'permission_denied': 'Permission denied. Cannot proceed without access.',
    },
    'sw': {
      'welcome': 'Karibu Jasho. Sema jina la kipengele chochote kuongoza, au sema msaada kwa usaidizi.',
      'help': 'Unaweza kusema: Mkoba, Kazi, Akiba, Bima, Msaada, Wasifu, Weka Pesa, Toa Pesa, Scan, au Zawadi. Nitakupeleka huko.',
      'wallet': 'Kufungua mkoba',
      'jobs': 'Kufungua soko la kazi',
      'savings': 'Kufungua akiba',
      'insurance': 'Kufungua bima',
      'support': 'Kufungua gumzo la msaada',
      'profile': 'Kufungua wasifu',
      'deposit': 'Kufungua skrini ya kuweka pesa',
      'withdraw': 'Kufungua skrini ya kutoa pesa',
      'scan': 'Kufungua scanner ya QR',
      'rewards': 'Kufungua duka la zawadi',
      'not_understood': 'Samahani, sikuelewi. Tafadhali sema tena, au sema msaada kwa chaguo.',
      'permission_granted': 'Ruhusa imetolewa. Asante.',
      'permission_denied': 'Ruhusa imekataliwa. Haiwezi kuendelea bila ufikiaji.',
    },
  };
  
  /// Initialize voice service with feminine Kenyan voice
  Future<bool> initialize({String language = 'en'}) async {
    _currentLanguage = language;
    
    // Initialize TTS with feminine voice
    if (language == 'en') {
      await _tts.setLanguage("en-KE"); // Kenyan English
    } else {
      await _tts.setLanguage("sw-KE"); // Kenyan Swahili
    }
    
    // FEMININE VOICE SETTINGS
    await _tts.setSpeechRate(0.45); // Slower for clarity
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.2); // Higher pitch for feminine voice
    
    // Try to select a female voice
    var voices = await _tts.getVoices;
    if (voices != null && voices.isNotEmpty) {
      var femaleVoice = voices.firstWhere(
        (voice) => 
          (voice['name'].toString().toLowerCase().contains('female') ||
           voice['name'].toString().toLowerCase().contains('woman') ||
           voice['gender']?.toString().toLowerCase() == 'female') &&
          (voice['locale']?.toString().contains('KE') == true ||
           voice['locale']?.toString().contains('ke') == true ||
           (language == 'sw' && voice['locale']?.toString().contains('sw') == true) ||
           (language == 'en' && voice['locale']?.toString().contains('en') == true)),
        orElse: () => voices.first,
      );
      
      if (femaleVoice != null) {
        await _tts.setVoice({
          "name": femaleVoice['name'],
          "locale": femaleVoice['locale'],
        });
      }
    }
    
    // Request microphone permission
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      _speechEnabled = await _speech.initialize(
        onError: (error) => print('Speech error: $error'),
        onStatus: (status) {
          if (status == 'done') {
            _isListening = false;
          }
        },
      );
      return _speechEnabled;
    }
    
    return false;
  }
  
  /// Speak text in current language
  Future<void> speak(String key, {String? customText}) async {
    final text = customText ?? _responses[_currentLanguage]![key] ?? key;
    await _tts.speak(text);
  }
  
  /// Request permission with voice prompts and handle voice response
  Future<PermissionStatus> requestPermissionWithVoice(
    Permission permission,
    BuildContext context, {
    required String permissionName,
  }) async {
    // Announce permission request
    if (permission == Permission.microphone) {
      await speak('permission_mic', customText: 
        _currentLanguage == 'en'
          ? 'Jasho needs microphone permission. Please say yes to allow, or no to deny.'
          : 'Jasho inahitaji ruhusa ya kipaza sauti. Tafadhali sema ndiyo kuruhusu, au hapana kukataa.'
      );
    } else if (permission == Permission.camera) {
      await speak('permission_camera', customText:
        _currentLanguage == 'en'
          ? 'Jasho needs camera permission. Please say yes to allow, or no to deny.'
          : 'Jasho inahitaji ruhusa ya kamera. Tafadhali sema ndiyo kuruhusu, au hapana kukataa.'
      );
    }
    
    // Listen for voice response
    bool userSaidYes = false;
    if (_speechEnabled) {
      await Future.delayed(const Duration(milliseconds: 500));
      _isListening = true;
      
      await _speech.listen(
        onResult: (result) {
          final words = result.recognizedWords.toLowerCase();
          final yesCommands = _commandMappings[_currentLanguage]!['yes']!;
          final noCommands = _commandMappings[_currentLanguage]!['no']!;
          
          for (var cmd in yesCommands) {
            if (words.contains(cmd)) {
              userSaidYes = true;
              break;
            }
          }
        },
        listenFor: const Duration(seconds: 5),
        pauseFor: const Duration(seconds: 2),
      );
      
      await Future.delayed(const Duration(seconds: 6));
      _isListening = false;
    }
    
    // Request permission
    final status = await permission.request();
    
    if (status.isGranted) {
      await speak('permission_granted');
    } else {
      await speak('permission_denied');
      
      // Show dialog to open settings
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                const SizedBox(width: 12),
                Text(
                  _currentLanguage == 'en' ? 'Permission Required' : 'Ruhusa Inahitajika',
                ),
              ],
            ),
            content: Text(
              _currentLanguage == 'en'
                ? 'Please enable $permissionName permission in your device settings.'
                : 'Tafadhali washa ruhusa ya $permissionName katika mipangilio ya kifaa chako.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(_currentLanguage == 'en' ? 'Cancel' : 'Sitisha'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await openAppSettings();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                ),
                child: Text(_currentLanguage == 'en' ? 'Open Settings' : 'Fungua Mipangilio'),
              ),
            ],
          ),
        );
      }
    }
    
    return status;
  }
  
  /// Listen for navigation commands
  Future<String?> listenForNavigationCommand() async {
    if (!_speechEnabled) return null;
    
    String? detectedCommand;
    _isListening = true;
    
    await _speech.listen(
      onResult: (result) {
        final words = result.recognizedWords.toLowerCase();
        
        // Check all command mappings
        for (var entry in _commandMappings[_currentLanguage]!.entries) {
          for (var keyword in entry.value) {
            if (words.contains(keyword)) {
              detectedCommand = entry.key;
              break;
            }
          }
          if (detectedCommand != null) break;
        }
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
    );
    
    await Future.delayed(const Duration(seconds: 11));
    _isListening = false;
    
    return detectedCommand;
  }
  
  /// Navigate based on voice command
  Future<void> navigateWithVoice(BuildContext context, String command) async {
    await speak(command);
    
    switch (command) {
      case 'wallet':
        Navigator.pushNamed(context, '/enhancedWallet');
        break;
      case 'jobs':
        Navigator.pushNamed(context, '/jobs');
        break;
      case 'savings':
        Navigator.pushNamed(context, '/savings');
        break;
      case 'insurance':
        Navigator.pushNamed(context, '/insurance');
        break;
      case 'support':
        Navigator.pushNamed(context, '/supportChat');
        break;
      case 'profile':
        Navigator.pushNamed(context, '/profileSettings');
        break;
      case 'deposit':
        Navigator.pushNamed(context, '/deposit');
        break;
      case 'withdraw':
        Navigator.pushNamed(context, '/withdraw');
        break;
      case 'scan':
        Navigator.pushNamed(context, '/qrScanner');
        break;
      case 'rewards':
        Navigator.pushNamed(context, '/rewards');
        break;
      case 'help':
        await speak('help');
        break;
      default:
        await speak('not_understood');
    }
  }
  
  /// Switch language
  Future<void> switchLanguage(String language) async {
    _currentLanguage = language;
    await initialize(language: language);
  }
  
  /// Check if currently listening
  bool get isListening => _isListening;
  
  /// Check if speech is enabled
  bool get isSpeechEnabled => _speechEnabled;
  
  /// Get current language
  String get currentLanguage => _currentLanguage;
  
  /// Clean up resources
  void dispose() {
    _speech.stop();
    _tts.stop();
  }
}

