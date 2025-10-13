import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;
  
  // Voice navigation for accessibility
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _speechEnabled = false;
  bool _isListening = false;
  bool _hasAnnounced = false;

  // Images and their corresponding messages (2 lines each)
  final List<Map<String, dynamic>> _slides = [
    {
      'image': 'Baba-fua.jpeg',
      'line1': '💧 Baba Fua (Laundry Worker)',
      'line2': 'Jasho helps you track, save, and grow every shilling of your hustle.',
    },
    {
      'image': 'boda_boda.jpeg',
      'line1': '🛵 Boda Boda Rider',
      'line2': 'Jasho helps you track your daily earnings and spend wisely.',
    },
    {
      'image': 'mama_mboga.jpeg',
      'line1': '🍅 Mama Mboga (Market Vendor)',
      'line2': 'Turn your daily hustle into lasting profit with Jasho.',
    },
    {
      'image': 'street_vendor.jpeg',
      'line1': '🧺 Street Vendor',
      'line2': 'Jasho helps you stabilize your hustle and plan ahead, one sale at a time.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
    _initVoiceNavigation();
  }
  
  Future<void> _initVoiceNavigation() async {
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
           voice['name'].toString().toLowerCase().contains('woman')) &&
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
    
    // Check if microphone permission is already granted
    final micStatus = await Permission.microphone.status;
    if (micStatus.isGranted) {
      _speechEnabled = await _speech.initialize(
        onError: (error) => print('Speech error: $error'),
        onStatus: (status) {
          if (status == 'done' && mounted) {
            setState(() => _isListening = false);
            // Restart listening after command
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) _startVoiceListener();
            });
          }
        },
      );
      
      if (_speechEnabled) {
        // Announce screen and start listening
        await Future.delayed(const Duration(milliseconds: 500));
        await _announceScreen();
        _startVoiceListener();
      }
    }
  }
  
  Future<void> _announceScreen() async {
    if (!_hasAnnounced) {
      await _tts.speak(
        'Welcome to Jasho. Say "Log In" to access your account, or say "Get Started" to create a new account. You can also say "Help" for more options.'
      );
      _hasAnnounced = true;
    }
  }
  
  Future<void> _startVoiceListener() async {
    if (!_speechEnabled || !mounted || _isListening) return;
    
    setState(() => _isListening = true);
    
    _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          final command = result.recognizedWords.toLowerCase();
          print('Voice command: $command');
          _processVoiceCommand(command);
        }
      },
      localeId: 'en_KE',
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 2),
    );
  }
  
  void _processVoiceCommand(String command) {
    // Log in commands (English & Swahili)
    if (command.contains('log in') || 
        command.contains('login') || 
        command.contains('sign in') ||
        command.contains('signin') ||
        command.contains('ingia') || // Swahili: enter/login
        command.contains('weka sahihi')) { // Swahili: sign in
      _tts.speak('Navigating to login');
      Navigator.pushNamed(context, '/login');
    }
    
    // Sign up / Get Started commands (English & Swahili)
    else if (command.contains('get started') || 
             command.contains('sign up') ||
             command.contains('signup') ||
             command.contains('register') ||
             command.contains('create account') ||
             command.contains('new account') ||
             command.contains('anza') || // Swahili: start
             command.contains('jiandikishe') || // Swahili: register
             command.contains('fungua akaunti')) { // Swahili: open account
      _tts.speak('Navigating to sign up');
      Navigator.pushNamed(context, '/signup');
    }
    
    // Accessible login (for PWD users)
    else if (command.contains('accessible') ||
             command.contains('accessibility') ||
             command.contains('voice login') ||
             command.contains('face login') ||
             command.contains('disabled')) {
      _tts.speak('Opening accessible login');
      Navigator.pushNamed(context, '/accessibleLogin');
    }
    
    // Help command
    else if (command.contains('help') || 
             command.contains('options') ||
             command.contains('msaada')) { // Swahili: help
      _announceScreen();
    }
    
    // Back command
    else if (command.contains('back') || 
             command.contains('go back') ||
             command.contains('rudi')) { // Swahili: return
      if (Navigator.canPop(context)) {
        _tts.speak('Going back');
        Navigator.pop(context);
      }
    }
    
    // Unrecognized command
    else {
      _tts.speak('Sorry, I did not understand. Say "Log In", "Get Started", or "Help".');
    }
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_currentPage < _slides.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsiveness
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Full-screen image slideshow
              PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      // Full-screen image
                      Positioned.fill(
                        child: Image.asset(
                          _slides[index]['image']!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(0xFFFF6B6B).withValues(alpha: 0.8),
                                    const Color(0xFFFFD93D).withValues(alpha: 0.7),
                                    const Color(0xFF6BCB77).withValues(alpha: 0.8),
                                    const Color(0xFF4D96FF).withValues(alpha: 0.7),
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.image_outlined,
                                  size: 100,
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      
                      // Gradient overlay for better text readability
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.2),
                                Colors.black.withValues(alpha: 0.3),
                                Colors.black.withValues(alpha: 0.7),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Text overlay at BOTTOM (just above indicators)
                      Positioned(
                        bottom: constraints.maxHeight * 0.37,
                        left: 0,
                        right: 0,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: constraints.maxWidth * 0.08,
                          ),
                          child: Column(
                            children: [
                              // Line 1 (Title with emoji)
                              Text(
                                _slides[index]['line1']!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 18 : 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.3,
                                ),
                              ),
                              SizedBox(height: 12),
                              // Line 2 (Message)
                              Text(
                                _slides[index]['line2']!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 16,
                                  color: Colors.white,
                                  height: 1.4,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Page indicators
                      Positioned(
                        bottom: constraints.maxHeight * 0.32,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _slides.length,
                            (i) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              height: 8,
                              width: i == _currentPage ? 24 : 8,
                              decoration: BoxDecoration(
                                color: i == _currentPage
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              // Bottom white card
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: constraints.maxWidth * 0.06,
                    vertical: isSmallScreen ? 16 : 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 500,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Back arrow
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              icon: Icon(
                                Icons.arrow_back,
                                size: isSmallScreen ? 22 : 24,
                              ),
                              onPressed: () {
                                if (Navigator.canPop(context)) {
                                  Navigator.pop(context);
                                }
                              },
                              padding: EdgeInsets.zero,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 4 : 8),

                          // Welcome Back heading
                          Text(
                            'Welcome Back',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 20 : 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 8 : 10),

                          // Description text
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: constraints.maxWidth * 0.02,
                            ),
                            child: Text(
                              'We\'re thrilled to have you back. Let\'s dive right in and start transacting.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 12 : 14,
                                color: Colors.grey[600],
                                height: 1.4,
                              ),
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 20 : 28),

                          // Login Button
                          SizedBox(
                            width: double.infinity,
                            height: isSmallScreen ? 48 : 54,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/login');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'Log In',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 12 : 14),

                          // Get Started Button (changed from Sign Up)
                          SizedBox(
                            width: double.infinity,
                            height: isSmallScreen ? 48 : 54,
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/signup');
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFF10B981),
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                'Get Started',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 16,
                                  color: const Color(0xFF10B981),
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 8 : 12),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

