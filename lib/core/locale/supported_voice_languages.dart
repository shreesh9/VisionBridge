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
    this.voiceStrings = const {},
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

  /// All spoken narration strings for this language. Every language must
  /// define every [VoiceKey] — narration never falls back to another
  /// language's text (an English string on an Indic voice sounds wrong).
  final VoiceStrings voiceStrings;

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

  /// Spoken confirmation when the AI persona (age group) changes.
  /// [group] is 'genZ', 'genAlpha' or 'adult'.
  String personaUpdated(String group) {
    switch (code) {
      case 'hi':
        switch (group) {
          case 'genZ':
            return 'AI वॉइस पर्सोना Gen Z अनौपचारिक शैली में बदला गया';
          case 'genAlpha':
            return 'AI वॉइस पर्सोना Gen Alpha ऊर्जावान शैली में बदला गया';
          default:
            return 'AI वॉइस पर्सोना सामान्य वयस्क शैली में बदला गया';
        }
      case 'mr':
        switch (group) {
          case 'genZ':
            return 'AI आवाज पर्सना Gen Z शैलीत बदलली';
          case 'genAlpha':
            return 'AI आवाज पर्सना Gen Alpha उत्साही शैलीत बदलली';
          default:
            return 'AI आवाज पर्सना सामान्य प्रौढ शैलीत बदलली';
        }
      case 'ta':
        switch (group) {
          case 'genZ':
            return 'AI குரல் பாங்கு Gen Z நடைக்கு மாற்றப்பட்டது';
          case 'genAlpha':
            return 'AI குரல் பாங்கு Gen Alpha துடிப்பான நடைக்கு மாற்றப்பட்டது';
          default:
            return 'AI குரல் பாங்கு வயது வந்தோர் நடைக்கு மாற்றப்பட்டது';
        }
      case 'te':
        switch (group) {
          case 'genZ':
            return 'AI వాయిస్ స్టైల్ Gen Z శైలికి మార్చబడింది';
          case 'genAlpha':
            return 'AI వాయిస్ స్టైల్ Gen Alpha ఉత్సాహభరిత శైలికి మార్చబడింది';
          default:
            return 'AI వాయిస్ స్టైల్ సాధారణ వయోజన శైలికి మార్చబడింది';
        }
      case 'bn':
        switch (group) {
          case 'genZ':
            return 'AI ভয়েস স্টাইল Gen Z স্টাইলে পরিবর্তিত হয়েছে';
          case 'genAlpha':
            return 'AI ভয়েস স্টাইল Gen Alpha প্রাণবন্ত স্টাইলে পরিবর্তিত হয়েছে';
          default:
            return 'AI ভয়েস স্টাইল সাধারণ প্রাপ্তবয়স্ক স্টাইলে পরিবর্তিত হয়েছে';
        }
      case 'kn':
        switch (group) {
          case 'genZ':
            return 'AI ಧ್ವನಿ ಶೈಲಿ Gen Z ಶೈಲಿಗೆ ಬದಲಾಗಿದೆ';
          case 'genAlpha':
            return 'AI ಧ್ವನಿ ಶೈಲಿ Gen Alpha ಉತ್ಸಾಹದ ಶೈಲಿಗೆ ಬದಲಾಗಿದೆ';
          default:
            return 'AI ಧ್ವನಿ ಶೈಲಿ ಸಾಮಾನ್ಯ ವಯಸ್ಕ ಶೈಲಿಗೆ ಬದಲಾಗಿದೆ';
        }
      default:
        switch (group) {
          case 'genZ':
            return 'AI voice persona updated to Gen Z casual vibes';
          case 'genAlpha':
            return 'AI voice persona updated to Gen Alpha energetic tone';
          default:
            return 'AI voice persona updated to standard adult tone';
        }
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

  /// Narration string for [key] in this language. Throws only on a developer
  /// error (missing key) — every language must define every key.
  String voice(VoiceKey key) => voiceStrings[key]!;

  /// Narration with the {n} numeric placeholder filled in (SOS countdown).
  String voiceN(VoiceKey key, int n) => voice(key).replaceAll('{n}', '$n');

  /// Spoken prefix before OCR read-aloud of raw scanned text ('' for English,
  /// matching the original behavior where English scans had no prefix).
  String readAloudPrefix() {
    switch (code) {
      case 'hi':
        return 'पढ़ा गया टेक्स्ट: ';
      case 'mr':
        return 'वाचलेला मजकूर: ';
      case 'ta':
        return 'படித்த உரை: ';
      case 'te':
        return 'చదివిన టెక్స్ట్: ';
      case 'bn':
        return 'পড়া টেক্সট: ';
      case 'kn':
        return 'ಓದಿದ ಪಠ್ಯ: ';
      default:
        return '';
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

/// Keys for the voice narration strings spoken by the app (status prompts,
/// confirmations, OCR announcements). Every language provides ALL of these —
/// narration must never fall back to English text spoken by an Indic voice.
enum VoiceKey {
  cameraReady,
  cameraPermission,
  openSettings,
  startingCamera,
  analyzingScene,
  aiReady,
  starting,
  analyzing,
  stop,
  describeScene,
  callHelp,
  connectingVolunteer,
  connectFailed,
  signInToCall,
  scannerReady,
  scanningText,
  readTextReady,
  noTextFound,
  noTextRetry,
  ocrError,
  sosScreenIntro,
  sosCountdown,
  sosCancelled,
  sosSending,
  sosSent,
  sosTriggered,
  profileSetupPrompt,
  roleSelectedBlind,
  roleSelectedVolunteer,
  pleaseSelectRole,
  incomingCallAnnouncement,
  requestCancelled,
  callClaimedByOther,
  speedPreview,
  pitchPreview,
  languageChanged,
  languageChangedTo,
}

/// Per-language narration strings. Keys map to [VoiceKey].
typedef VoiceStrings = Map<VoiceKey, String>;

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
    voiceStrings: {
      VoiceKey.cameraReady: 'Camera ready. Tap Describe to analyze your surroundings via AI.',
      VoiceKey.cameraPermission: 'Camera permission is required. Please enable it in your device settings.',
      VoiceKey.openSettings: 'Open Settings',
      VoiceKey.startingCamera: 'Starting camera...',
      VoiceKey.analyzingScene: 'Analyzing scene with AI...',
      VoiceKey.aiReady: 'AI Ready',
      VoiceKey.starting: 'Starting...',
      VoiceKey.analyzing: 'Analyzing...',
      VoiceKey.stop: 'Stop',
      VoiceKey.describeScene: 'Describe Scene',
      VoiceKey.callHelp: 'Call Help',
      VoiceKey.connectingVolunteer: 'Connecting you to a volunteer for help...',
      VoiceKey.connectFailed: 'Failed to connect. Please try again.',
      VoiceKey.signInToCall: 'You need to be signed in to call for help.',
      VoiceKey.scannerReady: 'Text Reader ready. Tap Read Text to scan printed text or signs.',
      VoiceKey.scanningText: 'Scanning text...',
      VoiceKey.readTextReady: 'Read Text Out Loud',
      VoiceKey.noTextFound: 'No text found in view.',
      VoiceKey.noTextRetry: 'No text found in camera view. Please hold document steady and try again.',
      VoiceKey.ocrError: 'Sorry, could not read text. Please try again.',
      VoiceKey.sosScreenIntro: 'SOS screen. Tap the large button to send emergency alert with your location.',
      VoiceKey.sosCountdown: 'SOS will send in {n} seconds. Tap cancel to stop.',
      VoiceKey.sosCancelled: 'SOS cancelled.',
      VoiceKey.sosSending: 'Sending SOS alert now...',
      VoiceKey.sosSent: 'SOS alert sent. Connecting to an emergency volunteer now.',
      VoiceKey.sosTriggered: 'SOS alert triggered.',
      VoiceKey.profileSetupPrompt: 'Profile setup. Please select your role and enter your name to continue.',
      VoiceKey.roleSelectedBlind: 'Selected Visually Impaired role.',
      VoiceKey.roleSelectedVolunteer: 'Selected Sighted Volunteer role.',
      VoiceKey.pleaseSelectRole: 'Please select a role.',
      VoiceKey.incomingCallAnnouncement: 'Incoming help request from a visually impaired user.',
      VoiceKey.requestCancelled: 'The help request was cancelled by the user.',
      VoiceKey.callClaimedByOther: 'This call was picked up by another volunteer.',
      VoiceKey.speedPreview: 'This is my speaking speed',
      VoiceKey.pitchPreview: 'This is my voice pitch',
      VoiceKey.languageChanged: 'Language changed to English',
      VoiceKey.languageChangedTo: 'Language changed',
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
    voiceStrings: {
      VoiceKey.cameraReady: 'कैमरा तैयार है। AI से दृश्य का विश्लेषण करने के लिए Describe बटन दबाएँ।',
      VoiceKey.cameraPermission: 'कैमरा अनुमति आवश्यक है। कृपया अपनी डिवाइस सेटिंग्स में सक्षम करें।',
      VoiceKey.openSettings: 'सेटिंग्स खोलें',
      VoiceKey.startingCamera: 'कैमरा शुरू हो रहा है...',
      VoiceKey.analyzingScene: 'AI से दृश्य का विश्लेषण हो रहा है...',
      VoiceKey.aiReady: 'AI तैयार',
      VoiceKey.starting: 'शुरू...',
      VoiceKey.analyzing: 'विश्लेषण...',
      VoiceKey.stop: 'रुकें',
      VoiceKey.describeScene: 'दृश्य बताएँ',
      VoiceKey.callHelp: 'मदद',
      VoiceKey.connectingVolunteer: 'स्वयंसेवक से जोड़ रहे हैं...',
      VoiceKey.connectFailed: 'कनेक्ट करने में विफल। कृपया पुनः प्रयास करें।',
      VoiceKey.signInToCall: 'मदद के लिए कॉल करने के लिए आपको साइन इन होना चाहिए।',
      VoiceKey.scannerReady: 'टेक्स्ट रीडर तैयार। प्रिंटेड टेक्स्ट या साइन स्कैन करने के लिए टेक्स्ट पढ़ें बटन दबाएँ।',
      VoiceKey.scanningText: 'टेक्स्ट स्कैन हो रहा है...',
      VoiceKey.readTextReady: 'टेक्स्ट पढ़ें',
      VoiceKey.noTextFound: 'दृश्य में कोई टेक्स्ट नहीं मिला।',
      VoiceKey.noTextRetry: 'कैमरा दृश्य में कोई टेक्स्ट नहीं मिला। कृपया दस्तावेज़ को स्थिर रखें और पुनः प्रयास करें।',
      VoiceKey.ocrError: 'क्षमा करें, टेक्स्ट नहीं पढ़ सका। कृपया पुनः प्रयास करें।',
      VoiceKey.sosScreenIntro: 'SOS स्क्रीन। आपातकालीन अलर्ट भेजने के लिए बड़ा बटन दबाएँ।',
      VoiceKey.sosCountdown: 'SOS {n} सेकंड में भेजा जाएगा। रोकने के लिए रद्द करें दबाएँ।',
      VoiceKey.sosCancelled: 'SOS रद्द।',
      VoiceKey.sosSending: 'SOS अलर्ट भेजा जा रहा है...',
      VoiceKey.sosSent: 'SOS अलर्ट भेजा गया। आपातकालीन स्वयंसेवक से जोड़ रहे हैं।',
      VoiceKey.sosTriggered: 'SOS अलर्ट भेजा गया।',
      VoiceKey.profileSetupPrompt: 'प्रोफ़ाइल सेटअप। जारी रखने के लिए अपनी भूमिका चुनें और अपना नाम दर्ज करें।',
      VoiceKey.roleSelectedBlind: 'दृष्टिबाधित भूमिका चुनी गई।',
      VoiceKey.roleSelectedVolunteer: 'स्वयंसेवक भूमिका चुनी गई।',
      VoiceKey.pleaseSelectRole: 'कृपया एक भूमिका चुनें।',
      VoiceKey.incomingCallAnnouncement: 'एक दृष्टिबाधित उपयोगकर्ता से मदद का अनुरोध आया है।',
      VoiceKey.requestCancelled: 'मदद का अनुरोध उपयोगकर्ता द्वारा रद्द कर दिया गया।',
      VoiceKey.callClaimedByOther: 'यह कॉल किसी अन्य स्वयंसेवक ने उठा लिया।',
      VoiceKey.speedPreview: 'यह मेरी बोलने की गति है',
      VoiceKey.pitchPreview: 'यह मेरी आवाज़ की पिच है',
      VoiceKey.languageChanged: 'भाषा हिन्दी में बदल दी गई',
      VoiceKey.languageChangedTo: 'भाषा बदल दी गई',
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
    voiceStrings: {
      VoiceKey.cameraReady: 'कॅमेरा तयार आहे. AI कडून आसपासचे विश्लेषण करण्यासाठी Describe बटण दाबा.',
      VoiceKey.cameraPermission: 'कॅमेरा परवानगी आवश्यक आहे. कृपया तुमच्या डिव्हाइस सेटिंग्जमध्ये सक्षम करा.',
      VoiceKey.openSettings: 'सेटिंग्ज उघडा',
      VoiceKey.startingCamera: 'कॅमेरा सुरू होत आहे...',
      VoiceKey.analyzingScene: 'AI दृश्याचे विश्लेषण करत आहे...',
      VoiceKey.aiReady: 'AI तयार',
      VoiceKey.starting: 'सुरू होत आहे...',
      VoiceKey.analyzing: 'विश्लेषण...',
      VoiceKey.stop: 'थांबा',
      VoiceKey.describeScene: 'दृश्य सांगा',
      VoiceKey.callHelp: 'मदत',
      VoiceKey.connectingVolunteer: 'स्वयंसेवकाशी जोडत आहोत...',
      VoiceKey.connectFailed: 'कनेक्ट करण्यात अयशस्वी. कृपया पुन्हा प्रयत्न करा.',
      VoiceKey.signInToCall: 'मदतीसाठी कॉल करण्यासाठी तुम्ही साइन इन असले पाहिजे.',
      VoiceKey.scannerReady: 'टेक्स्ट रीडर तयार. छापील मजकूर किंवा चिन्ह स्कॅन करण्यासाठी टेक्स्ट वाचा बटण दाबा.',
      VoiceKey.scanningText: 'मजकूर स्कॅन होत आहे...',
      VoiceKey.readTextReady: 'टेक्स्ट वाचा',
      VoiceKey.noTextFound: 'दृश्यात कोणताही मजकूर सापडला नाही.',
      VoiceKey.noTextRetry: 'कॅमेरा दृश्यात कोणताही मजकूर सापडला नाही. कृपया दस्तऐवज स्थिर धरा आणि पुन्हा प्रयत्न करा.',
      VoiceKey.ocrError: 'क्षमस्व, मजकूर वाचता आला नाही. कृपया पुन्हा प्रयत्न करा.',
      VoiceKey.sosScreenIntro: 'SOS स्क्रीन. तुमच्या स्थानासह आपत्कालीन सूचना पाठवण्यासाठी मोठे बटण दाबा.',
      VoiceKey.sosCountdown: 'SOS {n} सेकंदांत पाठवला जाईल. थांबवण्यासाठी रद्द दाबा.',
      VoiceKey.sosCancelled: 'SOS रद्द.',
      VoiceKey.sosSending: 'आता SOS सूचना पाठवत आहोत...',
      VoiceKey.sosSent: 'SOS सूचना पाठवली. आपत्कालीन स्वयंसेवकाशी जोडत आहोत.',
      VoiceKey.sosTriggered: 'SOS सूचना सक्रिय.',
      VoiceKey.profileSetupPrompt: 'प्रोफाइल सेटअप. सुरू ठेवण्यासाठी तुमची भूमिका निवडा आणि नाव प्रविष्ट करा.',
      VoiceKey.roleSelectedBlind: 'दृष्टीदोष भूमिका निवडली.',
      VoiceKey.roleSelectedVolunteer: 'स्वयंसेवक भूमिका निवडली.',
      VoiceKey.pleaseSelectRole: 'कृपया भूमिका निवडा.',
      VoiceKey.incomingCallAnnouncement: 'दृष्टीदोष वापरकर्त्याकडून मदतीची विनंती आली आहे.',
      VoiceKey.requestCancelled: 'मदतीची विनंती वापरकर्त्याने रद्द केली आहे.',
      VoiceKey.callClaimedByOther: 'हा कॉल दुसऱ्या स्वयंसेवकाने घेतला आहे.',
      VoiceKey.speedPreview: 'ही माझी बोलण्याची गती आहे',
      VoiceKey.pitchPreview: 'ही माझ्या आवाजाची पिच आहे',
      VoiceKey.languageChanged: 'भाषा मराठीत बदलली',
      VoiceKey.languageChangedTo: 'भाषा बदलली',
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
    voiceStrings: {
      VoiceKey.cameraReady: 'கேமரா தயார். AI உங்கள் சூழலை பகுப்பாய்வு செய்ய விவரி பொத்தானை அழுத்துங்கள்.',
      VoiceKey.cameraPermission: 'கேமரா அனுமதி தேவை. உங்கள் சாதன அமைப்புகளில் இயக்கவும்.',
      VoiceKey.openSettings: 'அமைப்புகளைத் திற',
      VoiceKey.startingCamera: 'கேமரா தொடங்குகிறது...',
      VoiceKey.analyzingScene: 'AI சூழலை பகுப்பாய்வு செய்கிறது...',
      VoiceKey.aiReady: 'AI தயார்',
      VoiceKey.starting: 'தொடங்குகிறது...',
      VoiceKey.analyzing: 'பகுப்பாய்வு...',
      VoiceKey.stop: 'நிறுத்து',
      VoiceKey.describeScene: 'காட்சி விவரி',
      VoiceKey.callHelp: 'உதவி',
      VoiceKey.connectingVolunteer: 'தன்னார்வலருடன் இணைக்கிறோம்...',
      VoiceKey.connectFailed: 'இணைக்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்.',
      VoiceKey.signInToCall: 'உதவிக்கு அழைக்க நீங்கள் உள்நுழைந்திருக்க வேண்டும்.',
      VoiceKey.scannerReady: 'உரை வாசிப்பான் தயார். அச்சிடப்பட்ட உரையை ஸ்கேன் செய்ய உரை படிக்கவும் பொத்தானை அழுத்துங்கள்.',
      VoiceKey.scanningText: 'உரை ஸ்கேன் செய்யப்படுகிறது...',
      VoiceKey.readTextReady: 'உரையைப் படிக்கவும்',
      VoiceKey.noTextFound: 'காட்சியில் உரை எதுவும் கிடைக்கவில்லை.',
      VoiceKey.noTextRetry: 'கேமரா காட்சியில் உரை எதுவும் கிடைக்கவில்லை. ஆவணத்தை உறுதியாகப் பிடித்து மீண்டும் முயற்சிக்கவும்.',
      VoiceKey.ocrError: 'மன்னிக்கவும், உரையைப் படிக்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்.',
      VoiceKey.sosScreenIntro: 'SOS திரை. உங்கள் இருப்பிடத்துடன் அவசர எச்சரிக்கை அனுப்ப பெரிய பொத்தானை அழுத்துங்கள்.',
      VoiceKey.sosCountdown: 'SOS {n} வினாடிகளில் அனுப்பப்படும். நிறுத்த ரத்து பொத்தானை அழுத்துங்கள்.',
      VoiceKey.sosCancelled: 'SOS ரத்து செய்யப்பட்டது.',
      VoiceKey.sosSending: 'இப்போது SOS எச்சரிக்கை அனுப்பப்படுகிறது...',
      VoiceKey.sosSent: 'SOS எச்சரிக்கை அனுப்பப்பட்டது. அவசர தன்னார்வலருடன் இணைக்கிறோம்.',
      VoiceKey.sosTriggered: 'SOS எச்சரிக்கை செயல்படுத்தப்பட்டது.',
      VoiceKey.profileSetupPrompt: 'சுயவிவர அமைப்பு. தொடர உங்கள் பங்கைத் தேர்ந்தெடுத்து பெயரை உள்ளிடவும்.',
      VoiceKey.roleSelectedBlind: 'பார்வையற்ற பங்கு தேர்ந்தெடுக்கப்பட்டது.',
      VoiceKey.roleSelectedVolunteer: 'தன்னார்வ பங்கு தேர்ந்தெடுக்கப்பட்டது.',
      VoiceKey.pleaseSelectRole: 'பங்கைத் தேர்ந்தெடுக்கவும்.',
      VoiceKey.incomingCallAnnouncement: 'பார்வையற்ற பயனரிடமிருந்து உதவி கோரிக்கை வந்துள்ளது.',
      VoiceKey.requestCancelled: 'உதவி கோரிக்கை பயனரால் ரத்து செய்யப்பட்டது.',
      VoiceKey.callClaimedByOther: 'இந்த அழைப்பை மற்றொரு தன்னார்வலர் ஏற்றுக்கொண்டார்.',
      VoiceKey.speedPreview: 'இது எனது பேச்சு வேகம்',
      VoiceKey.pitchPreview: 'இது எனது குரல் பிட்ச்',
      VoiceKey.languageChanged: 'மொழி தமிழாக மாற்றப்பட்டது',
      VoiceKey.languageChangedTo: 'மொழி மாற்றப்பட்டது',
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
    voiceStrings: {
      VoiceKey.cameraReady: 'కెమెరా సిద్ధంగా ఉంది. AIతో మీ పరిసరాలను విశ్లేషించడానికి వివరించు బటన్ నొక్కండి.',
      VoiceKey.cameraPermission: 'కెమెరా అనుమతి అవసరం. దయచేసి మీ పరికర సెట్టింగ్‌లలో ప్రారంభించండి.',
      VoiceKey.openSettings: 'సెట్టింగ్‌లను తెరవండి',
      VoiceKey.startingCamera: 'కెమెరా ప్రారంభమవుతోంది...',
      VoiceKey.analyzingScene: 'AI దృశ్యాన్ని విశ్లేషిస్తోంది...',
      VoiceKey.aiReady: 'AI సిద్ధం',
      VoiceKey.starting: 'ప్రారంభమవుతోంది...',
      VoiceKey.analyzing: 'విశ్లేషణ...',
      VoiceKey.stop: 'ఆపు',
      VoiceKey.describeScene: 'దృశ్యాన్ని వివరించు',
      VoiceKey.callHelp: 'సహాయం',
      VoiceKey.connectingVolunteer: 'స్వచ్ఛంద సేవకునితో కనెక్ట్ చేస్తోంది...',
      VoiceKey.connectFailed: 'కనెక్ట్ చేయడంలో విఫలమైంది. దయచేసి మళ్లీ ప్రయత్నించండి.',
      VoiceKey.signInToCall: 'సహాయం కోసం కాల్ చేయడానికి మీరు సైన్ ఇన్ చేసి ఉండాలి.',
      VoiceKey.scannerReady: 'టెక్స్ట్ రీడర్ సిద్ధంగా ఉంది. ముద్రిత టెక్స్ట్‌ను స్కాన్ చేయడానికి టెక్స్ట్ చదువు బటన్ నొక్కండి.',
      VoiceKey.scanningText: 'టెక్స్ట్ స్కాన్ అవుతోంది...',
      VoiceKey.readTextReady: 'టెక్స్ట్ చదువు',
      VoiceKey.noTextFound: 'దృశ్యంలో టెక్స్ట్ కనుగొనబడలేదు.',
      VoiceKey.noTextRetry: 'కెమెరా దృశ్యంలో టెక్స్ట్ కనుగొనబడలేదు. దయచేసి పత్రాన్ని స్థిరంగా పట్టుకుని మళ్లీ ప్రయత్నించండి.',
      VoiceKey.ocrError: 'క్షమించండి, టెక్స్ట్ చదవడం సాధ్యం కాలేదు. మళ్లీ ప్రయత్నించండి.',
      VoiceKey.sosScreenIntro: 'SOS స్క్రీన్. మీ స్థానంతో అత్యవసర హెచ్చరిక పంపడానికి పెద్ద బటన్ నొక్కండి.',
      VoiceKey.sosCountdown: 'SOS {n} సెకన్లలో పంపబడుతుంది. ఆపడానికి రద్దు చేయి బటన్ నొక్కండి.',
      VoiceKey.sosCancelled: 'SOS రద్దు చేయబడింది.',
      VoiceKey.sosSending: 'ఇప్పుడు SOS హెచ్చరిక పంపుతున్నాము...',
      VoiceKey.sosSent: 'SOS హెచ్చరిక పంపబడింది. అత్యవసర స్వచ్ఛంద సేవకునితో కనెక్ట్ చేస్తున్నాము.',
      VoiceKey.sosTriggered: 'SOS హెచ్చరిక ట్రిగర్ చేయబడింది.',
      VoiceKey.profileSetupPrompt: 'ప్రొఫైల్ సెటప్. కొనసాగించడానికి మీ పాత్రను ఎంచుకుని పేరు నమోదు చేయండి.',
      VoiceKey.roleSelectedBlind: 'దృష్టి లోపం పాత్ర ఎంపిక చేయబడింది.',
      VoiceKey.roleSelectedVolunteer: 'స్వచ్ఛంద పాత్ర ఎంపిక చేయబడింది.',
      VoiceKey.pleaseSelectRole: 'దయచేసి పాత్రను ఎంచుకోండి.',
      VoiceKey.incomingCallAnnouncement: 'దృష్టి లోపం ఉన్న వినియోగదారు నుండి సహాయ అభ్యర్థన వచ్చింది.',
      VoiceKey.requestCancelled: 'సహాయ అభ్యర్థన వినియోగదారుచే రద్దు చేయబడింది.',
      VoiceKey.callClaimedByOther: 'ఈ కాల్‌ను మరొక స్వచ్ఛంద సేవకుడు తీసుకున్నారు.',
      VoiceKey.speedPreview: 'ఇది నా మాట్లాడే వేగం',
      VoiceKey.pitchPreview: 'ఇది నా వాయిస్ పిచ్',
      VoiceKey.languageChanged: 'భాష తెలుగుకు మార్చబడింది',
      VoiceKey.languageChangedTo: 'భాష మార్చబడింది',
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
    voiceStrings: {
      VoiceKey.cameraReady: 'ক্যামেরা প্রস্তুত। AI দিয়ে আশেপাশে বিশ্লেষণ করতে বর্ণনা বোতাম চাপুন।',
      VoiceKey.cameraPermission: 'ক্যামেরার অনুমতি প্রয়োজন। অনুগ্রহ করে আপনার ডিভাইস সেটিংসে সক্ষম করুন।',
      VoiceKey.openSettings: 'সেটিংস খুলুন',
      VoiceKey.startingCamera: 'ক্যামেরা চালু হচ্ছে...',
      VoiceKey.analyzingScene: 'AI দৃশ্য বিশ্লেষণ করছে...',
      VoiceKey.aiReady: 'AI প্রস্তুত',
      VoiceKey.starting: 'শুরু হচ্ছে...',
      VoiceKey.analyzing: 'বিশ্লেষণ...',
      VoiceKey.stop: 'থামুন',
      VoiceKey.describeScene: 'দৃশ্য বর্ণনা করুন',
      VoiceKey.callHelp: 'সাহায্য',
      VoiceKey.connectingVolunteer: 'স্বেচ্ছাসেবকের সাথে সংযোগ করা হচ্ছে...',
      VoiceKey.connectFailed: 'সংযোগ করতে ব্যর্থ। অনুগ্রহ করে আবার চেষ্টা করুন।',
      VoiceKey.signInToCall: 'সাহায্যের জন্য কল করতে আপনাকে সাইন ইন করতে হবে।',
      VoiceKey.scannerReady: 'টেক্সট রিডার প্রস্তুত। মুদ্রিত টেক্সট স্ক্যান করতে টেক্সট পড়ুন বোতাম চাপুন।',
      VoiceKey.scanningText: 'টেক্সট স্ক্যান হচ্ছে...',
      VoiceKey.readTextReady: 'টেক্সট পড়ুন',
      VoiceKey.noTextFound: 'দৃশ্যে কোনো টেক্সট পাওয়া যায়নি।',
      VoiceKey.noTextRetry: 'ক্যামেরার দৃশ্যে কোনো টেক্সট পাওয়া যায়নি। অনুগ্রহ করে নথিটি স্থির রেখে আবার চেষ্টা করুন।',
      VoiceKey.ocrError: 'দুঃখিত, টেক্সট পড়া যায়নি। আবার চেষ্টা করুন।',
      VoiceKey.sosScreenIntro: 'SOS স্ক্রিন। আপনার অবস্থান সহ জরুরি সতর্কতা পাঠাতে বড় বোতাম চাপুন।',
      VoiceKey.sosCountdown: 'SOS {n} সেকেন্ডে পাঠানো হবে। থামাতে বাতিল বোতাম চাপুন।',
      VoiceKey.sosCancelled: 'SOS বাতিল হয়েছে।',
      VoiceKey.sosSending: 'এখন SOS সতর্কতা পাঠানো হচ্ছে...',
      VoiceKey.sosSent: 'SOS সতর্কতা পাঠানো হয়েছে। জরুরি স্বেচ্ছাসেবকের সাথে সংযোগ করা হচ্ছে।',
      VoiceKey.sosTriggered: 'SOS সতর্কতা ট্রিগার হয়েছে।',
      VoiceKey.profileSetupPrompt: 'প্রোফাইল সেটআপ। চালিয়ে যেতে আপনার ভূমিকা নির্বাচন করে নাম লিখুন।',
      VoiceKey.roleSelectedBlind: 'দৃষ্টি প্রতিবন্ধী ভূমিকা নির্বাচিত হয়েছে।',
      VoiceKey.roleSelectedVolunteer: 'স্বেচ্ছাসেবক ভূমিকা নির্বাচিত হয়েছে।',
      VoiceKey.pleaseSelectRole: 'অনুগ্রহ করে একটি ভূমিকা নির্বাচন করুন।',
      VoiceKey.incomingCallAnnouncement: 'দৃষ্টি প্রতিবন্ধী ব্যবহারকারীর কাছ থেকে সাহায্যের অনুরোধ এসেছে।',
      VoiceKey.requestCancelled: 'সাহায্যের অনুরোধ ব্যবহারকারী বাতিল করেছেন।',
      VoiceKey.callClaimedByOther: 'এই কল অন্য একজন স্বেচ্ছাসেবক গ্রহণ করেছেন।',
      VoiceKey.speedPreview: 'এটি আমার কথা বলার গতি',
      VoiceKey.pitchPreview: 'এটি আমার ভয়েস পিচ',
      VoiceKey.languageChanged: 'ভাষা বাংলায় পরিবর্তিত হয়েছে',
      VoiceKey.languageChangedTo: 'ভাষা পরিবর্তিত হয়েছে',
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
    voiceStrings: {
      VoiceKey.cameraReady: 'ಕ್ಯಾಮೆರಾ ಸಿದ್ಧವಾಗಿದೆ. AI ನಿಮ್ಮ ಪರಿಸರವನ್ನು ವಿಶ್ಲೇಷಿಸಲು ವಿವರಿಸು ಬಟನ್ ಒತ್ತಿರಿ.',
      VoiceKey.cameraPermission: 'ಕ್ಯಾಮೆರಾ ಅನುಮತಿ ಅಗತ್ಯವಿದೆ. ದಯವಿಟ್ಟು ನಿಮ್ಮ ಸಾಧನ ಸೆಟ್ಟಿಂಗ್‌ಗಳಲ್ಲಿ ಸಕ್ರಿಯಗೊಳಿಸಿ.',
      VoiceKey.openSettings: 'ಸೆಟ್ಟಿಂಗ್‌ಗಳನ್ನು ತೆರೆಯಿರಿ',
      VoiceKey.startingCamera: 'ಕ್ಯಾಮೆರಾ ಪ್ರಾರಂಭವಾಗುತ್ತಿದೆ...',
      VoiceKey.analyzingScene: 'AI ದೃಶ್ಯವನ್ನು ವಿಶ್ಲೇಷಿಸುತ್ತಿದೆ...',
      VoiceKey.aiReady: 'AI ಸಿದ್ಧ',
      VoiceKey.starting: 'ಪ್ರಾರಂಭವಾಗುತ್ತಿದೆ...',
      VoiceKey.analyzing: 'ವಿಶ್ಲೇಷಣ...',
      VoiceKey.stop: 'ನಿಲ್ಲಿಸು',
      VoiceKey.describeScene: 'ದೃಶ್ಯ ವಿವರಿಸು',
      VoiceKey.callHelp: 'ಸಹಾಯ',
      VoiceKey.connectingVolunteer: 'ಸ್ವಯಂಸೇವಕರೊಂದಿಗೆ ಸಂಪರ್ಕಿಸಲಾಗುತ್ತಿದೆ...',
      VoiceKey.connectFailed: 'ಸಂಪರ್ಕಿಸಲು ವಿಫಲವಾಗಿದೆ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
      VoiceKey.signInToCall: 'ಸಹಾಯಕ್ಕೆ ಕರೆ ಮಾಡಲು ನೀವು ಸೈನ್ ಇನ್ ಆಗಿರಬೇಕು.',
      VoiceKey.scannerReady: 'ಟೆಕ್ಸ್ಟ್ ರೀಡರ್ ಸಿದ್ಧವಾಗಿದೆ. ಮುದ್ರಿತ ಪಠ್ಯವನ್ನು ಸ್ಕ್ಯಾನ್ ಮಾಡಲು ಟೆಕ್ಸ್ಟ್ ಓದು ಬಟನ್ ಒತ್ತಿರಿ.',
      VoiceKey.scanningText: 'ಪಠ್ಯ ಸ್ಕ್ಯಾನ್ ಆಗುತ್ತಿದೆ...',
      VoiceKey.readTextReady: 'ಟೆಕ್ಸ್ಟ್ ಓದಿ',
      VoiceKey.noTextFound: 'ದೃಶ್ಯದಲ್ಲಿ ಯಾವುದೇ ಪಠ್ಯ ಸಿಗಲಿಲ್ಲ.',
      VoiceKey.noTextRetry: 'ಕ್ಯಾಮೆರಾ ದೃಶ್ಯದಲ್ಲಿ ಯಾವುದೇ ಪಠ್ಯ ಸಿಗಲಿಲ್ಲ. ದಯವಿಟ್ಟು ದಸ್ತಾವೇಜನ್ನು ಸ್ಥಿರವಾಗಿ ಹಿಡಿದು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
      VoiceKey.ocrError: 'ಕ್ಷಮಿಸಿ, ಪಠ್ಯ ಓದಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ. ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.',
      VoiceKey.sosScreenIntro: 'SOS ಪರದೆ. ನಿಮ್ಮ ಸ್ಥಳದೊಂದಿಗೆ ತುರ್ತು ಎಚ್ಚರಿಕೆ ಕಳುಹಿಸಲು ದೊಡ್ಡ ಬಟನ್ ಒತ್ತಿರಿ.',
      VoiceKey.sosCountdown: 'SOS {n} ಸೆಕೆಂಡುಗಳಲ್ಲಿ ಕಳುಹಿಸಲಾಗುವುದು. ನಿಲ್ಲಿಸಲು ರದ್ದು ಬಟನ್ ಒತ್ತಿರಿ.',
      VoiceKey.sosCancelled: 'SOS ರದ್ದುಗೊಳಿಸಲಾಗಿದೆ.',
      VoiceKey.sosSending: 'ಈಗ SOS ಎಚ್ಚರಿಕೆ ಕಳುಹಿಸಲಾಗುತ್ತಿದೆ...',
      VoiceKey.sosSent: 'SOS ಎಚ್ಚರಿಕೆ ಕಳುಹಿಸಲಾಗಿದೆ. ತುರ್ತು ಸ್ವಯಂಸೇವಕರೊಂದಿಗೆ ಸಂಪರ್ಕಿಸಲಾಗುತ್ತಿದೆ.',
      VoiceKey.sosTriggered: 'SOS ಎಚ್ಚರಿಕೆ ಸಕ್ರಿಯಗೊಂಡಿದೆ.',
      VoiceKey.profileSetupPrompt: 'ಪ್ರೊಫೈಲ್ ಸೆಟಪ್. ಮುಂದುವರಿಯಲು ನಿಮ್ಮ ಪಾತ್ರವನ್ನು ಆಯ್ಕೆ ಮಾಡಿ ಹೆಸರನ್ನು ನಮೂದಿಸಿ.',
      VoiceKey.roleSelectedBlind: 'ದೃಷ್ಟಿ ಸಮಸ್ಯೆ ಪಾತ್ರ ಆಯ್ಕೆ ಮಾಡಲಾಗಿದೆ.',
      VoiceKey.roleSelectedVolunteer: 'ಸ್ವಯಂಸೇವಕ ಪಾತ್ರ ಆಯ್ಕೆ ಮಾಡಲಾಗಿದೆ.',
      VoiceKey.pleaseSelectRole: 'ದಯವಿಟ್ಟು ಪಾತ್ರ ಆಯ್ಕೆ ಮಾಡಿ.',
      VoiceKey.incomingCallAnnouncement: 'ದೃಷ್ಟಿ ಸಮಸ್ಯೆ ಬಳಕೆದಾರರಿಂದ ಸಹಾಯದ ವಿನಂತಿ ಬಂದಿದೆ.',
      VoiceKey.requestCancelled: 'ಸಹಾಯದ ವಿನಂತಿಯನ್ನು ಬಳಕೆದಾರರು ರದ್ದುಗೊಳಿಸಿದ್ದಾರೆ.',
      VoiceKey.callClaimedByOther: 'ಈ ಕರೆಯನ್ನು ಇನ್ನೊಬ್ಬ ಸ್ವಯಂಸೇವಕ ಸ್ವೀಕರಿಸಿದ್ದಾರೆ.',
      VoiceKey.speedPreview: 'ಇದು ನನ್ನ ಮಾತನಾಡುವ ವೇಗ',
      VoiceKey.pitchPreview: 'ಇದು ನನ್ನ ಧ್ವನಿ ಪಿಚ್',
      VoiceKey.languageChanged: 'ಭಾಷೆ ಕನ್ನಡಕ್ಕೆ ಬದಲಾಗಿದೆ',
      VoiceKey.languageChangedTo: 'ಭಾಷೆ ಬದಲಾಗಿದೆ',
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
