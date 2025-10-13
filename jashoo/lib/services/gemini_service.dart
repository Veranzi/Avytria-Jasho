import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/api_keys.dart';

/// Gemini AI Service for intelligent chatbot responses
/// 
/// Features:
/// - Natural language understanding in English and Swahili
/// - Context-aware responses about Jasho app features
/// - Voice-friendly responses
class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  late GenerativeModel _model;
  late ChatSession _chatSession;
  bool _isInitialized = false;

  /// Initialize Gemini AI with Jasho context
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _model = GenerativeModel(
        model: 'gemini-pro',
        apiKey: ApiKeys.geminiApiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 1024,
        ),
        safetySettings: [
          SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.medium),
        ],
      );

      // Initialize chat session with Jasho context
      _chatSession = _model.startChat(history: [
        Content.text(_getSystemPrompt()),
      ]);

      _isInitialized = true;
      print('✅ Gemini AI initialized successfully');
    } catch (e) {
      print('❌ Error initializing Gemini AI: $e');
      throw Exception('Failed to initialize Gemini AI: $e');
    }
  }

  /// Get system prompt with Jasho app context
  String _getSystemPrompt() {
    return '''
You are Jasho AI Assistant, a friendly and helpful AI chatbot for the Jasho financial services app.

About Jasho:
- Jasho is a financial inclusion platform for informal sector workers in Kenya
- Supports gig workers (Mama Mboga, Boda Boda riders, Mama Fua, etc.)
- Features: Digital Wallet, Savings, Insurance, Jobs Marketplace, Micro-loans, AI Insights

Key Features:
1. **Wallet**: KES, USDT, USD balances. Masked for security. Deposit, withdraw, transfer.
2. **Savings**: Two tiers - Standing Order (automatic) and Voluntary (manual). Set goals.
3. **Jobs/Gigs**: Post jobs, apply for gigs, rate employers (0-5 stars with comments).
4. **Insurance**: Health, Life, Accident, Property insurance.
5. **KYC**: Required for posting jobs. ID/Passport verification.
6. **AI Insights**: Spending analysis, predictions, personalized suggestions.
7. **Voice Navigation**: English & Swahili support with feminine Kenyan voice.
8. **Accessibility**: Full PWD support with voice commands.

Your role:
- Answer questions about Jasho features
- Help users navigate the app
- Provide financial advice for informal sector workers
- Speak in simple, clear language
- Support both English and Swahili (detect user's language)
- Be encouraging and supportive

Guidelines:
- Keep responses concise (2-3 sentences max for voice)
- Use Kenyan context and examples
- Mention specific feature names
- Direct users to relevant screens
- Be warm and friendly
''';
  }

  /// Send message and get AI response
  Future<String> sendMessage(String message, {String language = 'en'}) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Add language context if needed
      String contextualMessage = message;
      if (language == 'sw' && !message.contains('Swahili') && !message.contains('Kiswahili')) {
        contextualMessage = 'Please respond in Swahili (Kiswahili). User message: $message';
      }

      final response = await _chatSession.sendMessage(Content.text(contextualMessage));
      
      if (response.text != null && response.text!.isNotEmpty) {
        return response.text!;
      } else {
        return _getFallbackResponse(message, language);
      }
    } catch (e) {
      print('Error sending message to Gemini: $e');
      return _getFallbackResponse(message, language);
    }
  }

  /// Get fallback response if AI fails
  String _getFallbackResponse(String message, String language) {
    final isSwahili = language == 'sw';
    final lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('wallet') || lowerMessage.contains('mkoba')) {
      return isSwahili
          ? 'Mkoba wako una salio za KES, USDT, na USD. Unaweza kuweka pesa, kutoa pesa, na kubadilisha sarafu. Salio linafichwa kwa usalama - bonyeza ikoni ya jicho kuonyesha.'
          : 'Your wallet has KES, USDT, and USD balances. You can deposit, withdraw, and convert currencies. Balance is masked for security - tap the eye icon to reveal.';
    } else if (lowerMessage.contains('savings') || lowerMessage.contains('akiba')) {
      return isSwahili
          ? 'Jasho ina aina mbili za akiba: 1) Standing Order (kiotomatiki) - weka kiasi na mzunguko. 2) Voluntary (hiari) - hifadhi wakati wowote. Nenda Savings > Create Goal kuanza.'
          : 'Jasho has two savings types: 1) Standing Order (automatic) - set amount and frequency. 2) Voluntary - save anytime. Go to Savings > Create Goal to start.';
    } else if (lowerMessage.contains('jobs') || lowerMessage.contains('kazi')) {
      return isSwahili
          ? 'Kazi zinapatikana kwenye Jobs section. Unaweza kuomba kazi, kupata mawasiliano ya mpangaji, kukamilisha, kulipwa, na kutoa ukaguzi. Unaweza pia kuweka kazi lakini lazima KYC ifanywe kwanza.'
          : 'Jobs available in Jobs section. You can apply, get poster contact, complete, get paid, and review. You can also post jobs but KYC is required first.';
    } else if (lowerMessage.contains('help') || lowerMessage.contains('msaada')) {
      return isSwahili
          ? 'Nina hapa kukusaidia 24/7! Niulize kuhusu: Akiba, Kazi, Mkoba, Mikopo, Bima, KYC, AI Insights, QR Scan, Ukaguzi, Usalama, au chochote kingine!'
          : 'I\'m here to help 24/7! Ask me about: Savings, Jobs, Wallet, Loans, Insurance, KYC, AI Insights, QR Scan, Reviews, Security, or anything else!';
    } else {
      return isSwahili
          ? 'Nashukuru kuuliza! Naweza kukusaidia na maswali kuhusu Jasho. Niulize kuhusu: Mkoba, Akiba, Kazi, Bima, KYC, au vipengele vingine.'
          : 'Thanks for asking! I can help you with questions about Jasho. Ask me about: Wallet, Savings, Jobs, Insurance, KYC, or any other features.';
    }
  }

  /// Reset chat session (for new conversation)
  Future<void> resetChat() async {
    if (!_isInitialized) return;
    
    _chatSession = _model.startChat(history: [
      Content.text(_getSystemPrompt()),
    ]);
  }

  /// Check if Gemini is initialized
  bool get isInitialized => _isInitialized;
}


