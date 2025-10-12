import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_provider.dart';

class EnhancedChatbotScreen extends StatefulWidget {
  const EnhancedChatbotScreen({super.key});

  @override
  State<EnhancedChatbotScreen> createState() => _EnhancedChatbotScreenState();
}

class _EnhancedChatbotScreenState extends State<EnhancedChatbotScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _speechEnabled = false;
  bool _voiceMode = false;
  
  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();
    _addBotMessage(_getWelcomeMessage());
  }

  String _getWelcomeMessage() {
    final locale = Provider.of<LocaleProvider>(context, listen: false).languageCode;
    if (locale == 'sw') {
      return 'Habari! Mimi ni msaidizi wa Jasho. Naweza kukusaidia na nini leo?';
    }
    return 'Hello! I\'m Jasho assistant. How can I help you today?';
  }

  Future<void> _initSpeech() async {
    _speechEnabled = await _speech.initialize(
      onError: (error) => setState(() => _isListening = false),
      onStatus: (status) {
        if (status == 'done') {
          setState(() => _isListening = false);
        }
      },
    );
  }

  Future<void> _initTts() async {
    final locale = Provider.of<LocaleProvider>(context, listen: false).languageCode;
    await _tts.setLanguage(locale == 'sw' ? "sw-KE" : "en-US");
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    
    _tts.setCompletionHandler(() {
      setState(() => _isSpeaking = false);
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
    _processUserMessage(text);
  }

  void _addBotMessage(String text, {bool speak = false}) {
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
    
    if (speak && _voiceMode) {
      _speak(text);
    }
  }

  Future<void> _speak(String text) async {
    setState(() => _isSpeaking = true);
    await _tts.speak(text);
  }

  void _stopSpeaking() {
    _tts.stop();
    setState(() => _isSpeaking = false);
  }

  void _startListening() async {
    if (!_speechEnabled) return;
    
    setState(() => _isListening = true);
    
    final locale = Provider.of<LocaleProvider>(context, listen: false).languageCode;
    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          _textController.text = result.recognizedWords;
          _handleSubmit();
        }
      },
      localeId: locale == 'sw' ? 'sw_KE' : 'en_US',
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
    );
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  void _processUserMessage(String text) {
    // Simulate bot response (in real app, call API)
    Future.delayed(const Duration(seconds: 1), () {
      final response = _generateResponse(text.toLowerCase());
      _addBotMessage(response, speak: true);
    });
  }

  String _generateResponse(String input) {
    final locale = Provider.of<LocaleProvider>(context, listen: false).languageCode;
    final isSwahili = locale == 'sw';
    
    // Savings-related queries
    if (input.contains('save') || input.contains('saving') || input.contains('hifadhi') || input.contains('akiba')) {
      return isSwahili
          ? 'Unaweza kuunda lengo la akiba kwenye sehemu ya Savings. Chagua kiasi cha lengo lako na tarehe ya kukamilisha.'
          : 'You can create a savings goal in the Savings section. Choose your target amount and completion date.';
    }
    
    // Job-related queries
    if (input.contains('job') || input.contains('gig') || input.contains('kazi')) {
      return isSwahili
          ? 'Kwa kupata kazi, nenda kwenye sehemu ya Jobs. Unaweza kutazama kazi zinazopatikana na kuomba. Unaweza pia kuweka tangazo la kazi.'
          : 'To find jobs, go to the Jobs section. You can browse available gigs and apply. You can also post a job.';
    }
    
    // Wallet/money queries
    if (input.contains('wallet') || input.contains('money') || input.contains('pesa') || input.contains('mkoba')) {
      return isSwahili
          ? 'Mkoba wako unakuruhusu kuweka pesa, kutoa pesa, na kubadilisha sarafu. Unaweza pia kuhifadhi pesa kwenye mlengo wa akiba.'
          : 'Your wallet allows you to deposit, withdraw, and convert currencies. You can also save money towards your goals.';
    }
    
    // Loan queries
    if (input.contains('loan') || input.contains('borrow') || input.contains('mkopo')) {
      return isSwahili
          ? 'Unaweza kuomba mkopo katika sehemu ya Savings & Loans. Kiasi cha mkopo kinategemea alama yako ya mkopo na historia ya matumizi.'
          : 'You can request a loan in the Savings & Loans section. The loan amount depends on your credit score and usage history.';
    }
    
    // Security queries
    if (input.contains('secure') || input.contains('safe') || input.contains('security') || input.contains('usalama')) {
      return isSwahili
          ? 'Pesa zako ni salama. Tunatumia usimbaji fiche, uthibitishaji wa PIN, na ufuatiliaji wa ulaghai ili kulinda akaunti yako.'
          : 'Your money is secure. We use encryption, PIN authentication, and fraud monitoring to protect your account.';
    }
    
    // Help queries
    if (input.contains('help') || input.contains('how') || input.contains('msaada') || input.contains('jinsi')) {
      return isSwahili
          ? 'Nina hapa kukusaidia! Unaweza kuniuliza kuhusu akiba, kazi, mkoba, mikopo, au chochote kingine kuhusu Jasho.'
          : 'I\'m here to help! You can ask me about savings, jobs, wallet, loans, or anything else about Jasho.';
    }
    
    // Fraud reporting
    if (input.contains('fraud') || input.contains('scam') || input.contains('fake') || input.contains('ulaghai') || input.contains('udanganyifu')) {
      return isSwahili
          ? 'Kwa kuripoti ulaghai, bonyeza kitufe cha "Ripoti Ulaghai" kwenye skrini ya tangazo au wasiliana na msaada wa wateja.'
          : 'To report fraud, tap the "Report Fraud" button on the post screen or contact customer support.';
    }
    
    // Default response
    return isSwahili
        ? 'Nashukuru kuuliza! Je, ungependa kujua zaidi kuhusu akiba, kazi, au huduma zingine za Jasho?'
        : 'Thanks for asking! Would you like to know more about savings, jobs, or other Jasho services?';
  }

  void _handleSubmit() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    
    _addUserMessage(text);
    _textController.clear();
  }

  void _toggleLanguage() {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final newLocale = localeProvider.languageCode == 'en' ? 'sw' : 'en';
    localeProvider.setLanguage(newLocale);
    
    _initTts(); // Reinitialize TTS with new language
    
    final message = newLocale == 'sw'
        ? 'Lugha imebadilishwa kuwa Kiswahili'
        : 'Language changed to English';
    
    _addBotMessage(message, speak: true);
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().languageCode;
    final isSwahili = locale == 'sw';
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isSwahili ? 'Msaidizi wa Jasho' : 'Jasho Assistant'),
        backgroundColor: const Color(0xFF10B981),
        actions: [
          // Voice Mode Toggle
          IconButton(
            icon: Icon(_voiceMode ? Icons.volume_up : Icons.volume_off),
            onPressed: () {
              setState(() => _voiceMode = !_voiceMode);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _voiceMode 
                        ? (isSwahili ? 'Hali ya sauti imewashwa' : 'Voice mode enabled')
                        : (isSwahili ? 'Hali ya sauti imezimwa' : 'Voice mode disabled'),
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          // Language Toggle
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: _toggleLanguage,
            tooltip: isSwahili ? 'Switch to English' : 'Badili kwenda Kiswahili',
          ),
        ],
      ),
      body: Column(
        children: [
          // Language indicator
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            color: Colors.blue.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.language, size: 16.sp, color: Colors.blue.shade700),
                SizedBox(width: 8.w),
                Text(
                  isSwahili ? 'Kiswahili' : 'English',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_voiceMode) ...[
                  SizedBox(width: 16.w),
                  Icon(Icons.mic, size: 16.sp, color: Colors.green.shade700),
                  SizedBox(width: 4.w),
                  Text(
                    isSwahili ? 'Sauti Imewashwa' : 'Voice Enabled',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(16.w),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _ChatBubble(
                  message: message,
                  onSpeak: _voiceMode ? () => _speak(message.text) : null,
                );
              },
            ),
          ),
          
          // Input area
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: EdgeInsets.all(12.w),
            child: Row(
              children: [
                // Voice input button
                IconButton(
                  icon: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening ? Colors.red : const Color(0xFF10B981),
                  ),
                  onPressed: _isListening ? _stopListening : _startListening,
                ),
                
                // Text input
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: isSwahili ? 'Andika ujumbe...' : 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 10.h,
                      ),
                    ),
                    onSubmitted: (_) => _handleSubmit(),
                  ),
                ),
                
                SizedBox(width: 8.w),
                
                // Send button
                CircleAvatar(
                  backgroundColor: const Color(0xFF10B981),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _handleSubmit,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onSpeak;

  const _ChatBubble({
    required this.message,
    this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              backgroundColor: const Color(0xFF10B981),
              radius: 16.r,
              child: Icon(Icons.support_agent, color: Colors.white, size: 18.sp),
            ),
            SizedBox(width: 8.w),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: message.isUser
                    ? const Color(0xFF10B981)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(message.isUser ? 16.r : 4.r),
                  topRight: Radius.circular(message.isUser ? 4.r : 16.r),
                  bottomLeft: Radius.circular(16.r),
                  bottomRight: Radius.circular(16.r),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser ? Colors.white : Colors.black87,
                      fontSize: 14.sp,
                    ),
                  ),
                  if (!message.isUser && onSpeak != null) ...[
                    SizedBox(height: 4.h),
                    GestureDetector(
                      onTap: onSpeak,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.volume_up,
                            size: 14.sp,
                            color: const Color(0xFF10B981),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'Listen',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: const Color(0xFF10B981),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            SizedBox(width: 8.w),
            CircleAvatar(
              backgroundColor: Colors.grey.shade300,
              radius: 16.r,
              child: Icon(Icons.person, color: Colors.grey.shade700, size: 18.sp),
            ),
          ],
        ],
      ),
    );
  }
}

