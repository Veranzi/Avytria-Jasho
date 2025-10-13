import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/gemini_service.dart';
import 'package:permission_handler/permission_handler.dart';

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
  final GeminiService _geminiService = GeminiService();
  
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _speechEnabled = false;
  bool _voiceMode = false;
  bool _isProcessing = false;
  
  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();
    _initGemini();
    _addBotMessage(_getWelcomeMessage());
  }
  
  Future<void> _initGemini() async {
    try {
      await _geminiService.initialize();
      print('✅ Gemini AI ready for chatbot');
    } catch (e) {
      print('❌ Gemini initialization failed: $e');
      // Will fall back to local responses
    }
  }

  String _getWelcomeMessage() {
    final locale = Provider.of<LocaleProvider>(context, listen: false).languageCode;
    if (locale == 'sw') {
      return 'Habari! Mimi ni msaidizi wa Jasho. Naweza kukusaidia na nini leo?';
    }
    return 'Hello! I\'m Jasho assistant. How can I help you today?';
  }

  Future<void> _initSpeech() async {
    // Explicitly request microphone permission first
    final micStatus = await Permission.microphone.request();
    
    if (micStatus.isGranted) {
      _speechEnabled = await _speech.initialize(
        onError: (error) {
          print('Speech error: $error');
          if (mounted) setState(() => _isListening = false);
        },
        onStatus: (status) {
          print('Speech status: $status');
          if (status == 'done' && mounted) {
            setState(() => _isListening = false);
          }
        },
      );
      print('🎤 Speech initialized: $_speechEnabled');
    } else if (micStatus.isDenied) {
      print('❌ Microphone permission denied');
      _speechEnabled = false;
    } else if (micStatus.isPermanentlyDenied) {
      print('❌ Microphone permission permanently denied');
      _speechEnabled = false;
      // Open app settings
      openAppSettings();
    }
  }

  Future<void> _initTts() async {
    final locale = Provider.of<LocaleProvider>(context, listen: false).languageCode;
    
    // Set language with Kenyan accents
    await _tts.setLanguage(locale == 'sw' ? "sw-KE" : "en-KE");
    
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
           voice['locale']?.toString().contains('ke') == true ||
           (locale == 'sw' && voice['locale']?.toString().contains('sw') == true)),
        orElse: () => voices.first,
      );
      
      if (femaleVoice != null) {
        await _tts.setVoice({
          "name": femaleVoice['name'],
          "locale": femaleVoice['locale'],
        });
      }
    }
    
    _tts.setCompletionHandler(() {
      if (mounted) {
        setState(() => _isSpeaking = false);
      }
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
    if (!_speechEnabled) {
      // Request permission with better handling
      await _speak('Requesting microphone permission...');
      await _initSpeech();
      if (!_speechEnabled) {
        await _speak('Microphone permission denied. Please enable it in your device settings to use voice input.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('🎤 Microphone permission required for voice input'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Enable',
                textColor: Colors.white,
                onPressed: () async {
                  // Re-try permission
                  await _initSpeech();
                },
              ),
            ),
          );
        }
        return;
      } else {
        await _speak('Microphone enabled! You can now speak.');
      }
    }
    
    setState(() => _isListening = true);
    
    // Give audio feedback
    await _speak('Listening... Speak now!');
    
    final locale = Provider.of<LocaleProvider>(context, listen: false).languageCode;
    await _speech.listen(
      onResult: (result) {
        setState(() {
          _textController.text = result.recognizedWords;
        });
        
        if (result.finalResult) {
          _handleSubmit();
        }
      },
      localeId: locale == 'sw' ? 'sw_KE' : 'en_KE', // Kenyan English for better recognition
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      onSoundLevelChange: (level) {
        // Visual feedback for sound level (optional)
        // Can be used to show a waveform or volume indicator
      },
    );
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  void _processUserMessage(String text) async {
    final locale = Provider.of<LocaleProvider>(context, listen: false).languageCode;
    
    setState(() => _isProcessing = true);
    
    try {
      // Use Gemini AI for intelligent responses
      String response;
      if (_geminiService.isInitialized) {
        response = await _geminiService.sendMessage(text, language: locale);
      } else {
        // Fallback to local responses if Gemini not available
        response = _generateResponse(text.toLowerCase());
      }
      
      setState(() => _isProcessing = false);
      _addBotMessage(response, speak: true);
    } catch (e) {
      print('Error generating response: $e');
      setState(() => _isProcessing = false);
      
      // Fallback to local response on error
      final response = _generateResponse(text.toLowerCase());
      _addBotMessage(response, speak: true);
    }
  }

  String _generateResponse(String input) {
    final locale = Provider.of<LocaleProvider>(context, listen: false).languageCode;
    final isSwahili = locale == 'sw';
    
    // KYC queries
    if (input.contains('kyc') || input.contains('verify') || input.contains('verification') || input.contains('uthibitisho')) {
      return isSwahili
          ? 'KYC (Uthibitisho wa Utambulisho) ni muhimu kwa kupata huduma zote. Nenda kwenye Profile > KYC, weka maelezo yako na picha za vitambulisho. Baada ya kuwasilisha, itakaguliwa na timu yetu.'
          : 'KYC (Know Your Customer) verification is required for full access. Go to Profile > KYC, enter your details and upload ID documents. After submission, it will be reviewed by our team.';
    }
    
    // Insurance queries
    if (input.contains('insurance') || input.contains('cover') || input.contains('bima')) {
      return isSwahili
          ? 'Jasho inatoa bima mbalimbali: Afya, Maisha, Ajali, na Mali. Nenda kwenye sehemu ya Insurance, chagua aina ya bima, na lipia kila mwezi. Bima zako zitahifadhiwa kwenye akaunti yako.'
          : 'Jasho offers various insurance: Health, Life, Accident, and Property. Go to Insurance section, select your coverage type, and pay monthly premiums. Your policies are stored in your account.';
    }
    
    // Savings tiers
    if (input.contains('standing order') || input.contains('automatic') || input.contains('auto save')) {
      return isSwahili
          ? 'Standing Order ni akiba za kiotomatiki. Chagua kiasi na mzunguko (kila wiki/mwezi). Pesa zitatolewa kiotomatiki kutoka mkoba wako na kuwekwa kwenye akiba. Unaweza kuziangalia kwenye Savings > Standing Order.'
          : 'Standing Order is automatic savings. Choose amount and frequency (weekly/monthly). Money will be auto-deducted from your wallet and saved. Check it in Savings > Standing Order.';
    }
    
    if (input.contains('voluntary') || input.contains('manual save') || input.contains('akiba ya hiari')) {
      return isSwahili
          ? 'Akiba za Hiari ni ambapo unahifadhi pesa wakati unapotaka. Unda lengo, weka kiasi cha lengo, na ongeza pesa wakati wowote. Unaweza kuziangalia kwenye Savings > Voluntary Savings.'
          : 'Voluntary Savings is where you save when you want. Create a goal, set target amount, and add money anytime. Check it in Savings > Voluntary Savings.';
    }
    
    // Gig marketplace
    if (input.contains('apply') || input.contains('application') || input.contains('omba kazi')) {
      return isSwahili
          ? 'Kuomba kazi: Bonyeza "Apply" kwenye tangazo, wasiliana na mpangaji kupitia nambari/barua pepe iliyotolewa. Baada ya kukamilisha, bonyeza "Complete", mwajiri atakulipia, kisha "Mark as Paid", na mwishowe toa ukaguzi (nyota 0-5 na maoni).'
          : 'To apply for gig: Tap "Apply" on listing, contact poster via phone/email provided. After completion, tap "Complete", employer pays you, then "Mark as Paid", and finally submit review (0-5 stars with comment).';
    }
    
    if (input.contains('post') || input.contains('create job') || input.contains('weka kazi')) {
      return isSwahili
          ? 'Kwa kuweka kazi: Lazima ufanye KYC kwanza. Baada ya KYC, bofya "Post Job", weka maelezo ya kazi. AI itakagua kazi ni halali. Ikiwa ni sawa, kazi itachapishwa. Ikiwa ni udanganyifu, haitachapishwa.'
          : 'To post a job: Complete KYC first. After KYC, tap "Post Job", enter job details. AI will verify the job is legitimate. If approved, job will be published. If fraudulent, it won\'t be posted.';
    }
    
    // Reviews and ratings
    if (input.contains('review') || input.contains('rating') || input.contains('star') || input.contains('ukaguzi')) {
      return isSwahili
          ? 'Baada ya kazi kukamilika na kulipwa, unaweza kutoa ukaguzi. Chagua nyota 0-5 (0=mbaya sana, 5=bora), andika maoni, na wasilisha. Ukaguzi utahifadhiwa na kuonyeshwa kwa wengine.'
          : 'After job completion and payment, you can submit a review. Choose 0-5 stars (0=very bad, 5=excellent), write comment, and submit. Review will be stored and shown to others.';
    }
    
    // AI Insights
    if (input.contains('insight') || input.contains('analysis') || input.contains('spending') || input.contains('matumizi')) {
      return isSwahili
          ? 'AI Insights inaonyesha jinsi unavyotumia pesa. Angalia pie chart ya matumizi, chagua kipindi (kila siku/wiki/mwezi). AI itakuambia wapi unatumia zaidi na jinsi ya kuokoa pesa.'
          : 'AI Insights shows how you spend money. View spending pie chart, select period (daily/weekly/monthly). AI will tell you where you spend most and how to save.';
    }
    
    // Wallet masking
    if (input.contains('hide') || input.contains('mask') || input.contains('balance') || input.contains('salio')) {
      return isSwahili
          ? 'Salio la mkoba linafichwa kwa default kwa usalama. Bonyeza ikoni ya jicho ili kuonyesha/kuficha salio. Unaweza pia kuweka PIN ili kulinda mkoba wako.'
          : 'Wallet balance is masked by default for security. Tap the eye icon to show/hide balance. You can also set a PIN to protect your wallet.';
    }
    
    // QR/Scan
    if (input.contains('scan') || input.contains('qr') || input.contains('code')) {
      return isSwahili
          ? 'Tumia kipokezi cha QR kulipa au kupokea pesa haraka. Bonyeza "Scan", onyesha QR code, na muamala utakamilika. Unaweza pia kuunda QR code wako mwenyewe.'
          : 'Use QR scanner to pay or receive money quickly. Tap "Scan", show QR code, and transaction will complete. You can also generate your own QR code.';
    }
    
    // Manage/Settings
    if (input.contains('manage') || input.contains('settings') || input.contains('mipangilio')) {
      return isSwahili
          ? 'Kwenye Settings unaweza: Badilisha picha ya profile, nambari ya simu, nenosiri, lugha. Pia unaweza angalia historia ya miamala, usalama wa akaunti, na weka PIN.'
          : 'In Settings you can: Change profile picture, phone number, password, language. Also view transaction history, account security, and set PIN.';
    }
    
    // Earnings vs Expenditure
    if (input.contains('earnings') || input.contains('income') || input.contains('expenditure') || input.contains('mapato')) {
      return isSwahili
          ? 'Graf ya Mapato vs Matumizi inaonyesha pesa unazopata na unazotumia. Chagua kipindi (wiki/mwezi), angalia mabadiliko, na AI itakuambia jinsi ya kuongeza mapato na kupunguza matumizi.'
          : 'Earnings vs Expenditure graph shows money you earn and spend. Select period (week/month), view trends, and AI will suggest how to increase earnings and reduce spending.';
    }
    
    // Savings-related queries
    if (input.contains('save') || input.contains('saving') || input.contains('hifadhi') || input.contains('akiba')) {
      return isSwahili
          ? 'Jasho ina aina mbili za akiba: 1) Standing Order (kiotomatiki) - weka kiasi na mzunguko. 2) Voluntary (hiari) - hifadhi wakati wowote. Nenda Savings > Create Goal kuanza.'
          : 'Jasho has two savings types: 1) Standing Order (automatic) - set amount and frequency. 2) Voluntary - save anytime. Go to Savings > Create Goal to start.';
    }
    
    // Job-related queries
    if (input.contains('job') || input.contains('gig') || input.contains('kazi')) {
      return isSwahili
          ? 'Kazi zinapatikana kwenye Jobs section. Unaweza kuomba kazi, kupata mawasiliano ya mpangaji, kukamilisha, kulipwa, na kutoa ukaguzi. Unaweza pia kuweka kazi lakini lazima KYC ifanywe kwanza.'
          : 'Jobs available in Jobs section. You can apply, get poster contact, complete, get paid, and review. You can also post jobs but KYC is required first.';
    }
    
    // Wallet/money queries
    if (input.contains('wallet') || input.contains('money') || input.contains('pesa') || input.contains('mkoba')) {
      return isSwahili
          ? 'Mkoba wako unaonyesha salio lako (linafichwa kwa default). Unaweza kuweka pesa, kutoa pesa, kubadilisha sarafu (KES/USD/USDT), kulipa kwa QR, na kuhifadhi pesa kwenye akiba.'
          : 'Your wallet shows your balance (masked by default). You can deposit, withdraw, convert currencies (KES/USD/USDT), pay with QR, and save money towards goals.';
    }
    
    // Loan queries
    if (input.contains('loan') || input.contains('borrow') || input.contains('mkopo')) {
      return isSwahili
          ? 'Mikopo inapatikana katika Savings & Loans. Kiasi cha mkopo kinategemea credit score yako na historia ya matumizi. Angalia eligibility yako, omba mkopo, na lipia polepole.'
          : 'Loans available in Savings & Loans section. Loan amount depends on your credit score and usage history. Check your eligibility, request loan, and repay gradually.';
    }
    
    // Security queries
    if (input.contains('secure') || input.contains('safe') || input.contains('security') || input.contains('usalama')) {
      return isSwahili
          ? 'Usalama wa Jasho: 1) Usimbaji fiche wa data. 2) PIN ya mkoba. 3) Uthibitisho wa biometric (uso/sauti). 4) Ufuatiliaji wa ulaghai. 5) KYC verification. Pesa zako ni salama kabisa!'
          : 'Jasho Security: 1) Data encryption. 2) Wallet PIN. 3) Biometric authentication (face/voice). 4) Fraud monitoring. 5) KYC verification. Your money is completely safe!';
    }
    
    // Help queries
    if (input.contains('help') || input.contains('how') || input.contains('msaada') || input.contains('jinsi')) {
      return isSwahili
          ? 'Nina hapa kukusaidia 24/7! Niulize kuhusu: Akiba, Kazi, Mkoba, Mikopo, Bima, KYC, AI Insights, QR Scan, Ukaguzi, Usalama, au chochote kingine!'
          : 'I\'m here to help 24/7! Ask me about: Savings, Jobs, Wallet, Loans, Insurance, KYC, AI Insights, QR Scan, Reviews, Security, or anything else!';
    }
    
    // Fraud reporting
    if (input.contains('fraud') || input.contains('scam') || input.contains('fake') || input.contains('ulaghai') || input.contains('udanganyifu')) {
      return isSwahili
          ? 'Ripoti ulaghai mara moja! Bonyeza "Report Fraud" kwenye tangazo au kazi. Timu yetu itachunguza haraka. Watuhumiwa wa ulaghai mara kwa mara watazuiwa kutumia Jasho.'
          : 'Report fraud immediately! Tap "Report Fraud" on any post or job. Our team will investigate quickly. Repeat offenders will be banned from Jasho.';
    }
    
    // Default response
    return isSwahili
        ? 'Nashukuru kuuliza! Niulize kuhusu: Akiba (Standing Order, Voluntary), Kazi (Omba, Weka), Mkoba (Weka/Toa pesa), Mikopo, Bima, KYC, AI Insights, Scan, Ukaguzi, au Usalama!'
        : 'Thanks for asking! Ask me about: Savings (Standing Order, Voluntary), Jobs (Apply, Post), Wallet (Deposit/Withdraw), Loans, Insurance, KYC, AI Insights, Scan, Reviews, or Security!';
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
    
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 700;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isSwahili ? 'Msaidizi wa Jasho' : 'Jasho Assistant',
          style: TextStyle(fontSize: isSmallScreen ? 18 : 20),
        ),
        backgroundColor: const Color(0xFF10B981),
        actions: [
          // Voice Mode Toggle
          IconButton(
            icon: Icon(
              _voiceMode ? Icons.volume_up : Icons.volume_off,
              size: isSmallScreen ? 22 : 24,
            ),
            onPressed: () {
              setState(() => _voiceMode = !_voiceMode);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _voiceMode 
                        ? (isSwahili ? 'Hali ya sauti imewashwa' : 'Voice mode enabled')
                        : (isSwahili ? 'Hali ya sauti imezimwa' : 'Voice mode disabled'),
                    style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            tooltip: isSwahili ? 'Badili hali ya sauti' : 'Toggle voice mode',
          ),
          // Language Toggle
          IconButton(
            icon: Icon(Icons.language, size: isSmallScreen ? 22 : 24),
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
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 12.0 : 16.0,
              vertical: isSmallScreen ? 6.0 : 8.0,
            ),
            color: Colors.blue.shade50,
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: isSmallScreen ? 6 : 8,
              runSpacing: 4,
              children: [
                Icon(
                  Icons.language,
                  size: isSmallScreen ? 14 : 16,
                  color: Colors.blue.shade700,
                ),
                Text(
                  isSwahili ? 'Kiswahili' : 'English',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 11 : 12,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_voiceMode) ...[
                  Icon(
                    Icons.mic,
                    size: isSmallScreen ? 14 : 16,
                    color: Colors.green.shade700,
                  ),
                  Text(
                    isSwahili ? 'Sauti Imewashwa' : 'Voice Enabled',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 11 : 12,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(
                    Icons.face_2,
                    size: isSmallScreen ? 14 : 16,
                    color: Colors.purple.shade700,
                  ),
                  Text(
                    isSwahili ? 'Sauti ya Kike' : 'Feminine Voice',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 11 : 12,
                      color: Colors.purple.shade700,
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
              padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _ChatBubble(
                  message: message,
                  onSpeak: _voiceMode ? () => _speak(message.text) : null,
                  isSmallScreen: isSmallScreen,
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
            padding: EdgeInsets.all(isSmallScreen ? 10.0 : 12.0),
            child: Row(
              children: [
                // Voice input button with animation
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: _isListening ? [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ] : null,
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: _isListening ? Colors.red : const Color(0xFF10B981),
                      size: isSmallScreen ? 24 : 28,
                    ),
                    onPressed: _isListening ? _stopListening : _startListening,
                    tooltip: _isListening 
                        ? (isSwahili ? 'Bonyeza kusitisha' : 'Tap to stop')
                        : (isSwahili ? 'Bonyeza kuzungumza' : 'Tap to speak'),
                  ),
                ),
                
                // Text input
                Expanded(
                  child: TextField(
                    controller: _textController,
                    style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
                    decoration: InputDecoration(
                      hintText: isSwahili ? 'Andika ujumbe...' : 'Type a message...',
                      hintStyle: TextStyle(fontSize: isSmallScreen ? 13 : 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 14.0 : 16.0,
                        vertical: isSmallScreen ? 8.0 : 10.0,
                      ),
                    ),
                    onSubmitted: (_) => _handleSubmit(),
                  ),
                ),
                
                SizedBox(width: isSmallScreen ? 6 : 8),
                
                // Send button
                CircleAvatar(
                  backgroundColor: const Color(0xFF10B981),
                  radius: isSmallScreen ? 20 : 22,
                  child: IconButton(
                    icon: Icon(
                      Icons.send,
                      color: Colors.white,
                      size: isSmallScreen ? 18 : 20,
                    ),
                    onPressed: _handleSubmit,
                    tooltip: isSwahili ? 'Tuma ujumbe' : 'Send message',
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
  final bool isSmallScreen;

  const _ChatBubble({
    required this.message,
    this.onSpeak,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isSmallScreen ? 10.0 : 12.0),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              backgroundColor: const Color(0xFF10B981),
              radius: isSmallScreen ? 14 : 16,
              child: Icon(
                Icons.support_agent,
                color: Colors.white,
                size: isSmallScreen ? 16 : 18,
              ),
            ),
            SizedBox(width: isSmallScreen ? 6 : 8),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 14.0 : 16.0,
                vertical: isSmallScreen ? 10.0 : 12.0,
              ),
              decoration: BoxDecoration(
                color: message.isUser
                    ? const Color(0xFF10B981)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(message.isUser ? 16 : 4),
                  topRight: Radius.circular(message.isUser ? 4 : 16),
                  bottomLeft: const Radius.circular(16),
                  bottomRight: const Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser ? Colors.white : Colors.black87,
                      fontSize: isSmallScreen ? 13 : 14,
                      height: 1.4,
                    ),
                  ),
                  if (!message.isUser && onSpeak != null) ...[
                    SizedBox(height: isSmallScreen ? 6 : 8),
                    GestureDetector(
                      onTap: onSpeak,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 8 : 10,
                          vertical: isSmallScreen ? 4 : 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.volume_up,
                              size: isSmallScreen ? 12 : 14,
                              color: const Color(0xFF10B981),
                            ),
                            SizedBox(width: isSmallScreen ? 4 : 6),
                            Text(
                              'Listen',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 11 : 12,
                                color: const Color(0xFF10B981),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            SizedBox(width: isSmallScreen ? 6 : 8),
            CircleAvatar(
              backgroundColor: Colors.grey.shade300,
              radius: isSmallScreen ? 14 : 16,
              child: Icon(
                Icons.person,
                color: Colors.grey.shade700,
                size: isSmallScreen ? 16 : 18,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

