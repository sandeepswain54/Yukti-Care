// voice_ai_chat.dart
import 'package:flutter/material.dart';
import 'package:service_app/Voice_AI/AI_Voice.dart';
import 'package:service_app/views/Host_Screens/booking.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:avatar_glow/avatar_glow.dart';

class VoiceAIChatPage extends StatefulWidget {
  @override
  _VoiceAIChatPageState createState() => _VoiceAIChatPageState();
}

class _VoiceAIChatPageState extends State<VoiceAIChatPage> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  
  bool _isListening = false;
  bool _speechAvailable = false;
  String _text = '';
  String _currentLanguage = 'en-US';
  List<ChatMessage> _messages = [];
  
  int _currentStep = 0;
  String _userName = '';
  
  final Map<String, String> _languages = {
    'English': 'en-US',
    'Hindi': 'hi-IN',
    'Odia': 'or-IN',
  };

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  void _initializeApp() async {
    _initSpeechRecognition();
    _initTTS();
    Future.delayed(Duration(seconds: 1), () {
      _startConversation();
    });
  }

  void _initSpeechRecognition() async {
    try {
      print("🔄 Initializing speech recognition...");
      
      bool hasSpeech = false;
      try {
        hasSpeech = await _speech.initialize(
          onStatus: (status) {
            print('📱 Speech Status: $status');
            if (mounted) {
              if (status == 'notListening') {
                setState(() => _isListening = false);
              }
            }
          },
          onError: (error) {
            print('❌ Speech Error: $error');
            if (mounted) {
              setState(() => _isListening = false);
            }
          },
        );
      } on Exception catch (e) {
        print("⚠️ Speech initialization failed: $e");
        hasSpeech = false;
      }

      if (mounted) {
        setState(() {
          _speechAvailable = hasSpeech;
        });
      }
    } catch (e) {
      print("❌ Critical error initializing speech: $e");
      if (mounted) {
        setState(() => _speechAvailable = false);
      }
    }
  }

  void _initTTS() async {
    try {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setVolume(1.0);
    } catch (e) {
      print("Error initializing TTS: $e");
    }
  }

  void _startConversation() async {
    if (_currentStep == 0) {
      String greeting = _getGreeting();
      _addMessage(greeting, false);
      await _speak(greeting);
    }
  }

  String _getGreeting() {
    switch (_currentLanguage) {
      case 'hi-IN':
        return 'नमस्ते! मैं सान्वी हूं और मैं महिला स्वास्थ्य के बारे में बात करना चाहती हूं। आपका क्या नाम है?';
      case 'or-IN':
        return 'ନମସ୍କାର! ମୁଁ ଆପଣଙ୍କର ବନ୍ଧୁ ଏବଂ ମୁଁ ମହିଳା ସ୍ୱାସ୍ଥ୍ୟ ବିଷୟରେ କଥା ହେବାକୁ ଚାହୁଁଛି। ଆପଣଙ୍କର ନାମ କଣ?';
      default:
        return 'Hello! I\'m Saanvi and I\'d like to talk about women\'s health. What\'s your name?';
    }
  }

  void _listen() async {
    if (_isListening) {
      _stopListening();
      return;
    }

    if (!_speechAvailable) {
      await _requestSpeechPermission();
      return;
    }

    await _startListening();
  }

  void _stopListening() {
    setState(() => _isListening = false);
    _speech.stop();
  }

  Future<void> _requestSpeechPermission() async {
    try {
      bool hasSpeech = await _speech.initialize(
        debugLogging: false,
        onStatus: (status) => print('📱 Speech Status: $status'),
        onError: (error) => print('❌ Speech Error: $error'),
      );
      
      if (hasSpeech && mounted) {
        setState(() => _speechAvailable = true);
        await _startListening();
      } else {
        _showPermissionDeniedMessage();
      }
    } catch (e) {
      _showErrorMessage('Error: ${e.toString()}');
    }
  }

  Future<void> _startListening() async {
    try {
      if (!_speechAvailable) {
        await _requestSpeechPermission();
        return;
      }

      if (_isListening) return;

      if (mounted) {
        setState(() {
          _isListening = true;
          _text = '';
        });
      }

      await _speech.listen(
        onResult: (result) {
          if (mounted) {
            setState(() {
              _text = result.recognizedWords;
            });
          }
          
          if (result.finalResult) {
            _processSpeech(result.recognizedWords);
            if (mounted) {
              setState(() => _isListening = false);
            }
          }
        },
        listenFor: Duration(seconds: 30),
        pauseFor: Duration(seconds: 5),
        localeId: _currentLanguage,
        cancelOnError: true,
        partialResults: true,
      );
      
    } catch (e) {
      if (mounted) {
        setState(() => _isListening = false);
      }
      _showErrorMessage('Failed to start listening: ${e.toString()}');
    }
  }

  void _processSpeech(String text) {
    _addMessage(text, true);
    
    switch (_currentStep) {
      case 0:
        _processName(text);
        break;
      case 1:
        _processAge(text);
        break;
      case 2:
        _processHealthInterest(text);
        break;
      case 3:
        _processPeriodExperience(text);
        break;
      case 4:
        _processCostAwareness(text);
        break;
      case 5:
        _processEcoInterest(text);
        break;
      case 6:
        _processFinalInfo(text);
        break;
      default:
        _processGeneralResponse(text);
    }
  }

  void _processName(String text) {
    String name = _extractName(text);
    if (name.isNotEmpty) {
      _userName = name;
      _currentStep = 1;
      
      String response = _getNameResponse(name);
      _addMessage(response, false);
      _speak(response);
    } else {
      String response = _getNoNameResponse();
      _addMessage(response, false);
      _speak(response);
    }
  }

  String _getNameResponse(String name) {
    switch (_currentLanguage) {
      case 'hi-IN':
        return 'बहुत खूब $name! आपसे मिलकर बहुत खुशी हुई। क्या आप मुझे अपनी उम्र बता सकती हैं ताकि मैं आपको बेहतर जानकारी दे सकूं?';
      case 'or-IN':
        return 'ବହୁତ ଭଲ $name! ଆପଣଙ୍କୁ ଦେଖି ବହୁତ ଖୁସି ହେଲା। ଆପଣ ମୋତେ ଆପଣଙ୍କର ବୟସ କହିପାରିବେ କି ଯେଉଁଥିରେ ମୁଁ ଆପଣଙ୍କୁ ଭଲ ତଥ୍ୟ ଦେଇପାରିବି?';
      default:
        return 'Lovely $name! It\'s wonderful to meet you. Could you tell me your age so I can provide you with more relevant information?';
    }
  }

  String _getNoNameResponse() {
    switch (_currentLanguage) {
      case 'hi-IN':
        return 'मुझे आपका नाम समझ नहीं आया। क्या आप कृपया अपना नाम फिर से बता सकती हैं?';
      case 'or-IN':
        return 'ମୁଁ ଆପଣଙ୍କର ନାମ ବୁଝିପାରିଲି ନାହିଁ। ଆପଣ ଦୟାକରି ଆପଣଙ୍କର ନାମ ପୁଣି କହିପାରିବେ କି?';
      default:
        return 'I didn\'t quite catch your name. Could you please say it again?';
    }
  }

  void _processAge(String text) {
    // Simple age extraction
    int? age = _extractAge(text);
    _currentStep = 2;
    
    String response = _getAgeResponse(age);
    _addMessage(response, false);
    _speak(response);
  }

  int? _extractAge(String text) {
    try {
      // Look for numbers in the text
      RegExp regExp = RegExp(r'\b(\d{1,2})\b');
      var matches = regExp.allMatches(text);
      if (matches.isNotEmpty) {
        return int.tryParse(matches.first.group(1)!);
      }
    } catch (e) {
      print("Error extracting age: $e");
    }
    return null;
  }

  String _getAgeResponse(int? age) {
    String ageText = age != null ? age.toString() : '';
    
    switch (_currentLanguage) {
      case 'hi-IN':
        return 'धन्यवाद! $ageText साल एक बहुत अच्छी उम्र है। क्या आप महिला स्वास्थ्य और मासिक धर्म प्रबंधन के बारे में जानने में रुचि रखती हैं?';
      case 'or-IN':
        return 'ଧନ୍ୟବାଦ! $ageText ବର୍ଷ ଏକ ବହୁତ ଭଲ ବୟସ ଅଟେ। ଆପଣ ମହିଳା ସ୍ୱାସ୍ଥ୍ୟ ଏବଂ ଋତୁସ୍ରାବ ପରିଚାଳନା ବିଷୟରେ ଜାଣିବାକୁ ଚାହୁଁଛନ୍ତି କି?';
      default:
        return 'Thank you! $ageText years is a wonderful age. Are you interested in learning more about women\'s health and menstrual management?';
    }
  }

  void _processHealthInterest(String text) {
    bool isInterested = text.toLowerCase().contains('yes') ||
        text.toLowerCase().contains('yeah') ||
        text.toLowerCase().contains('sure') ||
        text.toLowerCase().contains('ok') ||
        text.toLowerCase().contains('हाँ') ||
        text.toLowerCase().contains('हां') ||
        text.toLowerCase().contains('ହଁ') ||
        text.toLowerCase().contains('ହାଁ') ||
        text.toLowerCase().contains('interested');

    _currentStep = 3;
    
    String response = isInterested 
        ? _getPositiveHealthResponse()
        : _getNeutralHealthResponse();
    
    _addMessage(response, false);
    _speak(response);
  }

  String _getPositiveHealthResponse() {
    switch (_currentLanguage) {
      case 'hi-IN':
        return 'यह बहुत अच्छी बात है! मासिक धर्म प्रबंधन हर महिला के जीवन का एक महत्वपूर्ण हिस्सा है। क्या आप मुझे अपने मासिक धर्म के अनुभव के बारे में बता सकती हैं? क्या आपको कोई चुनौतियाँ हैं?';
      case 'or-IN':
        return 'ଏହା ବହୁତ ଭଲ ଖବର! ଋତୁସ୍ରାବ ପରିଚାଳନା ପ୍ରତ୍ୟେକ ମହିଳାଙ୍କ ଜୀବନର ଏକ ଗୁରୁତ୍ୱପୂର୍ଣ୍ଣ ଅଂଶ ଅଟେ। ଆପଣ ମୋତେ ଆପଣଙ୍କର ଋତୁସ୍ରାବ ଅନୁଭୂତି ବିଷୟରେ କହିପାରିବେ କି? ଆପଣଙ୍କୁ କିଛି ଚାଲେଞ୍ଜ ଅନୁଭବ ହୁଏ କି?';
      default:
        return 'That\'s wonderful to hear! Menstrual management is an important part of every woman\'s life. Could you share with me about your menstrual experience? Do you face any challenges?';
    }
  }

  String _getNeutralHealthResponse() {
    switch (_currentLanguage) {
      case 'hi-IN':
        return 'कोई बात नहीं! फिर भी, मैं एक महत्वपूर्ण जानकारी साझा करना चाहूंगी जो कई महिलाओं की मदद कर रही है। क्या आप जानती हैं कि मासिक धर्म उत्पादों पर हम कितना पैसा खर्च करते हैं?';
      case 'or-IN':
        return 'କିଛି ଅସୁବିଧା ନାହିଁ! ତଥାପି, ମୁଁ ଏକ ଗୁରୁତ୍ୱପୂର୍ଣ୍ଣ ତଥ୍ୟ ଶେୟାର କରିବାକୁ ଚାହୁଁଛି ଯାହା ଅନେକ ମହିଳାଙ୍କୁ ସାହାଯ୍ୟ କରୁଛି। ଆପଣ ଜାଣନ୍ତି କି ଆମେ ଋତୁସ୍ରାବ ଉତ୍ପାଦ ପାଇଁ କେତେ ଟଙ୍କା ଖର୍ଚ୍ଚ କରୁ?';
      default:
        return 'No problem at all! Still, I\'d like to share an important insight that\'s helping many women. Did you know how much money we spend on menstrual products?';
    }
  }

  void _processPeriodExperience(String text) {
    _currentStep = 4;
    String response = _getCostAwarenessQuestion();
    _addMessage(response, false);
    _speak(response);
  }

  String _getCostAwarenessQuestion() {
    switch (_currentLanguage) {
      case 'hi-IN':
        return 'आपके अनुभव के लिए धन्यवाद! अब एक दिलचस्प तथ्य की ओर आते हैं। क्या आपने कभी गणना की है कि आप अपने पूरे जीवन में मासिक धर्म उत्पादों पर कितना पैसा खर्च करती हैं?';
      case 'or-IN':
        return 'ଆପଣଙ୍କର ଅନୁଭୂତି ପାଇଁ ଧନ୍ୟବାଦ! ଏବେ ଏକ ମଜାଦାର ତଥ୍ୟ ଆଡକୁ ଚାଲନ୍ତୁ। ଆପଣ କଭି ଗଣନା କରିଛନ୍ତି କି ଆପଣ ଆପଣଙ୍କର ସମ୍ପୂର୍ଣ୍ଣ ଜୀବନରେ ଋତୁସ୍ରାବ ଉତ୍ପାଦ ପାଇଁ କେତେ ଟଙ୍କା ଖର୍ଚ୍ଚ କରନ୍ତି?';
      default:
        return 'Thank you for sharing your experience! Now let\'s talk about an interesting fact. Have you ever calculated how much money you spend on menstrual products throughout your life?';
    }
  }

  void _processCostAwareness(String text) {
    _currentStep = 5;
    String response = _getCostRevelation();
    _addMessage(response, false);
    _speak(response);
  }

  String _getCostRevelation() {
    switch (_currentLanguage) {
      case 'hi-IN':
        return 'यह जानकर आपको आश्चर्य होगा! एक औसत महिला अपने जीवनकाल में डिस्पोजेबल पैड्स पर लगभग 50,000 से 70,000 रुपये खर्च करती है। यह एक छोटी कार खरीदने जितना है!';
      case 'or-IN':
        return 'ଏହା ଜାଣି ଆପଣ ଆଶ୍ଚର୍ଯ୍ୟ ହୋଇଯିବେ! ଜଣେ ସାଧାରଣ ମହିଳା ତାଙ୍କର ସାରା ଜୀବନରେ ଡିସ୍ପୋଜାବଲ୍ ପ୍ୟାଡ୍ ପାଇଁ ପ୍ରାୟ 50,000 ରୁ 70,000 ଟଙ୍କା ଖର୍ଚ୍ଚ କରନ୍ତି। ଏହା ଏକ ଛୋଟ କାର କିଣିବା ପରି ଅଟେ!';
      default:
        return 'You\'ll be surprised to know this! An average woman spends approximately ₹50,000 to ₹70,000 on disposable pads throughout her lifetime. That\'s like buying a small car!';
    }
  }

  void _processEcoInterest(String text) {
    _currentStep = 6;
    String response = _getEcoQuestion();
    _addMessage(response, false);
    _speak(response);
  }

  String _getEcoQuestion() {
    switch (_currentLanguage) {
      case 'hi-IN':
        return 'और यह सिर्फ पैसे की बात नहीं है। क्या आप पर्यावरण के प्रति conscious हैं? क्या आप जानती हैं कि डिस्पोजेबल पैड्स पर्यावरण को कितना नुकसान पहुंचाते हैं?';
      case 'or-IN':
        return 'ଏବଂ ଏହା କେବଳ ଟଙ୍କାର କଥା ନୁହେଁ। ଆପଣ ପରିବେଶ ପ୍ରତି ସଚେତନ ଅଛନ୍ତି କି? ଆପଣ ଜାଣନ୍ତି କି ଡିସ୍ପୋଜାବଲ୍ ପ୍ୟାଡ୍ ପରିବେଶକୁ କେତେ କ୍ଷତି କରେ?';
      default:
        return 'And it\'s not just about money. Are you environmentally conscious? Do you know how much disposable pads harm our environment?';
    }
  }

  void _processFinalInfo(String text) {
    bool isEcoFriendly = text.toLowerCase().contains('yes') ||
        text.toLowerCase().contains('हाँ') ||
        text.toLowerCase().contains('ହଁ') ||
        text.toLowerCase().contains('environment') ||
        text.toLowerCase().contains('पर्यावरण') ||
        text.toLowerCase().contains('ପରିବେଶ');

    _currentStep = 7;
    
    String response = isEcoFriendly 
        ? _getEcoFriendlySolution()
        : _getFinancialSolution();
    
    _addMessage(response, false);
    _speak(response);
  }

  String _getEcoFriendlySolution() {
    switch (_currentLanguage) {
      case 'hi-IN':
        return 'तो मैं आपके लिए एक बेहतरीन समाधान लेकर आई हूं! पीरियड पैंटीज़:\n\n💰 आर्थिक: 3 साल में डिस्पोज़ेबल पैड पर ₹6500, पीरियड पैंटी पर सिर्फ ₹1800!\n💰 बचत: ₹4600 की सीधी बचत\n🌱 पर्यावरण: शून्य कचरा, शून्य चिंता\n\nस्मार्ट बनो, सेफ़ चुनो, रीयूज़ेबल अपनाओ। यह आपके लिए, आपके बटुए के लिए और हमारे ग्रह के लिए बेहतर है!';
      
      case 'or-IN':
        return 'ତେବେ ମୁଁ ଆପଣଙ୍କ ପାଇଁ ଏକ ଚମତ୍କାର ସମାଧାନ ନେଇ ଆସିଛି! ପିରିଅଡ୍ ପ୍ୟାଣ୍ଟି:\n\n💰 ଆର୍ଥିକ: 3 ବର୍ଷରେ ଡିସପୋଜାବଲ୍ ପ୍ୟାଡ୍ ପାଇଁ ₹6500, ପିରିଅଡ୍ ପ୍ୟାଣ୍ଟି ପାଇଁ କେବଳ ₹1800!\n💰 ସଉକ: ଏକଦମ୍ ₹4600 ବଞ୍ଚତ\n🌱 ପରିବେଶ: କଚରା ଶୂନ୍ୟ, ଚିନ୍ତା ଶୂନ୍ୟ\n\nସ୍ମାର୍ଟ ଚଏସ୍, ସେଫ୍ ଚଏସ୍, ରିଉଜେବଲ୍ ଚଏସ୍। ଏହା ଆପଣଙ୍କ ପାଇଁ, ଆପଣଙ୍କ ପର୍ସ ପାଇଁ ଏବଂ ଆମ ଗ୍ରହ ପାଇଁ ଭଲ!';
      
      default:
        return 'Then I have an amazing solution for you! Period Panties:\n\n💰 Economic: Using disposable pads for 3 years costs around ₹6500. But using period panties for the same time costs only ₹1800!\n💰 Savings: That means you save ₹4600\n🌱 Environment: Plus zero waste, zero worry\n\nSmart choice. Safe choice. Reusable choice. It\'s better for you, your wallet, and our planet!';
    }
  }

  String _getFinancialSolution() {
    switch (_currentLanguage) {
      case 'hi-IN':
        return 'चलिए मैं आपको एक समझदार विकल्प दिखाती हूं! पीरियड पैंटीज़:\n\n💰 3 साल में डिस्पोज़ेबल पैड: ₹6500\n💰 3 साल में पीरियड पैंटी: सिर्फ ₹1800\n💰 आपकी बचत: ₹4600!\n\nयह सिर्फ पैसे की बचत नहीं, बल्कि आराम, सुरक्षा और पर्यावरण संरक्षण भी है। स्मार्ट बनो, सेफ़ चुनो, रीयूज़ेबल अपनाओ!';
      
      case 'or-IN':
        return 'ଚାଲନ୍ତୁ ମୁଁ ଆପଣଙ୍କୁ ଏକ ସମଝଦାର ବିକଳ୍ପ ଦେଖାଉଛି! ପିରିଅଡ୍ ପ୍ୟାଣ୍ଟି:\n\n💰 3 ବର୍ଷରେ ଡିସପୋଜାବଲ୍ ପ୍ୟାଡ୍: ₹6500\n💰 3 ବର୍ଷରେ ପିରିଅଡ୍ ପ୍ୟାଣ୍ଟି: କେବଳ ₹1800\n💰 ଆପଣଙ୍କର ସଉକ: ₹4600!\n\nଏହା କେବଳ ଟଙ୍କା ବଞ୍ଚତ ନୁହେଁ, ବରଂ ଆରାମ, ସୁରକ୍ଷା ଏବଂ ପରିବେଶ ସଂରକ୍ଷଣ ମଧ୍ୟ ଅଟେ। ସ୍ମାର୍ଟ ଚଏସ୍, ସେଫ୍ ଚଏସ୍, ରିଉଜେବଲ୍ ଚଏସ୍!';
      
      default:
        return 'Let me show you a smart alternative! Period Panties:\n\n💰 3 years of disposable pads: ₹6500\n💰 3 years of period panties: Only ₹1800\n💰 Your savings: ₹4600!\n\nIt\'s not just about saving money, but also about comfort, safety, and environmental protection. Smart choice. Safe choice. Reusable choice!';
    }
  }

  void _processGeneralResponse(String text) {
    String response = _getGeneralResponse();
    _addMessage(response, false);
    _speak(response);
  }

  String _getGeneralResponse() {
    switch (_currentLanguage) {
      case 'hi-IN':
        return 'मुझे आपसे बात करके बहुत खुशी हुई $_userName! यदि आपके कोई और प्रश्न हैं तो बताएं। याद रखें, आपकी सेहत और सुख आपके हाथ में है!';
      case 'or-IN':
        return 'ଆପଣଙ୍କ ସହିତ କଥା ହୋଇ ବହୁତ ଖୁସି ଲାଗିଲା $_userName! ଯଦି ଆପଣଙ୍କର ଆଉ କିଛି ପ୍ରଶ୍ନ ଅଛି ତେବେ ଜଣାନ୍ତୁ। ମନେରଖନ୍ତୁ, ଆପଣଙ୍କର ସ୍ୱାସ୍ଥ୍ୟ ଏବଂ ସୁଖ ଆପଣଙ୍କ ହାତରେ ଅଛି!';
      default:
        return 'It was wonderful talking with you $_userName! If you have any more questions, feel free to ask. Remember, your health and happiness are in your hands!';
    }
  }

  String _extractName(String text) {
    text = text.toLowerCase();
    if (text.contains('my name is')) {
      return text.split('my name is').last.trim();
    } else if (text.contains('i am')) {
      return text.split('i am').last.trim();
    } else if (text.contains('मेरा नाम')) {
      return text.split('मेरा नाम').last.trim();
    } else if (text.contains('मैं')) {
      return text.split('मैं').last.trim();
    } else if (text.contains('ମୋର ନାମ')) {
      return text.split('ମୋର ନାମ').last.trim();
    } else if (text.contains('ମୁଁ')) {
      return text.split('ମୁଁ').last.trim();
    }
    return text;
  }

  Future<void> _speak(String text) async {
    try {
      String ttsLanguage = _currentLanguage;
      await _flutterTts.setLanguage(ttsLanguage);
      await _flutterTts.speak(text);
    } catch (e) {
      try {
        await _flutterTts.setLanguage('en-US');
        await _flutterTts.speak(text);
      } catch (e2) {
        print("Error in TTS fallback: $e2");
      }
    }
  }

  void _addMessage(String text, bool isUser) {
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: isUser));
    });
  }

  void _changeLanguage(String language) {
    setState(() {
      _currentLanguage = _languages[language]!;
    });
    
    _messages.clear();
    _currentStep = 0;
    _userName = '';
    _startConversation();
  }

  void _resetConversation() {
    setState(() {
      _messages.clear();
      _currentStep = 0;
      _userName = '';
      _text = '';
    });
    _startConversation();
  }

  void _showPermissionDeniedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Microphone permission is required for speech recognition'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => Booking()),
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
       
        title: Text(
          'सान्वी👩 AI Agent',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF4A90E2),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: _changeLanguage,
            itemBuilder: (BuildContext context) {
              return _languages.keys.map((String language) {
                return PopupMenuItem<String>(
                  value: language,
                  child: Text(language),
                );
              }).toList();
            },
            icon: Icon(Icons.language, color: Colors.white),
          ),
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.white),
              onPressed:_resetConversation,
            ),
          ],
        ),
        body: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Column(
                children: [
                  // Status Indicator
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    color: _speechAvailable ? Colors.green[50] : Colors.orange[50],
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _speechAvailable ? Icons.check_circle : Icons.warning,
                          color: _speechAvailable ? Colors.green : Colors.orange,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Text(
                          _speechAvailable 
                              ? 'Ready to talk'
                              : 'Microphone permission required',
                          style: TextStyle(
                            color: _speechAvailable ? Colors.green : Colors.orange,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Language Indicator
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 8),
                    color: Colors.grey[50],
                    child: Text(
                      _getLanguageDisplayText(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ),
                  
                  // Chat Messages
                  Expanded(
                    child: _messages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.health_and_safety,
                                  size: 64,
                                  color: Colors.grey[300],
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Let\'s talk about women\'s health',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Press the microphone to start',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.only(
    left: 16,
    right: 16,
    top: 16,
    bottom: 80, // Add bottom padding to avoid overlap with FAB
  ),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              return ChatBubble(
                                message: _messages[index].text,
                                isUser: _messages[index].isUser,
                              );
                            },
                          ),
                  ),
                  
                  // Listening Indicator
                  if (_isListening)
                    Container(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            "Listening...",
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                        ],
                      ),
                    ),
                  
                  // Current Speech Text
                  if (_text.isNotEmpty)
                    Container(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        _text,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
              // FAB positioned absolutely to stay above nav bar
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: AvatarGlow(
                    animate: _isListening,
                    glowColor: _speechAvailable ? Color(0xFF4A90E2) : Colors.orange,
                    duration: Duration(milliseconds: 2000),
                    repeat: true,
                    child: FloatingActionButton(
                      onPressed: _listen,
                      child: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: Colors.white,
                        size: 30,
                      ),
                      backgroundColor: _isListening 
                          ? Colors.red 
                          : (_speechAvailable ? Color(0xFF4A90E2) : Colors.orange),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getLanguageDisplayText() {
    switch (_currentLanguage) {
      case 'hi-IN':
        return 'Language: Hindi - महिला स्वास्थ्य सहायक';
      case 'or-IN':
        return 'Language: Odia - ମହିଳା ସ୍ୱାସ୍ଥ୍ୟ ସହାୟକ';
      default:
        return 'Language: English - Women Health Assistant';
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _flutterTts.stop();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;

  const ChatBubble({Key? key, required this.message, required this.isUser}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser)
            Container(
              margin: EdgeInsets.only(right: 8),
              child: CircleAvatar(
                 backgroundColor: Colors.transparent,
        backgroundImage: NetworkImage('https://img.freepik.com/premium-photo/confident-healthcare-worker-posed_1009902-45353.jpg'),
                radius: 16,
              ),
            ),
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? Color(0xFF4A90E2) : Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                message,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}