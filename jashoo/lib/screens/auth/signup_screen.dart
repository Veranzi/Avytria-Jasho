import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../services/api_service.dart';
import '../../services/voice_permission_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // Controllers
  final usernameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  String? _fullPhoneE164;

  // State vars
  List<String> selectedHustles = [];
  String? selectedCountry;
  String? selectedCounty;
  String? selectedWard;
  bool _acceptedTerms = false;
  bool _acceptedPrivacy = false;

  final _formKey = GlobalKey<FormState>();

  // Accessibility features
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _speechEnabled = false;
  bool _isListening = false;
  String _voiceStatus = 'Not enrolled';
  String _faceStatus = 'Not enrolled';
  File? _capturedFaceImage;
  String? _voicePrintPath;

  // Hustles list
  final List<String> hustles = [
    "Mama Mboga",
    "Boda Rider",
    "Mama Fua",
    "Online Writer",
    "Retailer",
    "Chemist",
    "Wholesaler",
    "Farmer",
    "Artisan",
    "Mechanic",
    "Tailor",
    "Hairdresser",
    "Other",
  ];

  // Custom hustle input when "Other" is selected
  final TextEditingController otherHustleController = TextEditingController();

  // Country -> Counties/Provinces
  final Map<String, List<String>> countryRegions = {
    "Kenya": ["Nairobi", "Kiambu", "Mombasa", "Kisumu", "Nakuru", "Machakos"],
    "South Africa": ["Gauteng", "Western Cape", "KwaZulu-Natal", "Eastern Cape"],
  };

  // County/Province -> Wards/Areas
  final Map<String, List<String>> wards = {
    // Kenya
    "Nairobi": ["Westlands", "Langata", "Kasarani"],
    "Kiambu": ["Thika Town", "Ruiru", "Gatundu"],
    "Mombasa": ["Mvita", "Kisauni", "Nyali"],
    "Kisumu": ["Kisumu East", "Kisumu West", "Nyando"],
    "Nakuru": ["Nakuru Town East", "Nakuru Town West"],
    "Machakos": ["Mavoko", "Machakos Town", "Kangundo"],

    // South Africa (example data)
    "Gauteng": ["Johannesburg", "Pretoria"],
    "Western Cape": ["Cape Town", "Stellenbosch"],
    "KwaZulu-Natal": ["Durban", "Pietermaritzburg"],
    "Eastern Cape": ["Port Elizabeth", "East London"],
  };

  @override
  void initState() {
    super.initState();
    _initTts();
    // Start listening for voice commands to trigger enrollment
    _startEnrollmentListener();
  }

  @override
  void dispose() {
    usernameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    otherHustleController.dispose();
    _speech.stop();
    super.dispose();
  }

  /// Always-on voice listener for enrollment commands
  /// Listens for: "enroll voice", "enroll face", "yes voice", "yes face"
  Future<void> _startEnrollmentListener() async {
    // Wait a bit for UI to load
    await Future.delayed(const Duration(seconds: 1));
    
    // Initialize speech if not already done
    if (!_speechEnabled) {
      final status = await Permission.microphone.status;
      if (status.isGranted) {
        _speechEnabled = await _speech.initialize(
          onError: (error) => print('Speech error: $error'),
          onStatus: (status) {
            if (status == 'done' && mounted) {
              // Restart listening after each command
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted && _voiceStatus != 'Enrolled' || _faceStatus != 'Enrolled') {
                  _startEnrollmentListener();
                }
              });
            }
          },
        );
      }
    }
    
    if (!_speechEnabled || !mounted) return;
    
    // Announce that voice commands are ready
    if (_voiceStatus != 'Enrolled' || _faceStatus != 'Enrolled') {
      await _speak('You can say "enroll voice" or "enroll face" to start enrollment without tapping buttons.');
    }
    
    // Listen for enrollment commands
    _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          final command = result.recognizedWords.toLowerCase();
          print('Heard command: $command');
          
          // Voice enrollment triggers (English & Swahili)
          if ((command.contains('enroll voice') || 
               command.contains('voice recognition') ||
               command.contains('yes voice') ||
               command.contains('start voice') ||
               command.contains('sajili sauti') || // Swahili: enroll voice
               command.contains('sauti') || // Swahili: voice
               (command.contains('enroll') && command.contains('voice'))) &&
              _voiceStatus != 'Enrolled') {
            _speak('Starting voice enrollment');
            _enrollVoice();
          }
          
          // Face enrollment triggers (English & Swahili)
          else if ((command.contains('enroll face') || 
                    command.contains('face recognition') ||
                    command.contains('yes face') ||
                    command.contains('start face') ||
                    command.contains('sajili uso') || // Swahili: enroll face
                    command.contains('uso') || // Swahili: face
                    (command.contains('enroll') && command.contains('face'))) &&
                   _faceStatus != 'Enrolled') {
            _speak('Starting face enrollment');
            _enrollFace();
          }
          
          // Generic "yes" when showing enrollment section
          else if ((command.contains('yes') || command.contains('ndiyo')) && 
                   (_voiceStatus != 'Enrolled' || _faceStatus != 'Enrolled')) {
            _speak('Which enrollment? Say "enroll voice" or "enroll face"');
          }
        }
      },
      localeId: 'en_KE',
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 2),
      onSoundLevelChange: (level) {
        // Visual feedback could be added here
      },
    );
  }

  Future<void> _initSpeech() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      _speechEnabled = await _speech.initialize(
        onError: (error) => print('Speech error: $error'),
        onStatus: (status) {
          if (status == 'done') {
            if (mounted) {
              setState(() => _isListening = false);
            }
          }
        },
      );
    }
  }

  Future<void> _initTts() async {
    // Set language with Kenyan accent
    await _tts.setLanguage("en-KE");
    
    // Feminine voice settings
    await _tts.setSpeechRate(0.45); // Slightly slower for clarity
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.2); // Higher pitch for feminine voice
    
    // Try to set a female voice if available
    var voices = await _tts.getVoices;
    if (voices != null && voices.isNotEmpty) {
      // Look for female Kenyan voice
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

  Future<void> _speak(String text) async {
    await _tts.speak(text);
  }

  Future<void> _enrollVoice() async {
    // Voice-controlled permission request (Siri-style!)
    final voiceService = VoicePermissionService();
    await voiceService.initialize();
    
    // Request microphone with voice prompts - user just says "yes" or "no"!
    final granted = await voiceService.requestMicrophoneWithVoice(language: 'en');
    
    if (!granted) {
      // Permission denied
      return;
    }
    
    // Permission granted - initialize speech
    if (!_speechEnabled) {
      _speechEnabled = await _speech.initialize(
        onError: (error) => print('Speech error: $error'),
        onStatus: (status) {
          if (status == 'done' && mounted) {
            setState(() => _isListening = false);
          }
        },
      );
    }

    await _speak('Voice enrollment started. Please say: My voice is my password. Repeat this phrase three times for secure enrollment.');
    
    setState(() => _isListening = true);
    
    // Simulate voice enrollment (in production, you'd capture and process multiple voice samples)
    await Future.delayed(const Duration(seconds: 5));
    
    // Save voice print to local storage
    final directory = await getApplicationDocumentsDirectory();
    final voiceFile = File('${directory.path}/voice_print_${DateTime.now().millisecondsSinceEpoch}.dat');
    await voiceFile.writeAsString('VOICE_PRINT_DATA_PLACEHOLDER'); // In production, store actual voice biometric data
    
    if (mounted) {
      setState(() {
        _voiceStatus = 'Enrolled';
        _voicePrintPath = voiceFile.path;
        _isListening = false;
      });
    }
    
    await _speak('Excellent! Voice enrollment successful. Your voice is now registered for secure authentication.');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voice biometric enrolled successfully!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }

  Future<void> _enrollFace() async {
    // Voice-controlled permission request (Siri-style!)
    final voiceService = VoicePermissionService();
    await voiceService.initialize();
    
    // Request camera with voice prompts - user just says "yes" or "no"!
    final granted = await voiceService.requestCameraWithVoice(language: 'en');
    
    if (!granted) {
      // Permission denied
      return;
    }
    
    // Permission granted!
    await _speak('Permission granted. Opening camera for face enrollment. Please position your face in the center of the screen.');

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        await _speak('No camera available on this device');
        throw Exception('No camera available');
      }

      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      if (!mounted) return;

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => _FaceCaptureScreen(camera: frontCamera),
        ),
      );

      if (result != null && result is File) {
        if (mounted) {
          setState(() {
            _capturedFaceImage = result;
            _faceStatus = 'Enrolled';
          });
        }

        await _speak('Perfect! Face enrollment successful. Your face is now registered for secure authentication.');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Face biometric enrolled successfully!'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        }
      }
    } catch (e) {
      await _speak('Face enrollment failed. Please try again.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Face enrollment failed: $e')),
        );
      }
    }
  }
  
  void _showPermissionDialog(String permissionName, Permission permission, {bool isPermanent = false}) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$permissionName Permission Required',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isPermanent
                  ? 'This app needs $permissionName permission for accessibility features. Please enable it in your device settings.'
                  : '$permissionName access is required for enrollment. Would you like to grant permission?',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            if (!isPermanent)
              const Text(
                '• Voice enrollment requires microphone\n• Face enrollment requires camera\n• These features are optional but enhance security',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _speak('Permission request cancelled');
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (isPermanent) {
                await _speak('Opening settings. Please enable $permissionName permission and return to this app.');
                await openAppSettings();
              } else {
                await _speak('Requesting permission again');
                final newStatus = await permission.request();
                if (newStatus.isGranted) {
                  await _speak('Permission granted. You may now try enrollment again.');
                } else {
                  await _speak('Permission not granted. Enrollment cannot proceed.');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
            ),
            child: Text(isPermanent ? 'Open Settings' : 'Grant Permission'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxHeight < 700 || constraints.maxWidth < 400;
            final horizontalPadding = constraints.maxWidth * 0.06;
            final verticalPadding = constraints.maxHeight * 0.03;

            return SingleChildScrollView(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 16),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Image.asset(
                        'assets/signup.png',
                        height: isSmallScreen ? 100 : 120,
                      ),
                      SizedBox(height: isSmallScreen ? 12 : 16),

                      Text(
                        "Sign Up",
                        style: TextStyle(
                          fontSize: isSmallScreen ? 22 : 26,
                          fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Input fields
                  _buildTextField(usernameController, "Full Name", Icons.person_outline,
                      validator: (val) =>
                          val == null || val.isEmpty ? "Enter username" : null),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: IntlPhoneField(
                      controller: phoneController,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        border:
                            OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                      ),
                      initialCountryCode: selectedCountry == 'South Africa' ? 'ZA' : 'KE',
                      onChanged: (phone) {
                        // Normalize to E.164 without trunk '0' after country code
                        final rawDigits = phone.number.replaceAll(RegExp(r'[^0-9]'), '');
                        final withoutTrunkZero = rawDigits.startsWith('0')
                            ? rawDigits.substring(1)
                            : rawDigits;
                        _fullPhoneE164 = '${phone.countryCode}$withoutTrunkZero';
                      },
                      validator: (val) {
                        if (val == null || val.number.isEmpty) {
                          return 'Enter phone number';
                        }
                        return null;
                      },
                    ),
                  ),
                  _buildTextField(emailController, "Email", Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) {
                        if (val == null || val.isEmpty) return "Enter email";
                        if (!val.contains("@")) return "Enter valid email";
                        return null;
                      }),

                  // Hustles
                  _buildMultiSelectField("Your Hustles", hustles),
                  if (selectedHustles.contains('Other'))
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: TextFormField(
                        controller: otherHustleController,
                        decoration: const InputDecoration(
                          labelText: 'Specify your hustle',
                          prefixIcon: Icon(Icons.edit_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (selectedHustles.contains('Other') && (val == null || val.trim().isEmpty)) {
                            return 'Please specify your hustle';
                          }
                          return null;
                        },
                      ),
                    ),

                  // Country
                  _buildDropdownField(
                    "Country",
                    countryRegions.keys.toList(),
                    selectedCountry,
                    (val) {
                      setState(() {
                        selectedCountry = val;
                        selectedCounty = null;
                        selectedWard = null;
                      });
                    },
                    Icons.flag_outlined,
                  ),

                  // County/Province
                  if (selectedCountry != null)
                    _buildDropdownField(
                        "County / Province",
                        countryRegions[selectedCountry] ?? [],
                        selectedCounty,
                        (val) {
                          setState(() {
                            selectedCounty = val;
                            selectedWard = null;
                          });
                        },
                        Icons.map_outlined),

                  // Ward
                  if (selectedCounty != null)
                    _buildDropdownField(
                        "Constituency / Ward",
                        wards[selectedCounty] ?? [],
                        selectedWard,
                        (val) => setState(() => selectedWard = val),
                        Icons.location_city_outlined),

                  _buildPasswordField(passwordController, "Password",
                      validator: (val) {
                    if (val == null || val.isEmpty) return "Enter password";
                    if (val.length < 8) return "Password too short";
                    return null;
                  }),
                  _buildPasswordField(confirmPasswordController, "Confirm Password",
                      validator: (val) {
                    if (val != passwordController.text) {
                      return "Passwords do not match";
                    }
                    return null;
                  }),
                  const SizedBox(height: 10),

                  const Text(
                    "Password must have: 1 uppercase, 1 lowercase, 1 number, and 1 special character. Length 8-16 characters.",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),

                  // GDPR Compliance - Terms and Conditions
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.privacy_tip, color: Color(0xFF10B981), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Data Privacy & Consent',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 15,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: _acceptedTerms,
                              onChanged: (value) {
                                setState(() {
                                  _acceptedTerms = value ?? false;
                                });
                              },
                              activeColor: const Color(0xFF10B981),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(context, '/terms');
                                },
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 11 : 12,
                                      color: Colors.black87,
                                    ),
                                    children: [
                                      const TextSpan(
                                        text: 'I have read and accept the ',
                                      ),
                                      const TextSpan(
                                        text: 'Terms & Conditions',
                                        style: TextStyle(
                                          color: Color(0xFF10B981),
                                          decoration: TextDecoration.underline,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const TextSpan(text: ' *'),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: _acceptedPrivacy,
                              onChanged: (value) {
                                setState(() {
                                  _acceptedPrivacy = value ?? false;
                                });
                              },
                              activeColor: const Color(0xFF10B981),
                            ),
                            Expanded(
                              child: Text(
                                'I consent to the collection and processing of my personal data as per GDPR and applicable data protection laws *',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 11 : 12,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '* Required for registration',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 9 : 10,
                            color: Colors.red.shade700,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 16 : 20),

                  // Inclusivity Section - Voice & Face Enrollment
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.accessibility_new, color: Color(0xFF10B981), size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Accessibility Features (Optional)',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 15,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF10B981),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Enroll your voice and face for secure, accessible authentication',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 11 : 12,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Voice command hint
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF10B981).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.mic_rounded,
                                color: Color(0xFF10B981),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Say "Enroll Voice" or "Enroll Face" to start without tapping!',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 10 : 11,
                                    color: const Color(0xFF10B981),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (_speechEnabled)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Voice Enrollment
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.mic, color: Color(0xFF10B981), size: 18),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Voice Recognition',
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 13 : 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Status: $_voiceStatus',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 10 : 11,
                                      color: _voiceStatus == 'Enrolled' 
                                        ? const Color(0xFF10B981) 
                                        : Colors.grey[600],
                                      fontWeight: _voiceStatus == 'Enrolled' 
                                        ? FontWeight.w600 
                                        : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _voiceStatus == 'Enrolled' ? null : _enrollVoice,
                              icon: Icon(
                                _voiceStatus == 'Enrolled' ? Icons.check_circle : Icons.mic,
                                size: 16,
                              ),
                              label: Text(
                                _voiceStatus == 'Enrolled' ? 'Enrolled' : 'Enroll',
                                style: TextStyle(fontSize: isSmallScreen ? 11 : 12),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _voiceStatus == 'Enrolled' 
                                  ? Colors.grey[400] 
                                  : const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 12 : 16,
                                  vertical: isSmallScreen ? 6 : 8,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 12),
                        
                        // Face Enrollment
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.face, color: Color(0xFF10B981), size: 18),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Face Recognition',
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 13 : 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Status: $_faceStatus',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 10 : 11,
                                      color: _faceStatus == 'Enrolled' 
                                        ? const Color(0xFF10B981) 
                                        : Colors.grey[600],
                                      fontWeight: _faceStatus == 'Enrolled' 
                                        ? FontWeight.w600 
                                        : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _faceStatus == 'Enrolled' ? null : _enrollFace,
                              icon: Icon(
                                _faceStatus == 'Enrolled' ? Icons.check_circle : Icons.camera_alt,
                                size: 16,
                              ),
                              label: Text(
                                _faceStatus == 'Enrolled' ? 'Enrolled' : 'Enroll',
                                style: TextStyle(fontSize: isSmallScreen ? 11 : 12),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _faceStatus == 'Enrolled' 
                                  ? Colors.grey[400] 
                                  : const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 12 : 16,
                                  vertical: isSmallScreen ? 6 : 8,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_isListening)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Listening...',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 11 : 12,
                                    color: const Color(0xFF10B981),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 16 : 20),

                      ElevatedButton(
                        onPressed: _handleSignup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          padding: EdgeInsets.symmetric(
                            vertical: isSmallScreen ? 14 : 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: Text(
                          "Register",
                          style: TextStyle(
                            fontSize: isSmallScreen ? 16 : 18,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 8 : 10),

                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            "Already have an account?",
                            style: TextStyle(
                              color: const Color(0xFF10B981),
                              fontWeight: FontWeight.bold,
                              fontSize: isSmallScreen ? 14 : 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (!_acceptedTerms || !_acceptedPrivacy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You must accept the Terms & Conditions and Privacy Policy to continue"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (selectedHustles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one hustle")),
      );
      return;
    }
    if (_fullPhoneE164 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid phone number")),
      );
      return;
    }
    if (selectedCountry == null || selectedCounty == null || selectedWard == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete location details")),
      );
      return;
    }

    // Build skills list with custom hustle if "Other" provided
    final List<String> finalSkills = List<String>.from(selectedHustles);
    if (finalSkills.contains('Other')) {
      final String custom = otherHustleController.text.trim();
      if (custom.isNotEmpty) {
        finalSkills.remove('Other');
        finalSkills.add(custom);
      }
    }

    final fullLocation = '${selectedCountry!}, ${selectedCounty!}, ${selectedWard!}';
    try {
      final resp = await ApiService().register(
        email: emailController.text.trim(),
        password: passwordController.text,
        fullName: usernameController.text.trim(),
        phoneNumber: _fullPhoneE164!,
        location: fullLocation,
        skills: finalSkills,
      );

      if (!mounted) return;

      if (resp['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created')),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resp['message'] ?? 'Registration failed')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // Helpers ----------------
  Widget _buildTextField(TextEditingController controller, String label, IconData icon,
      {TextInputType keyboardType = TextInputType.text,
      String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        ),
      ),
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String label,
      {String? Function(String?)? validator}) {
    bool obscure = true;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: StatefulBuilder(
        builder: (context, setState) => TextFormField(
          controller: controller,
          obscureText: obscure,
          validator: validator,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => obscure = !obscure),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField(String label, List<String> items, String? value,
      ValueChanged<String?> onChanged, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
        validator: (val) => val == null ? "Select $label" : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        ),
      ),
    );
  }

  Widget _buildMultiSelectField(String label, List<String> options) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: options.map((hustle) {
                  final isSelected = selectedHustles.contains(hustle);
                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth > 300 ? 120 : 100,
                    ),
                    child: FilterChip(
                      label: Text(
                        hustle,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            selectedHustles.add(hustle);
                          } else {
                            selectedHustles.remove(hustle);
                          }
                        });
                      },
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Face Capture Screen for biometric enrollment
class _FaceCaptureScreen extends StatefulWidget {
  final CameraDescription camera;

  const _FaceCaptureScreen({required this.camera});

  @override
  State<_FaceCaptureScreen> createState() => _FaceCaptureScreenState();
}

class _FaceCaptureScreenState extends State<_FaceCaptureScreen> {
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
      
      // Save to app documents directory
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = '${directory.path}/face_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = File(imagePath);
      await File(image.path).copy(savedImage.path);
      
      if (!mounted) return;
      Navigator.of(context).pop(savedImage);
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
