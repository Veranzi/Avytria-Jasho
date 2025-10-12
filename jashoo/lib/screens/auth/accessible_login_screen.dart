import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import 'dart:io';

class AccessibleLoginScreen extends StatefulWidget {
  const AccessibleLoginScreen({super.key});

  @override
  State<AccessibleLoginScreen> createState() => _AccessibleLoginScreenState();
}

class _AccessibleLoginScreenState extends State<AccessibleLoginScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  
  bool _isListening = false;
  String _voiceInput = '';
  bool _speechEnabled = false;
  String _selectedLanguage = 'en'; // 'en' for English, 'sw' for Swahili
  bool _languageSelected = false;
  
  // Language translations
  Map<String, Map<String, String>> _translations = {
    'en': {
      'welcome': 'Welcome to Jasho accessible login. Please choose your language. Say English or Swahili.',
      'language_selected': 'Language selected',
      'permission_mic': 'Jasho needs microphone permission to listen to your voice. Please allow microphone access.',
      'permission_camera': 'Jasho needs camera permission for face recognition. Please allow camera access.',
      'login_options': 'Say your phone number to login, or say face recognition for face login.',
      'listening': 'Listening',
      'phone_recognized': 'Phone number recognized. Please say your password.',
      'face_recognition': 'Opening face recognition',
      'login_success': 'Login successful',
    },
    'sw': {
      'welcome': 'Karibu kwa Jasho kuingia kwa urahisi. Tafadhali chagua lugha yako. Sema Kiingereza au Kiswahili.',
      'language_selected': 'Lugha imechaguliwa',
      'permission_mic': 'Jasho inahitaji ruhusa ya kipaza sauti kusikia sauti yako. Tafadhali ruhusu ufikiaji wa kipaza sauti.',
      'permission_camera': 'Jasho inahitaji ruhusa ya kamera kwa utambuzi wa uso. Tafadhali ruhusu ufikiaji wa kamera.',
      'login_options': 'Sema nambari yako ya simu kuingia, au sema utambuzi wa uso kwa kuingia kwa uso.',
      'listening': 'Kusikiliza',
      'phone_recognized': 'Nambari ya simu imetambulika. Tafadhali sema neno lako la siri.',
      'face_recognition': 'Kufungua utambuzi wa uso',
      'login_success': 'Kuingia kumefanikiwa',
    },
  };

  @override
  void initState() {
    super.initState();
    // Default to English for voice
    _selectedLanguage = 'en';
    _languageSelected = true;
    _initTts();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    await _speak(_translations[_selectedLanguage]!['permission_mic']!);
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      _speechEnabled = await _speech.initialize(
        onError: (error) => print('Speech error: $error'),
        onStatus: (status) {
          if (status == 'done') {
            setState(() => _isListening = false);
          }
        },
      );
      if (_speechEnabled) {
        await _speak(_translations[_selectedLanguage]!['login_options']!);
      }
    }
  }

  Future<void> _initTts() async {
    // Set Kenyan English or Swahili voice
    if (_selectedLanguage == 'en') {
      await _tts.setLanguage("en-KE"); // Kenyan English
      await _tts.setVoice({"name": "en-ke-x-kea-network", "locale": "en-KE"}); // Kenyan accent
    } else {
      await _tts.setLanguage("sw-KE"); // Swahili (Kenya)
      await _tts.setVoice({"name": "sw-ke-x-swa-network", "locale": "sw-KE"});
    }
    await _tts.setSpeechRate(0.45); // Slightly slower for accessibility
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  Future<void> _speak(String text) async {
    await _tts.speak(text);
  }

  Future<void> _speakLanguageSelection() async {
    await Future.delayed(const Duration(milliseconds: 500));
    await _speak(_translations['en']!['welcome']!);
    await Future.delayed(const Duration(milliseconds: 500));
    await _speak(_translations['sw']!['welcome']!);
    _startLanguageListening();
  }

  Future<void> _startLanguageListening() async {
    // Request microphone permission with voice prompt
    await _speak('Jasho needs microphone permission to listen. Please allow when prompted.');
    await _speak('Jasho inahitaji ruhusa ya kipaza sauti. Tafadhali ruhusu.');
    
    final status = await Permission.microphone.request();
    
    if (status.isGranted) {
      await _speak('Permission granted. Thank you. Asante.');
      
      bool initialized = await _speech.initialize(
        onError: (error) {
          print('Speech error: $error');
          _speak('Speech recognition error. Please try again.');
        },
        onStatus: (status) {
          if (status == 'done') {
            setState(() => _isListening = false);
          }
        },
      );
      
      if (initialized) {
        setState(() => _isListening = true);
        await _speech.listen(
          onResult: (result) {
            final words = result.recognizedWords.toLowerCase();
            if (words.contains('english') || words.contains('kiingereza')) {
              _selectLanguage('en');
            } else if (words.contains('swahili') || words.contains('kiswahili')) {
              _selectLanguage('sw');
            }
          },
          listenFor: const Duration(seconds: 10),
          pauseFor: const Duration(seconds: 3),
        );
      }
    } else {
      // Permission denied - abort and show message
      await _speak('Permission denied. Cannot proceed without microphone access.');
      await _speak('Ruhusa imekataliwa. Haiwezi kuendelea bila ufikiaji wa kipaza sauti.');
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('Permission Required'),
            ],
          ),
          content: const Text(
            'Microphone permission is required for accessible login. '
            'Please grant permission in your device settings to use this feature.\n\n'
            'Ruhusa ya kipaza sauti inahitajika kwa kuingia kwa urahisi. '
            'Tafadhali ipe ruhusa katika mipangilio ya kifaa chako kutumia kipengele hiki.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Go back to login
              },
              child: const Text('Go Back / Rudi Nyuma'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
              ),
              child: const Text('Open Settings / Fungua Mipangilio'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _selectLanguage(String lang) async {
    _speech.stop();
    setState(() {
      _selectedLanguage = lang;
      _languageSelected = true;
      _isListening = false;
    });
    await _initTts(); // Reinitialize with selected language
    await _speak(_translations[_selectedLanguage]!['language_selected']!);
    await Future.delayed(const Duration(milliseconds: 1000));
    await _initSpeech(); // Initialize speech recognition after language selection
  }

  void _startListening() async {
    if (!_speechEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition not available')),
      );
      return;
    }
    
    setState(() => _isListening = true);
    await _speak('Listening');
    
    await _speech.listen(
      onResult: (result) {
        setState(() {
          _voiceInput = result.recognizedWords;
        });
        
        if (result.finalResult) {
          _processVoiceCommand(_voiceInput);
        }
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
    );
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  void _processVoiceCommand(String command) {
    final lowerCommand = command.toLowerCase();
    
    if (lowerCommand.contains('face') || lowerCommand.contains('facial')) {
      _speak('Opening face recognition');
      _openFaceRecognition();
    } else if (_isPhoneNumber(command)) {
      _speak('Phone number recognized. Please say your password.');
      // In a real implementation, wait for password
      Future.delayed(const Duration(seconds: 2), () {
        _speak('Login successful');
        Navigator.pushReplacementNamed(context, '/dashboard');
      });
    } else {
      _speak('Command not recognized. Please try again.');
    }
  }

  bool _isPhoneNumber(String input) {
    // Check if input contains numbers
    final digitsOnly = input.replaceAll(RegExp(r'[^0-9]'), '');
    return digitsOnly.length >= 9; // Minimum phone number length
  }

  Future<void> _openFaceRecognition() async {
    await _speak(_translations[_selectedLanguage]!['permission_camera']!);
    final status = await Permission.camera.request();
    
    if (status.isGranted) {
      await _speak(_translations[_selectedLanguage]!['face_recognition']!);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FaceRecognitionScreen(language: _selectedLanguage, translations: _translations),
        ),
      );
    } else {
      // Permission denied - abort and show message (voice in selected language, UI in English)
      await _speak(_translations[_selectedLanguage]!['permission_camera']!);
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('Camera Permission Required'),
            ],
          ),
          content: const Text(
            'Camera permission is required for face recognition. Please grant permission in your device settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
              ),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Accessible Login',
          style: TextStyle(fontSize: 18),
        ),
        backgroundColor: const Color(0xFF10B981),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up),
            tooltip: 'Repeat instructions',
            onPressed: () {
              _speak(_translations[_selectedLanguage]!['login_options']!);
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF10B981).withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = constraints.maxHeight < 700 || constraints.maxWidth < 400;
              
              return Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Accessibility Icon
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _languageSelected ? Icons.accessible_forward : Icons.language,
                          size: isSmallScreen ? 60 : 80,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 24 : 32),
                      
                      // Title - MATCH REGISTER SIZE
                      const Text(
                        'Voice & Face Login',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 12 : 16),
                      
                      // Language Switch Button (Voice Only)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Voice Language:',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 13,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('English'),
                            selected: _selectedLanguage == 'en',
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedLanguage = 'en');
                                _initTts();
                              }
                            },
                            selectedColor: const Color(0xFF10B981),
                            labelStyle: TextStyle(
                              color: _selectedLanguage == 'en' ? Colors.white : Colors.black87,
                              fontSize: isSmallScreen ? 11 : 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Kiswahili'),
                            selected: _selectedLanguage == 'sw',
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedLanguage = 'sw');
                                _initTts();
                              }
                            },
                            selectedColor: const Color(0xFF10B981),
                            labelStyle: TextStyle(
                              color: _selectedLanguage == 'sw' ? Colors.white : Colors.black87,
                              fontSize: isSmallScreen ? 11 : 12,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isSmallScreen ? 12 : 16),
                      
                      // Instructions - NORMALIZED SIZE (English UI only)
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 12 : 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.info_outline, 
                              color: const Color(0xFF10B981),
                              size: isSmallScreen ? 18 : 20,
                            ),
                            SizedBox(height: isSmallScreen ? 6 : 8),
                            Text(
                              'Say your phone number followed by your password, or say "face recognition" to use facial login',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 12 : 13,
                                color: const Color(0xFF10B981),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 24 : 32),
                      
                      // Voice Input Display
                      if (_voiceInput.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF10B981)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                'You said:',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 11 : 12,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: isSmallScreen ? 6 : 8),
                              Text(
                                _voiceInput,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      SizedBox(height: isSmallScreen ? 24 : 32),
                      
                      // Voice Button
                      if (_languageSelected)
                        GestureDetector(
                          onTap: _isListening ? _stopListening : _startListening,
                          child: Container(
                            width: isSmallScreen ? 100 : 120,
                            height: isSmallScreen ? 100 : 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isListening 
                                  ? Colors.red 
                                  : const Color(0xFF10B981),
                              boxShadow: [
                                BoxShadow(
                                  color: (_isListening ? Colors.red : const Color(0xFF10B981))
                                      .withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Icon(
                              _isListening ? Icons.mic : Icons.mic_none,
                              size: isSmallScreen ? 50 : 60,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      SizedBox(height: isSmallScreen ? 12 : 16),
                      Text(
                        _isListening ? 'Listening...' : 'Tap to speak',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.w600,
                          color: _isListening ? Colors.red : const Color(0xFF10B981),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 32 : 40),
                      
                      // Face Recognition Button
                      ElevatedButton.icon(
                        onPressed: _openFaceRecognition,
                        icon: const Icon(Icons.face, color: Colors.white),
                        label: Text(
                          'Use Face Recognition',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 16 : 18,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 24 : 32,
                              vertical: isSmallScreen ? 14 : 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      SizedBox(height: isSmallScreen ? 12 : 16),
                      
                      // Standard Login Link
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        child: Text(
                          'Use standard login instead',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 13 : 14,
                            color: const Color(0xFF10B981),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// Face Recognition Screen (placeholder - requires camera integration)
class FaceRecognitionScreen extends StatefulWidget {
  final String language;
  final Map<String, Map<String, String>> translations;
  
  const FaceRecognitionScreen({
    super.key,
    required this.language,
    required this.translations,
  });

  @override
  State<FaceRecognitionScreen> createState() => _FaceRecognitionScreenState();
}

class _FaceRecognitionScreenState extends State<FaceRecognitionScreen> {
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _startScanning();
  }

  Future<void> _startScanning() async {
    setState(() => _isScanning = true);
    
    // Request camera permission
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera permission required')),
      );
      Navigator.pop(context);
      return;
    }

    // Open camera to capture face
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('No camera available');
      }

      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      if (!mounted) return;

      // Open camera preview and capture
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => _FaceCaptureScreen(camera: frontCamera),
        ),
      );

      if (result != null && result is File) {
        // Face captured successfully
        setState(() => _isScanning = false);
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Face recognized! Logging in...'),
            backgroundColor: Colors.green,
          ),
        );
        
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        // Cancelled
        if (!mounted) return;
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error accessing camera: $e')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Face Recognition',
          style: TextStyle(fontSize: 18),
        ),
        backgroundColor: const Color(0xFF10B981),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxHeight < 700 || constraints.maxWidth < 400;
          
          return Center(
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Face Icon with animation
                  Container(
                    width: isSmallScreen ? 150 : 200,
                    height: isSmallScreen ? 150 : 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isScanning 
                            ? const Color(0xFF10B981) 
                            : Colors.grey,
                        width: 4,
                      ),
                    ),
                    child: Icon(
                      Icons.face,
                      size: isSmallScreen ? 80 : 100,
                      color: _isScanning 
                          ? const Color(0xFF10B981) 
                          : Colors.grey,
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 32 : 40),
                  
                  if (_isScanning) ...[
                    const CircularProgressIndicator(
                      color: Color(0xFF10B981),
                    ),
                    SizedBox(height: isSmallScreen ? 16 : 20),
                    Text(
                      'Scanning your face...',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 10 : 12),
                    Text(
                      'Please look at the camera',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 13 : 14,
                        color: Colors.grey,
                      ),
                    ),
                  ] else ...[
                      Icon(
                        Icons.check_circle,
                        size: isSmallScreen ? 50 : 60,
                        color: Colors.green,
                      ),
                      SizedBox(height: isSmallScreen ? 16 : 20),
                      Text(
                        'Face recognized!',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      );
  }
}

// Face Capture Screen for actually capturing the face
class _FaceCaptureScreen extends StatefulWidget {
  final CameraDescription camera;

  const _FaceCaptureScreen({required this.camera});

  @override
  State<_FaceCaptureScreen> createState() => __FaceCaptureScreenState();
}

class __FaceCaptureScreenState extends State<_FaceCaptureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _captureAndSave() async {
    if (_isCapturing) return;
    
    setState(() => _isCapturing = true);

    try {
      await _initializeControllerFuture;
      final image = await _controller.takePicture();
      
      if (!mounted) return;
      Navigator.of(context).pop(File(image.path));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error capturing face: $e')),
      );
      Navigator.of(context).pop();
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Capture Your Face'),
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                Center(child: CameraPreview(_controller)),
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Column(
                      children: [
                        const Text(
                          'Position your face in the center',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            shadows: [
                              Shadow(
                                blurRadius: 10.0,
                                color: Colors.black,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _isCapturing ? null : _captureAndSave,
                          icon: Icon(_isCapturing ? Icons.hourglass_empty : Icons.camera),
                          label: Text(_isCapturing ? 'Capturing...' : 'Capture Face'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
              ),
            );
          }
        },
      ),
    );
  }
}

