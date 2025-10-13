import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import 'dart:async';

/// Voice-Controlled Permission System (Siri-like)
/// 
/// Allows users to grant/deny permissions using ONLY voice commands
/// Features:
/// - Always-on listening (wake word: "Jasho")
/// - Voice prompts for permissions
/// - Voice responses (Yes/No/Allow/Deny)
/// - Hands-free permission management
/// - Works like Siri - recognizes voice from distance
class VoicePermissionService {
  static final VoicePermissionService _instance = VoicePermissionService._internal();
  factory VoicePermissionService() => _instance;
  VoicePermissionService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;
  bool _isListening = false;
  
  // Pending permission request
  Permission? _pendingPermission;
  Function(bool)? _pendingCallback;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize speech recognition
    _isInitialized = await _speech.initialize(
      onError: (error) => print('Voice Permission Error: $error'),
      onStatus: (status) => print('Voice Permission Status: $status'),
    );

    // Initialize TTS with feminine Kenyan voice
    await _tts.setLanguage("en-KE");
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.2);

    var voices = await _tts.getVoices;
    if (voices != null && voices.isNotEmpty) {
      var femaleVoice = voices.firstWhere(
        (voice) =>
          (voice['name'].toString().toLowerCase().contains('female') ||
           voice['name'].toString().toLowerCase().contains('woman') ||
           voice['gender']?.toString().toLowerCase() == 'female') &&
          voice['locale']?.toString().contains('KE') == true,
        orElse: () => voices.first,
      );
      if (femaleVoice != null) {
        await _tts.setVoice({
          "name": femaleVoice['name'],
          "locale": femaleVoice['locale'],
        });
      }
    }

    print('✅ Voice Permission Service initialized');
  }

  Future<void> speak(String text) async {
    await _tts.speak(text);
  }

  /// Request permission using voice (Siri-style)
  /// 
  /// Example:
  /// ```dart
  /// final granted = await VoicePermissionService().requestWithVoice(
  ///   Permission.microphone,
  ///   prompt: "Can I access your microphone?",
  /// );
  /// ```
  Future<bool> requestWithVoice(
    Permission permission, {
    String? prompt,
    String? language = 'en',
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Check if already granted
    if (await permission.isGranted) {
      return true;
    }

    // Generate prompt
    final defaultPrompt = _getDefaultPrompt(permission, language ?? 'en');
    final finalPrompt = prompt ?? defaultPrompt;

    // Speak the prompt
    await speak(finalPrompt);
    await Future.delayed(const Duration(milliseconds: 500));
    await speak("Say 'yes' to allow, or 'no' to deny.");

    // Listen for voice response
    final response = await _listenForResponse(language ?? 'en');

    if (response) {
      // User said "yes" - request permission
      await speak("Thank you. Requesting permission now.");
      
      final status = await permission.request();
      
      if (status.isGranted) {
        await speak("Permission granted. You're all set!");
        return true;
      } else if (status.isDenied) {
        await speak("Permission denied. You can enable it later in settings.");
        return false;
      } else if (status.isPermanentlyDenied) {
        await speak("Permission permanently denied. Please enable it in device settings.");
        return false;
      }
    } else {
      // User said "no"
      await speak("Okay, permission denied. You can enable it later if needed.");
      return false;
    }

    return false;
  }

  /// Request camera permission with voice
  Future<bool> requestCameraWithVoice({String language = 'en'}) async {
    return await requestWithVoice(
      Permission.camera,
      prompt: language == 'sw' 
        ? "Je, naweza kutumia kamera yako?"
        : "Can I access your camera for facial recognition?",
      language: language,
    );
  }

  /// Request microphone permission with voice
  Future<bool> requestMicrophoneWithVoice({String language = 'en'}) async {
    // Special case: For first-time mic access, we need a button click
    // But after that, we can use voice for everything
    if (!await Permission.microphone.isGranted) {
      await speak(language == 'sw'
        ? "Tafadhali bonyeza kibonyezo kuruhusu maikrofoni kwa mara ya kwanza."
        : "Please tap the button to allow microphone for the first time.");
      
      // Wait for manual permission grant
      final status = await Permission.microphone.request();
      
      if (status.isGranted) {
        await speak(language == 'sw'
          ? "Asante! Maikrofoni imeanzishwa. Sasa unaweza kutumia sauti pekee."
          : "Thank you! Microphone enabled. You can now use voice only.");
        _isInitialized = await _speech.initialize();
        return true;
      } else {
        await speak(language == 'sw'
          ? "Maikrofoni haijatolewa ruhusa. Tafadhali ruhusu katika mipangilio."
          : "Microphone not granted. Please enable in settings.");
        return false;
      }
    }
    
    return true; // Already granted
  }

  /// Listen for yes/no response from user
  Future<bool> _listenForResponse(String language) async {
    if (!_isInitialized) return false;

    final completer = Completer<bool>();
    bool responseReceived = false;

    _isListening = true;

    await _speech.listen(
      onResult: (result) {
        if (result.finalResult && !responseReceived) {
          responseReceived = true;
          final words = result.recognizedWords.toLowerCase();
          
          // Check for positive responses
          final positiveWords = language == 'sw'
            ? ['ndiyo', 'ndio', 'sawa', 'ruhusu', 'allow', 'yes', 'okay']
            : ['yes', 'allow', 'okay', 'sure', 'grant', 'accept', 'enable'];
          
          final isPositive = positiveWords.any((word) => words.contains(word));
          
          completer.complete(isPositive);
        }
      },
      localeId: language == 'sw' ? 'sw_KE' : 'en_US',
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
    );

    // Timeout after 10 seconds
    return await completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        speak("No response heard. Permission denied.");
        return false;
      },
    );
  }

  /// Get default prompt for permission
  String _getDefaultPrompt(Permission permission, String language) {
    if (language == 'sw') {
      if (permission == Permission.camera) {
        return "Je, naweza kutumia kamera yako kwa utambuzi wa uso?";
      } else if (permission == Permission.microphone) {
        return "Je, naweza kutumia maikrofoni yako kwa sauti?";
      } else if (permission == Permission.location) {
        return "Je, naweza kupata mahali ulipo?";
      } else if (permission == Permission.storage) {
        return "Je, naweza kufikia hifadhi yako?";
      } else {
        return "Je, naweza kupata ruhusa hii?";
      }
    } else {
      if (permission == Permission.camera) {
        return "Can I access your camera for facial recognition?";
      } else if (permission == Permission.microphone) {
        return "Can I access your microphone for voice commands?";
      } else if (permission == Permission.location) {
        return "Can I access your location?";
      } else if (permission == Permission.storage) {
        return "Can I access your device storage?";
      } else {
        return "Can I access this permission?";
      }
    }
  }

  /// Start always-on listening (wake word: "Jasho")
  Future<void> startAlwaysListening({
    required BuildContext context,
    String language = 'en',
  }) async {
    if (!_isInitialized || !await Permission.microphone.isGranted) {
      print('❌ Cannot start always-on listening: not initialized or no mic permission');
      return;
    }

    print('🎤 Starting always-on listening for wake word "Jasho"...');

    // Continuous listening for wake word
    _listenForWakeWord(context, language);
  }

  Future<void> _listenForWakeWord(BuildContext context, String language) async {
    if (!_isInitialized) return;

    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          final words = result.recognizedWords.toLowerCase();
          
          // Check for wake word "Jasho"
          if (words.contains('jasho') || words.contains('jasho app')) {
            _handleWakeWord(context, language);
          }
        }
      },
      localeId: language == 'sw' ? 'sw_KE' : 'en_US',
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 1),
      onSoundLevelChange: (level) {
        // Can be used for voice activity detection
      },
    );

    // Restart listening after it stops (always-on)
    Future.delayed(const Duration(seconds: 1), () {
      if (_isInitialized) {
        _listenForWakeWord(context, language);
      }
    });
  }

  void _handleWakeWord(BuildContext context, String language) {
    print('🎤 Wake word detected!');
    speak(language == 'sw' ? 'Ndiyo, nasikia' : 'Yes, I\'m listening');
    
    // Can trigger any action here
    // For now, just acknowledge
  }

  /// Stop listening
  void stopListening() {
    _speech.stop();
    _isListening = false;
  }

  /// Check if listening
  bool get isListening => _isListening;
}

/// Voice Permission Dialog Widget
/// 
/// Shows a dialog that uses voice for permission request
class VoicePermissionDialog extends StatefulWidget {
  final Permission permission;
  final String? prompt;
  final String language;

  const VoicePermissionDialog({
    super.key,
    required this.permission,
    this.prompt,
    this.language = 'en',
  });

  @override
  State<VoicePermissionDialog> createState() => _VoicePermissionDialogState();
}

class _VoicePermissionDialogState extends State<VoicePermissionDialog>
    with SingleTickerProviderStateMixin {
  bool _isListening = false;
  late AnimationController _animationController;
  final VoicePermissionService _voiceService = VoicePermissionService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    
    _requestPermission();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _requestPermission() async {
    setState(() => _isListening = true);
    
    final granted = await _voiceService.requestWithVoice(
      widget.permission,
      prompt: widget.prompt,
      language: widget.language,
    );
    
    if (mounted) {
      Navigator.of(context).pop(granted);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated microphone icon
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green.withOpacity(0.1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(
                          0.3 + (_animationController.value * 0.3),
                        ),
                        blurRadius: 20 + (_animationController.value * 20),
                        spreadRadius: 5 + (_animationController.value * 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.mic,
                    size: 50,
                    color: Colors.green,
                  ),
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            Text(
              widget.language == 'sw'
                ? 'Nisikiliza...'
                : 'Listening...',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 12),
            
            Text(
              widget.language == 'sw'
                ? 'Sema "Ndiyo" kuruhusu au "Hapana" kukataa'
                : 'Say "Yes" to allow or "No" to deny',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            const CircularProgressIndicator(
              color: Colors.green,
            ),
          ],
        ),
      ),
    );
  }
}

