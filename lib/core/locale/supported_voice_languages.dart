/// VisionBridge — Supported Voice Languages Registry
///
/// Single source of truth for the app's VOICE-LAYER languages: everything the
/// user HEARS (TTS voice, AI scene descriptions, OCR read-aloud, voice
/// commands) supports these languages.
///
/// NOTE: The visual UI intentionally supports only English + Hindi (inline
/// `isHindi ? ... : ...` strings across screens). Do NOT add a UI locale here —
/// a third UI language requires a full ARB migration of every screen first.
///
/// Designed & Implemented by Shreesh Nalawade | SN09092005
library;

class VBLanguage {
  const VBLanguage({
    required this.code,
    required this.nativeName,
    required this.englishName,
    required this.ttsTag,
    required this.scriptFlag,
    this.aiPromptLanguage,
    this.voiceKeywords = const {},
  });

  /// Storage / locale-provider code ('en', 'hi', 'mr', ...).
  final String code;

  /// Name shown in the language picker, written in the language itself.
  final String nativeName;

  /// English name, used in semantics and TTS confirmations.
  final String englishName;

  /// BCP-47 tag for TTS (flutter_tts) and STT (speech_to_text) engines.
  final String ttsTag;

  /// Script classification used by OCR read-aloud language detection.
  final VoiceScript scriptFlag;

  /// Language name passed to vision LLMs in prompts (e.g. "Hindi", "Marathi").
  /// Falls back to [englishName] when null.
  final String? aiPromptLanguage;

  /// Voice-command keywords in this language (lowercase, already normalized).
  /// Values map to command keys understood by TTSSTTService._parseCommand.
  final Map<String, List<String>> voiceKeywords;

  String get promptLanguage => aiPromptLanguage ?? englishName;

  /// On-device fallback sentence when objects were detected, in this language.
  /// [labels] are already-localized object words (see _hiLabels dictionary).
  String fallbackWithObjects(List<String> labels) {
    final String objects = labels.join(', ');
    switch (code) {
      case 'hi':
        return 'मुझे सामने $objects दिख रहा है। अधिक जानने के लिए दोबारा दृश्य बताएँ बटन दबाएँ, या मदद के लिए कॉल करें।';
      case 'mr':
        return 'मला समोर $objects दिसत आहे. अधिक जाणून घेण्यासाठी पुन्हा दृश्य सांगा बटण दाबा, किंवा मदतीसाठी कॉल करा.';
      case 'ta':
        return 'எனக்கு முன்னால் $objects தெரிகிறது. மேலும் அறிய மீண்டும் காட்சி விவரி பொத்தானை அழுத்துங்கள், அல்லது உதவிக்கு அழையுங்கள்.';
      case 'te':
        return 'నాకు ముందు $objects కనిపిస్తున్నాయి. మరింత తెలుసుకోవడానికి మళ్లీ దృశ్య వివరణ బటన్ నొక్కండి, లేదా సహాయం కోసం కాల్ చేయండి.';
      case 'bn':
        return 'আমার সামনে $objects দেখা যাচ্ছে। আরও জানতে আবার দৃশ্য বলুন বোতাম চাপুন, বা সাহায্যের জন্য কল করুন।';
      case 'kn':
        return 'ನನಗೆ ಮುಂದೆ $objects ಕಾಣಿಸುತ್ತಿವೆ. ಇನ್ನಷ್ಟು ತಿಳಿಯಲು ಮತ್ತೆ ದೃಶ್ಯ ವಿವರಿಸು ಬಟನ್ ಒತ್ತಿರಿ, ಅಥವಾ ಸಹಾಯಕ್ಕೆ ಕರೆ ಮಾಡಿ.';
      default:
        return 'I see $objects ahead. If you want to know anything else, tap on the Describe button again or call for help.';
    }
  }

  /// On-device fallback sentence when nothing recognizable was detected.
  String fallbackNoObjects() {
    switch (code) {
      case 'hi':
        return 'मुझे सामने कुछ वस्तुएँ दिख रही हैं। अधिक जानने के लिए दोबारा दृश्य बताएँ बटन दबाएँ, या मदद के लिए कॉल करें।';
      case 'mr':
        return 'मला समोर काही वस्तू दिसत आहेत. अधिक जाणून घेण्यासाठी पुन्हा दृश्य सांगा बटण दाबा, किंवा मदतीसाठी कॉल करा.';
      case 'ta':
        return 'எனக்கு முன்னால் சில பொருள்கள் தெரிகின்றன. மேலும் அறிய மீண்டும் காட்சி விவரி பொத்தானை அழுத்துங்கள், அல்லது உதவிக்கு அழையுங்கள்.';
      case 'te':
        return 'నాకు ముందు కొన్ని వస్తువులు కనిపిస్తున్నాయి. మరింత తెలుసుకోవడానికి మళ్లీ దృశ్య వివరణ బటన్ నొక్కండి, లేదా సహాయం కోసం కాల్ చేయండి.';
      case 'bn':
        return 'আমার সামনে কিছু বস্তু দেখা যাচ্ছে। আরও জানতে আবার দৃশ্য বলুন বোতাম চাপুন, বা সাহায্যের জন্য কল করুন।';
      case 'kn':
        return 'ನನಗೆ ಮುಂದೆ ಕೆಲವು ವಸ್ತುಗಳು ಕಾಣಿಸುತ್ತಿವೆ. ಇನ್ನಷ್ಟು ತಿಳಿಯಲು ಮತ್ತೆ ದೃಶ್ಯ ವಿವರಿಸು ಬಟನ್ ಒತ್ತಿರಿ, ಅಥವಾ ಸಹಾಯಕ್ಕೆ ಕರೆ ಮಾಡಿ.';
      default:
        return 'I can see some objects ahead. If you want to know anything else, tap on the Describe button again or call for help.';
    }
  }

  /// User-friendly "AI busy" error in this language.
  String errorBusy() {
    switch (code) {
      case 'hi':
        return 'AI विज़न मॉडल अभी व्यस्त हैं। कृपया कुछ क्षण बाद पुनः प्रयास करें।';
      case 'mr':
        return 'AI व्हिजन मॉडेल्स सध्या व्यस्त आहेत. कृपया थोड्या वेळाने पुन्हा प्रयत्न करा.';
      case 'ta':
        return 'AI விஷன் மாடல்கள் தற்போது பணிமிகுதியில் உள்ளன. சற்று நேரம் கழித்து மீண்டும் முயற்சிக்கவும்.';
      case 'te':
        return 'AI విజన్ మోడళ్లు ప్రస్తుతం బిజీగా ఉన్నాయి. దయచేసి కొంత సేపటి తర్వాత మళ్లీ ప్రయత్నించండి.';
      case 'bn':
        return 'AI ভিশন মডেলগুলি এই মুহূর্তে ব্যস্ত। কিছুক্ষণ পরে আবার চেষ্টা করুন।';
      case 'kn':
        return 'AI ವಿಷನ್ ಮಾಡೆಲ್‌ಗಳು ಈಗ ಕಾರ್ಯನಿರತವಾಗಿವೆ. ದಯವಿಟ್ಟು ಸ್ವಲ್ಪ ಸಮಯದ ನಂತರ ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.';
      default:
        return 'AI vision models are currently busy. Please try again in a moment.';
    }
  }

  /// User-friendly rate-limit error in this language.
  String errorRateLimit() {
    switch (code) {
      case 'hi':
        return 'AI विज़न मॉडल की अस्थायी सीमा पूरी हो गई। कृपया कुछ सेकंड प्रतीक्षा करें और पुनः प्रयास करें।';
      case 'mr':
        return 'AI व्हिजन मॉडेल्सची तात्पुरती मर्यादा संपली. कृपया काही सेकंद थांबा आणि पुन्हा प्रयत्न करा.';
      case 'ta':
        return 'AI விஷன் மாடல்களின் தற்காலிக வரம்பு முடிந்தது. சில விநாடிகள் காத்திருந்து மீண்டும் முயற்சிக்கவும்.';
      case 'te':
        return 'AI విజన్ మోడళ్ల తాత్కాలిక పరిమితి ముగిసింది. దయచేసి కొన్ని సెకన్లు వేచి ఉండి మళ్లీ ప్రయత్నించండి.';
      case 'bn':
        return 'AI ভিশন মডেলের সাময়িক সীমা শেষ হয়ে গেছে। কয়েক সেকেন্ড অপেক্ষা করে আবার চেষ্টা করুন।';
      case 'kn':
        return 'AI ವಿಷನ್ ಮಾಡೆಲ್‌ಗಳ ತಾತ್ಕಾಲಿಕ ಮಿತಿ ಮುಗಿದಿದೆ. ದಯವಿಟ್ಟು ಕೆಲವು ಸೆಕೆಂಡುಗಳು ಕಾಯಿರಿ ಮತ್ತು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.';
      default:
        return 'AI vision models reached a temporary limit. Please wait a few seconds and try again.';
    }
  }

  /// Sentence used when a model response cleans down to nothing.
  String emptyDescription() {
    switch (code) {
      case 'hi':
        return 'कोई विवरण उपलब्ध नहीं है।';
      case 'mr':
        return 'कोणतीही माहिती उपलब्ध नाही.';
      case 'ta':
        return 'எந்த விவரமும் கிடைக்கவில்லை.';
      case 'te':
        return 'ఏ వివరాలు అందుబాటులో లేవు.';
      case 'bn':
        return 'কোনো বিবরণ পাওয়া যায়নি।';
      case 'kn':
        return 'ಯಾವುದೇ ಮಾಹಿತಿ ಲಭ್ಯವಿಲ್ಲ.';
      default:
        return 'No description available.';
    }
  }

  /// Closing call-to-action appended to AI descriptions in this language.
  /// [current] is the cleaned model description; the CTA is only appended if
  /// a similar one is not already present.
  String withCallToAction(String current) {
    switch (code) {
      case 'hi':
        const cta = ' और कुछ जानना हो तो दोबारा दृश्य बताएँ बटन दबाएँ, या मदद के लिए कॉल करें।';
        if (current.contains('दृश्य बताएँ') || current.contains('कॉल करें')) {
          return current;
        }
        return '$current$cta';
      case 'mr':
        if (current.contains('दृश्य सांगा') || current.contains('कॉल करा')) return current;
        return '$current अधिक जाणून घेण्यासाठी पुन्हा दृश्य सांगा बटण दाबा, किंवा मदतीसाठी कॉल करा.';
      case 'ta':
        if (current.contains('காட்சி விவரி') || current.contains('அழையுங்கள்')) return current;
        return '$current மேலும் அறிய மீண்டும் காட்சி விவரி பொத்தானை அழுத்துங்கள், அல்லது உதவிக்கு அழையுங்கள்.';
      case 'te':
        if (current.contains('దృశ్య వివరణ') || current.contains('కాల్ చేయండి')) return current;
        return '$current మరింత తెలుసుకోవడానికి మళ్లీ దృశ్య వివరణ బటన్ నొక్కండి, లేదా సహాయం కోసం కాల్ చేయండి.';
      case 'bn':
        if (current.contains('দৃশ্য বলুন') || current.contains('কল করুন')) return current;
        return '$current আরও জানতে আবার দৃশ্য বলুন বোতাম চাপুন, বা সাহায্যের জন্য কল করুন।';
      case 'kn':
        if (current.contains('ದೃಶ್ಯ ವಿವರಿಸು') || current.contains('ಕರೆ ಮಾಡಿ')) return current;
        return '$current ಇನ್ನಷ್ಟು ತಿಳಿಯಲು ಮತ್ತೆ ದೃಶ್ಯ ವಿವರಿಸು ಬಟನ್ ಒತ್ತಿರಿ, ಅಥವಾ ಸಹಾಯಕ್ಕೆ ಕರೆ ಮಾಡಿ.';
      default:
        const cta = ' If you want to know anything else, tap on the Describe button again or call for help.';
        if (current.contains('Describe button') || current.contains('call for help')) {
          return current;
        }
        return '$current$cta';
    }
  }
}

/// Script families relevant to OCR language detection.
enum VoiceScript { latin, devanagari, dravidian, bengali }

class VBLanguages {
  VBLanguages._();

  /// English — default.
  static const VBLanguage en = VBLanguage(
    code: 'en',
    nativeName: 'English',
    englishName: 'English',
    ttsTag: 'en-US',
    scriptFlag: VoiceScript.latin,
    aiPromptLanguage: 'English',
    voiceKeywords: {
      'emergency': ['emergency', 'sos', 'help me'],
      'help': ['help', "what's around", 'around me'],
      'describe': ['describe', 'what do you see', 'tell me'],
      'stop': ['stop', 'quiet', 'silence'],
      'call': ['call', 'volunteer'],
      'endCall': ['end call', 'hang up'],
      'yes': ['yes', 'yeah', 'confirm'],
      'no': ['no', 'cancel', 'nevermind'],
    },
  );

  /// Hindi — full UI + voice support.
  static const VBLanguage hi = VBLanguage(
    code: 'hi',
    nativeName: 'हिन्दी',
    englishName: 'Hindi',
    ttsTag: 'hi-IN',
    scriptFlag: VoiceScript.devanagari,
    aiPromptLanguage: 'Hindi',
    voiceKeywords: {
      'emergency': ['आपातकाल', 'बचाओ', 'खतरा'],
      'help': ['मदद', 'आसपास'],
      'describe': ['बताओ', 'क्या दिख रहा'],
      'stop': ['रुको', 'शांत', 'बंद'],
      'call': ['कॉल', 'स्वयंसेवक'],
      'endCall': ['कॉल खत्म', 'रखो'],
      'yes': ['हाँ', 'हां'],
      'no': ['नहीं', 'ना'],
    },
  );

  /// Marathi — voice layer (Devanagari script; OCR reads it via the
  /// bundled Devanagari model; TTS uses mr-IN).
  static const VBLanguage mr = VBLanguage(
    code: 'mr',
    nativeName: 'मराठी',
    englishName: 'Marathi',
    ttsTag: 'mr-IN',
    scriptFlag: VoiceScript.devanagari,
    aiPromptLanguage: 'Marathi',
    voiceKeywords: {
      'emergency': ['मदत करा', 'धोका'],
      'help': ['मदत', 'जवळपास'],
      'describe': ['सांग', 'काय दिसतंय'],
      'stop': ['थांब', 'शांत'],
      'call': ['कॉल', 'स्वयंसेवक'],
      'yes': ['होय'],
      'no': ['नाही'],
    },
  );

  /// Tamil — voice layer.
  static const VBLanguage ta = VBLanguage(
    code: 'ta',
    nativeName: 'தமிழ்',
    englishName: 'Tamil',
    ttsTag: 'ta-IN',
    scriptFlag: VoiceScript.dravidian,
    aiPromptLanguage: 'Tamil',
    voiceKeywords: {
      'emergency': ['உதவி தேவை', 'ஆபத்து'],
      'help': ['உதவி'],
      'describe': ['சொல்', 'என்ன தெரிகிறது'],
      'stop': ['நிறுத்து', 'அமைதி'],
      'call': ['அழைப்பு'],
      'yes': ['ஆம்'],
      'no': ['இல்லை'],
    },
  );

  /// Telugu — voice layer.
  static const VBLanguage te = VBLanguage(
    code: 'te',
    nativeName: 'తెలుగు',
    englishName: 'Telugu',
    ttsTag: 'te-IN',
    scriptFlag: VoiceScript.dravidian,
    aiPromptLanguage: 'Telugu',
    voiceKeywords: {
      'emergency': ['సహాయం కావాలి', 'ప్రమాదం'],
      'help': ['సహాయం'],
      'describe': ['చెప్పు', 'ఏమి కనిపిస్తోంది'],
      'stop': ['ఆపు', 'నిశ్శబ్దం'],
      'call': ['కాల్'],
      'yes': ['అవును'],
      'no': ['లేదు'],
    },
  );

  /// Bengali — voice layer.
  static const VBLanguage bn = VBLanguage(
    code: 'bn',
    nativeName: 'বাংলা',
    englishName: 'Bengali',
    ttsTag: 'bn-IN',
    scriptFlag: VoiceScript.bengali,
    aiPromptLanguage: 'Bengali',
    voiceKeywords: {
      'emergency': ['বাঁচাও', 'বিপদ'],
      'help': ['সাহায্য'],
      'describe': ['বলো', 'কী দেখা যাচ্ছে'],
      'stop': ['থামো', 'শান্ত'],
      'call': ['কল'],
      'yes': ['হ্যাঁ'],
      'no': ['না'],
    },
  );

  /// Kannada — voice layer.
  static const VBLanguage kn = VBLanguage(
    code: 'kn',
    nativeName: 'ಕನ್ನಡ',
    englishName: 'Kannada',
    ttsTag: 'kn-IN',
    scriptFlag: VoiceScript.dravidian,
    aiPromptLanguage: 'Kannada',
    voiceKeywords: {
      'emergency': ['ರಕ್ಷಿಸಿ', 'ಅಪಾಯ'],
      'help': ['ಸಹಾಯ'],
      'describe': ['ಹೇಳು', 'ಏನು ಕಾಣಿಸುತ್ತಿದೆ'],
      'stop': ['ನಿಲ್ಲಿಸು', 'ಶಾಂತ'],
      'call': ['ಕರೆ'],
      'yes': ['ಹೌದು'],
      'no': ['ಇಲ್ಲ'],
    },
  );

  /// All languages offered in the voice-language picker (UI stays EN/HI).
  static const List<VBLanguage> all = [en, hi, mr, ta, te, bn, kn];

  /// UI locales — used by the Material `locale` only.
  static const List<String> uiLocaleCodes = ['en', 'hi'];

  /// Look up a language by storage code; unknown codes fall back to English.
  static VBLanguage byCode(String code) {
    for (final lang in all) {
      if (lang.code == code) return lang;
    }
    return en;
  }

  /// Classify a character rune into a script family for OCR detection.
  static VoiceScript scriptOfRune(int rune) {
    if (rune >= 0x0900 && rune <= 0x097F) return VoiceScript.devanagari;
    if (rune >= 0x0980 && rune <= 0x09FF) return VoiceScript.bengali;
    if (rune >= 0x0B80 && rune <= 0x0BFF) return VoiceScript.dravidian; // Tamil
    if (rune >= 0x0C00 && rune <= 0x0C7F) return VoiceScript.dravidian; // Telugu
    if (rune >= 0x0C80 && rune <= 0x0CFF) return VoiceScript.dravidian; // Kannada
    return VoiceScript.latin;
  }
}
