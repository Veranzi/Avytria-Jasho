import 'package:flutter/material.dart';
import '../services/voice_navigation_service.dart';

/// Floating Voice Assistant Button
/// 
/// A persistent button that allows users to navigate the app using voice commands.
/// Features:
/// - Feminine Kenyan voice
/// - English/Swahili support
/// - Voice-controlled permissions
/// - PWD-friendly
class VoiceAssistantButton extends StatefulWidget {
  const VoiceAssistantButton({super.key});

  @override
  State<VoiceAssistantButton> createState() => _VoiceAssistantButtonState();
}

class _VoiceAssistantButtonState extends State<VoiceAssistantButton> with SingleTickerProviderStateMixin {
  final VoiceNavigationService _voiceService = VoiceNavigationService();
  late AnimationController _animationController;
  bool _isInitialized = false;
  bool _isListening = false;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    
    _initializeVoiceService();
  }
  
  Future<void> _initializeVoiceService() async {
    final success = await _voiceService.initialize(language: 'en');
    if (mounted) {
      setState(() => _isInitialized = success);
      if (success) {
        await _voiceService.speak('welcome');
      }
    }
  }
  
  Future<void> _handleVoiceCommand() async {
    if (!_isInitialized || _isListening) return;
    
    setState(() => _isListening = true);
    
    // Speak prompt
    await _voiceService.speak('help');
    
    // Listen for command
    final command = await _voiceService.listenForNavigationCommand();
    
    if (command != null && mounted) {
      await _voiceService.navigateWithVoice(context, command);
    }
    
    if (mounted) {
      setState(() => _isListening = false);
    }
  }
  
  void _showVoiceMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _VoiceMenuSheet(
        voiceService: _voiceService,
        onLanguageChange: (lang) async {
          await _voiceService.switchLanguage(lang);
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  lang == 'en' ? 'Language switched to English' : 'Lugha imebadilishwa kuwa Kiswahili',
                ),
                backgroundColor: const Color(0xFF10B981),
              ),
            );
          }
        },
      ),
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: _showVoiceMenu,
      child: FloatingActionButton(
        onPressed: _handleVoiceCommand,
        backgroundColor: _isListening ? Colors.red : const Color(0xFF10B981),
        child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          if (_isListening) {
            return Transform.scale(
              scale: 1.0 + (_animationController.value * 0.2),
              child: const Icon(Icons.mic, color: Colors.white),
            );
          }
          return child!;
        },
        child: const Icon(Icons.record_voice_over, color: Colors.white),
      ),
      ),
    );
  }
}

/// Voice Menu Sheet for settings
class _VoiceMenuSheet extends StatelessWidget {
  final VoiceNavigationService voiceService;
  final Function(String) onLanguageChange;
  
  const _VoiceMenuSheet({
    required this.voiceService,
    required this.onLanguageChange,
  });
  
  @override
  Widget build(BuildContext context) {
    final currentLang = voiceService.currentLanguage;
    
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.record_voice_over, color: Color(0xFF10B981), size: 28),
              const SizedBox(width: 12),
              const Text(
                'Voice Assistant',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Language selection
          const Text(
            'Language / Lugha',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: currentLang == 'en' ? null : () => onLanguageChange('en'),
                  icon: const Icon(Icons.language),
                  label: const Text('English'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: currentLang == 'en' 
                        ? const Color(0xFF10B981) 
                        : Colors.grey[300],
                    foregroundColor: currentLang == 'en' ? Colors.white : Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: currentLang == 'sw' ? null : () => onLanguageChange('sw'),
                  icon: const Icon(Icons.language),
                  label: const Text('Kiswahili'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: currentLang == 'sw' 
                        ? const Color(0xFF10B981) 
                        : Colors.grey[300],
                    foregroundColor: currentLang == 'sw' ? Colors.white : Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Voice commands help
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: const Color(0xFF10B981)),
                    const SizedBox(width: 8),
                    const Text(
                      'Voice Commands',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Tap button: Start voice navigation\n'
                  '• Long press: Open this menu\n'
                  '• Say "Help" for available commands\n'
                  '• Feminine voice with Kenyan accent\n'
                  '• Works in English and Swahili',
                  style: TextStyle(fontSize: 12, height: 1.5),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

