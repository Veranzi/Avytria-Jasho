import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import '../../../services/pwd_voice_navigation.dart';
import '../../../services/pwd_preferences.dart';

class WelcomeScreenWithPWD extends StatefulWidget {
  const WelcomeScreenWithPWD({super.key});

  @override
  State<WelcomeScreenWithPWD> createState() => _WelcomeScreenWithPWDState();
}

class _WelcomeScreenWithPWDState extends State<WelcomeScreenWithPWD> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;
  Timer? _autoSuggestTimer;

  // PWD Voice Navigation
  final PWDVoiceNavigation _pwdVoice = PWDVoiceNavigation();
  bool _isPWDModeActive = false;
  bool _showAutoSuggest = false;
  bool _hasUserInteracted = false;

  // Images and their corresponding messages
  final List<Map<String, dynamic>> _slides = [
    {
      'image': 'Baba-fua.jpeg',
      'line1': '💧 Baba Fua (Laundry Worker)',
      'line2':
          'Jasho helps you track, save, and grow every shilling of your hustle.',
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
      'line2':
          'Jasho helps you stabilize your hustle and plan ahead, one sale at a time.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
    _checkPWDPreference();
    _startAutoSuggestTimer();
  }

  Future<void> _checkPWDPreference() async {
    final isEnabled = await PWDPreferences.isPWDModeEnabled();
    if (isEnabled && mounted) {
      await _enablePWDMode();
    }
  }

  void _startAutoSuggestTimer() async {
    final shouldShow = await PWDPreferences.shouldShowAutoSuggest();
    if (!shouldShow) return;

    _autoSuggestTimer = Timer(const Duration(seconds: 5), () {
      if (!_hasUserInteracted && !_isPWDModeActive && mounted) {
        setState(() => _showAutoSuggest = true);
      }
    });
  }

  Future<void> _enablePWDMode() async {
    final initialized = await _pwdVoice.initialize();
    if (!initialized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to initialize voice navigation. Please check microphone permissions.',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    setState(() => _isPWDModeActive = true);

    // Speak welcome message
    await _pwdVoice.speakWelcome();

    // Start listening for voice commands
    _pwdVoice.startListening(
      onNavigate: _handleNavigation,
      onCommand: _handleCommand,
    );
  }

  Future<void> _disablePWDMode() async {
    _pwdVoice.stopListening();
    setState(() => _isPWDModeActive = false);
  }

  void _handleNavigation(String destination) {
    if (!mounted) return;

    if (destination == 'login') {
      Navigator.pushNamed(context, '/login');
    } else if (destination == 'signup') {
      Navigator.pushNamed(context, '/signup');
    }
  }

  void _handleCommand(String command) {
    if (command == 'exit') {
      _disablePWDMode();
    } else if (command == 'help') {
      // Already handled by PWDVoiceNavigation
    }
  }

  void _markUserInteraction() {
    setState(() => _hasUserInteracted = true);
    _autoSuggestTimer?.cancel();
  }

  void _dismissAutoSuggest(bool permanently) async {
    _markUserInteraction();
    setState(() => _showAutoSuggest = false);
    if (permanently) {
      await PWDPreferences.disableAutoSuggest();
    }
  }

  Future<void> _handlePWDButtonPress() async {
    _markUserInteraction();
    if (!_isPWDModeActive) {
      await _enablePWDMode();

      // Ask if user wants to remember preference
      if (mounted) {
        final remember = await _showRememberDialog();
        if (remember == true) {
          await PWDPreferences.setPWDModeEnabled(true);
        }
      }
    } else {
      await _disablePWDMode();
    }
  }

  Future<bool?> _showRememberDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remember Preference?'),
        content: const Text(
          'Would you like to automatically enable voice navigation next time you open the app?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No, Thanks'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
            ),
            child: const Text('Yes, Remember'),
          ),
        ],
      ),
    );
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
    _autoSuggestTimer?.cancel();
    _pageController.dispose();
    _pwdVoice.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Full-screen image slideshow (existing code)
              _buildSlideshow(constraints, isSmallScreen),

              // Bottom white card with buttons
              _buildBottomCard(constraints, isSmallScreen),

              // PWD Accessibility Button (TOP)
              _buildPWDAccessibilityButton(isSmallScreen),

              // Auto-suggest popup
              if (_showAutoSuggest) _buildAutoSuggestPopup(),

              // PWD Mode Active Indicator
              if (_isPWDModeActive) _buildPWDModeIndicator(isSmallScreen),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSlideshow(BoxConstraints constraints, bool isSmallScreen) {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() => _currentPage = index);
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

            // Gradient overlay
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

            // Text overlay at BOTTOM
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
                    const SizedBox(height: 12),
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
    );
  }

  Widget _buildBottomCard(BoxConstraints constraints, bool isSmallScreen) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: constraints.maxWidth * 0.06,
          vertical: isSmallScreen ? 16 : 20,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Back arrow
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, size: isSmallScreen ? 22 : 24),
                    onPressed: () {
                      _markUserInteraction();
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
                      _markUserInteraction();
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

                // Get Started Button
                SizedBox(
                  width: double.infinity,
                  height: isSmallScreen ? 48 : 54,
                  child: OutlinedButton(
                    onPressed: () {
                      _markUserInteraction();
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
    );
  }

  Widget _buildPWDAccessibilityButton(bool isSmallScreen) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          color: _isPWDModeActive ? const Color(0xFF10B981) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _handlePWDButtonPress,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: isSmallScreen ? 12 : 14,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isPWDModeActive ? Icons.mic : Icons.accessible,
                    color: _isPWDModeActive
                        ? Colors.white
                        : const Color(0xFF10B981),
                    size: isSmallScreen ? 20 : 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isPWDModeActive
                          ? '🎤 Voice Mode Active'
                          : '♿ Accessibility Mode',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.w600,
                        color: _isPWDModeActive
                            ? Colors.white
                            : const Color(0xFF10B981),
                      ),
                    ),
                  ),
                  if (_isPWDModeActive)
                    Text(
                      'Tap to disable',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAutoSuggestPopup() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.7),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.accessible_forward,
                  size: 48,
                  color: Color(0xFF10B981),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Need Hands-Free Help?',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enable voice navigation to use Jasho without touching your screen. Perfect for people with disabilities.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _dismissAutoSuggest(true),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.grey),
                        ),
                        child: const Text('No, Thanks'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          _dismissAutoSuggest(false);
                          await _handlePWDButtonPress();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                        ),
                        child: const Text('Yes, Enable'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPWDModeIndicator(bool isSmallScreen) {
    return Positioned(
      bottom: 100,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  _pwdVoice.isListening ? Icons.mic : Icons.mic_off,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _pwdVoice.isListening ? '🔴 Listening...' : '⏸️ Paused',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Say: "Login", "Sign up", "Help", or "Turn off voice"',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
