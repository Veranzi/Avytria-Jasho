import 'package:flutter/material.dart';
import '../services/comprehensive_voice_service.dart';

/// Voice Assistant Icon Button for AppBars
/// 
/// A compact mic icon button that can be added to any AppBar
/// Provides the same voice navigation as VoiceAssistantButton but
/// optimized for AppBar usage
class VoiceAssistantIconButton extends StatefulWidget {
  const VoiceAssistantIconButton({super.key});

  @override
  State<VoiceAssistantIconButton> createState() => _VoiceAssistantIconButtonState();
}

class _VoiceAssistantIconButtonState extends State<VoiceAssistantIconButton> 
    with SingleTickerProviderStateMixin {
  ComprehensiveVoiceService? _voiceService;
  late AnimationController _animationController;
  bool _isListening = false;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize voice service with context
    _voiceService ??= ComprehensiveVoiceService(context);
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _toggleListening() async {
    if (_voiceService == null) return;
    
    if (_isListening) {
      _voiceService!.stopListening();
      setState(() => _isListening = false);
      _animationController.stop();
    } else {
      setState(() => _isListening = true);
      _animationController.repeat();
      _voiceService!.startListening();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return IconButton(
          icon: Icon(
            _isListening ? Icons.mic : Icons.mic_none,
            color: _isListening 
                ? Colors.white.withOpacity(0.7 + (_animationController.value * 0.3))
                : Colors.white,
            size: 24,
          ),
          onPressed: _toggleListening,
          tooltip: _isListening ? 'Stop Voice Navigation' : 'Voice Navigation',
        );
      },
    );
  }
}

