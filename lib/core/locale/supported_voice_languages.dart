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
    this.uiStrings = const {},
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

  /// All on-screen UI strings for this language.
  final UIStrings uiStrings;

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

  /// UI string for [key] in this language.
  String ui(UIKey key) => uiStrings[key]!;

  /// UI string with {x} placeholder replaced.
  String uiX(UIKey key, String x) => ui(key).replaceAll('{x}', x);

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

/// Keys for on-screen UI strings. Every language provides ALL of these so the
/// whole interface renders in the selected language.
enum UIKey {
  appNameTagline,
  visionbridgeLogo,
  welcomeTo,
  loginSubtitle,
  signInWithGoogle,
  orUseVerificationCode,
  phoneNumber,
  sendVerificationCode,
  verificationCode,
  enterOtpHint,
  changeNumber,
  verifyCode,
  setUpProfile,
  letUsKnowHow,
  iAm,
  visuallyImpaired,
  iNeedAssistance,
  sightedVolunteer,
  iWantToHelp,
  displayName,
  enterYourName,
  nameRequired,
  startUsingVB,
  pleaseSelectYourRole,
  settings,
  profile,
  appearance,
  theme,
  language,
  voiceLanguageSubtitle,
  chooseVoiceLanguage,
  voiceSubtitleBU,
  voiceSubtitleV,
  notifications,
  pushNotifications,
  receivingRequests,
  notificationsDisabled,
  soundAndVibration,
  forIncomingCallAlerts,
  account,
  signOut,
  editProfile,
  editProfilePhoto,
  uploadPhoto,
  enterDisplayName,
  cancel,
  save,
  photoUpdated,
  user,
  volunteer,
  dashboard,
  youreOnline,
  youreOffline,
  readyToReceive,
  tapToStartVolunteering,
  availabilityToggleOnline,
  availabilityToggleOffline,
  callsHelped,
  timeGiven,
  recentActivity,
  noCallsYet,
  goOnlineToStartHelping,
  helpedUser,
  assistedBy,
  fullHistory,
  justNow,
  daysAgo,
  hoursAgo,
  minutesAgo,
  durationLabel,
  callHistory,
  noCallHistoryYet,
  historyWillAppearHere,
  goOnlineToStartHelpingExcl,
  visuallyImpairedUser,
  communityVolunteer,
  hello,
  aiVisualAssist,
  tapToSeeAround,
  aiAssistSemantics,
  history,
  readText,
  openSettingsSemantics,
  readTextOcr,
  extractedText,
  tapToSpeakStop,
  readTextOutLoud,
  pointCameraHint,
  hiPointCameraHint,
  emergencySos,
  sosShareLocation,
  sosCancel,
  sendingSos,
  sendingSosIn,
  sosActivated,
  incomingCall,
  someoneNeedsHelp,
  pickedUpByOther,
  connectingLiveCall,
  requestingLiveAssistance,
  decline,
  accept,
  connectingVideo,
  assistingWith,
  describeClearlyHint,
  mute,
  unmute,
  speaker,
  earpiece,
  connected,
  waitingForVolunteer,
  endCall,
  callAnswered,
  callRequestExpired,
  callClaimedOrCancelled,
  failedToAcceptCall,
  goBack,
  analyzingStatus,
  skipOnboarding,
  skip,
  next,
  getStarted,
  onboardingStep,
  onboardingStepOf,
  callRequestInvalid,
  voiceSection,
  ttsSpeed,
  ttsPitch,
  personaTone,
  personaDesc,
  detectionSection,
  confidenceThreshold,
  autoDescribe,
  autoDescribeDesc,
  accessibilitySection,
  hapticFeedback,
  hapticDesc,
  speedPreviewLabel,
  pitchLabel,
}

/// Per-language UI strings. Keys map to [UIKey].
typedef UIStrings = Map<UIKey, String>;

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
    uiStrings: {
      UIKey.appNameTagline: 'Your AI-powered visual assistant',
      UIKey.welcomeTo: 'Welcome to\nVisionBridge',
      UIKey.loginSubtitle: 'Sign in with your Google account or via verification code to start using the app.',
      UIKey.signInWithGoogle: 'Sign In with Google',
      UIKey.orUseVerificationCode: 'or use verification code',
      UIKey.phoneNumber: 'Phone Number',
      UIKey.sendVerificationCode: 'Send Verification Code',
      UIKey.verificationCode: 'Verification Code',
      UIKey.enterOtpHint: 'Enter 6-digit code',
      UIKey.changeNumber: 'Change Number',
      UIKey.verifyCode: 'Verify Code',
      UIKey.setUpProfile: 'Set up profile',
      UIKey.letUsKnowHow: 'Let us know how you will use VisionBridge.',
      UIKey.iAm: 'I am...',
      UIKey.visuallyImpaired: 'Visually\nImpaired',
      UIKey.iNeedAssistance: 'I need assistance',
      UIKey.sightedVolunteer: 'Sighted\nVolunteer',
      UIKey.iWantToHelp: 'I want to help',
      UIKey.displayName: 'Display Name',
      UIKey.enterYourName: 'Enter your name',
      UIKey.nameRequired: 'Name is required',
      UIKey.startUsingVB: 'Start Using VisionBridge',
      UIKey.pleaseSelectYourRole: 'Please select your role',
      UIKey.settings: 'Settings',
      UIKey.profile: 'Profile',
      UIKey.appearance: 'Appearance',
      UIKey.theme: 'Theme',
      UIKey.language: 'Language / भाषा',
      UIKey.voiceLanguageSubtitle: 'Voice, AI descriptions & voice commands',
      UIKey.chooseVoiceLanguage: 'Choose Voice Language / आवाज़ की भाषा चुनें',
      UIKey.voiceSubtitleBU: 'Voice, AI descriptions & voice commands',
      UIKey.voiceSubtitleV: 'Voice & voice commands',
      UIKey.notifications: 'Notifications',
      UIKey.pushNotifications: 'Push Notifications',
      UIKey.receivingRequests: 'Receiving help requests when online',
      UIKey.notificationsDisabled: 'Notifications disabled',
      UIKey.soundAndVibration: 'Sound & Vibration',
      UIKey.forIncomingCallAlerts: 'For incoming call alerts',
      UIKey.account: 'Account',
      UIKey.signOut: 'Sign Out',
      UIKey.editProfile: 'Edit Profile & Photo',
      UIKey.editProfilePhoto: 'Edit Profile & Photo',
      UIKey.uploadPhoto: 'Upload Photo from Device',
      UIKey.enterDisplayName: 'Enter display name',
      UIKey.cancel: 'Cancel',
      UIKey.save: 'Save',
      UIKey.photoUpdated: 'Profile photo updated successfully!',
      UIKey.user: 'User',
      UIKey.volunteer: 'Volunteer',
      UIKey.dashboard: 'Dashboard',
      UIKey.youreOnline: "You're Online",
      UIKey.youreOffline: "You're Offline",
      UIKey.readyToReceive: 'Ready to receive help requests',
      UIKey.tapToStartVolunteering: 'Tap to start volunteering',
      UIKey.availabilityToggleOnline: 'Availability toggle. Currently online. Tap to go offline.',
      UIKey.availabilityToggleOffline: 'Availability toggle. Currently offline. Tap to go online.',
      UIKey.callsHelped: 'Calls Helped',
      UIKey.timeGiven: 'Time Given',
      UIKey.recentActivity: 'Recent Activity',
      UIKey.noCallsYet: 'No calls yet',
      UIKey.goOnlineToStartHelping: 'Go online to start helping!',
      UIKey.helpedUser: 'Helped {x}',
      UIKey.assistedBy: 'Assisted by {x}',
      UIKey.fullHistory: 'Full History',
      UIKey.justNow: 'Just now',
      UIKey.daysAgo: '{x}d ago',
      UIKey.hoursAgo: '{x}h ago',
      UIKey.minutesAgo: '{x}m ago',
      UIKey.durationLabel: 'Duration: {x}',
      UIKey.callHistory: 'Call History',
      UIKey.noCallHistoryYet: 'No call history yet',
      UIKey.historyWillAppearHere: 'Your call history will appear here',
      UIKey.goOnlineToStartHelpingExcl: 'Go online to start helping!',
      UIKey.visuallyImpairedUser: 'Visually Impaired User',
      UIKey.communityVolunteer: 'Community Volunteer',
      UIKey.hello: 'Hello,',
      UIKey.aiVisualAssist: 'AI Visual Assist',
      UIKey.tapToSeeAround: "Tap to see what's around you",
      UIKey.aiAssistSemantics: 'AI Visual Assist. Tap to open camera and get AI-powered scene description.',
      UIKey.history: 'History',
      UIKey.readText: 'Read Text',
      UIKey.openSettingsSemantics: 'Open settings',
      UIKey.readTextOcr: 'Read Text (OCR)',
      UIKey.extractedText: 'Extracted Text',
      UIKey.tapToSpeakStop: 'Tap to speak/stop',
      UIKey.readTextOutLoud: 'Read Text Out Loud',
      UIKey.pointCameraHint: 'Point camera at any text, sign, or document and tap Read.',
      UIKey.hiPointCameraHint: 'कैमरा किसी टेक्स्ट, साइन या दस्तावेज़ की ओर रखें और पढ़ें बटन दबाएँ।',
      UIKey.emergencySos: 'Emergency SOS',
      UIKey.sosShareLocation: 'This will share your live location\nwith emergency contacts.',
      UIKey.sosCancel: 'CANCEL',
      UIKey.sendingSos: 'Sending SOS...',
      UIKey.sendingSosIn: 'Sending SOS in',
      UIKey.sosActivated: 'SOS Activated! Notifying emergency contacts.',
      UIKey.incomingCall: 'Incoming Call',
      UIKey.someoneNeedsHelp: 'Someone needs\nyour help',
      UIKey.pickedUpByOther: 'This request was picked up by another volunteer.',
      UIKey.connectingLiveCall: 'Connecting live call...',
      UIKey.requestingLiveAssistance: 'A visually impaired user is requesting\nlive visual assistance',
      UIKey.decline: 'Decline',
      UIKey.accept: 'Accept',
      UIKey.connectingVideo: 'Connecting live video...',
      UIKey.assistingWith: 'Assisting · {x}',
      UIKey.describeClearlyHint: 'Describe what you see clearly — the user can hear you.',
      UIKey.mute: 'Mute',
      UIKey.unmute: 'Unmute',
      UIKey.speaker: 'Speaker',
      UIKey.earpiece: 'Earpiece',
      UIKey.connected: 'Connected',
      UIKey.waitingForVolunteer: 'Waiting for volunteer...',
      UIKey.endCall: 'End call',
      UIKey.callAnswered: 'Call Answered',
      UIKey.callRequestExpired: 'Call request expired or invalid.',
      UIKey.callClaimedOrCancelled: 'Call was already claimed by another volunteer or cancelled.',
      UIKey.failedToAcceptCall: 'Failed to accept call: {x}',
      UIKey.goBack: 'Go back',
      UIKey.analyzingStatus: 'Analyzing...',
      UIKey.skipOnboarding: 'Skip onboarding',
      UIKey.skip: 'Skip',
      UIKey.next: 'Next',
      UIKey.getStarted: 'Get Started',
      UIKey.onboardingStep: 'Onboarding step {x}',
      UIKey.onboardingStepOf: 'of {x}',
      UIKey.visionbridgeLogo: 'VisionBridge logo',
      UIKey.callRequestInvalid: 'Call request expired or invalid.',
      UIKey.voiceSection: 'Voice',
      UIKey.ttsSpeed: 'TTS Speed',
      UIKey.ttsPitch: 'TTS Pitch',
      UIKey.personaTone: 'AI Persona Tone',
      UIKey.personaDesc: 'Adapts AI voice tone to your age group',
      UIKey.detectionSection: 'Detection',
      UIKey.confidenceThreshold: 'AI Confidence Threshold',
      UIKey.autoDescribe: 'Auto Scene Description',
      UIKey.autoDescribeDesc: 'Automatically describe scenes via AI',
      UIKey.accessibilitySection: 'Accessibility',
      UIKey.hapticFeedback: 'Haptic Feedback',
      UIKey.hapticDesc: 'Vibrate on key actions',
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
    uiStrings: {
      UIKey.appNameTagline: 'आपका AI-संचालित दृश्य सहायक',
      UIKey.welcomeTo: 'विज़नब्रिज में\nस्वागत है',
      UIKey.loginSubtitle: 'ऐप उपयोग शुरू करने के लिए Google खाते या सत्यापन कोड से साइन इन करें।',
      UIKey.signInWithGoogle: 'Google से साइन इन करें',
      UIKey.orUseVerificationCode: 'या सत्यापन कोड से साइन इन करें',
      UIKey.phoneNumber: 'फ़ोन नंबर',
      UIKey.sendVerificationCode: 'सत्यापन कोड भेजें',
      UIKey.verificationCode: 'सत्यापन कोड',
      UIKey.enterOtpHint: '6 अंकों का कोड दर्ज करें',
      UIKey.changeNumber: 'नंबर बदलें',
      UIKey.verifyCode: 'कोड सत्यापित करें',
      UIKey.setUpProfile: 'प्रोफ़ाइल सेटअप',
      UIKey.letUsKnowHow: 'बताएँ कि आप VisionBridge का उपयोग कैसे करेंगे।',
      UIKey.iAm: 'मैं हूँ...',
      UIKey.visuallyImpaired: 'दृष्टिबाधित',
      UIKey.iNeedAssistance: 'मुझे सहायता चाहिए',
      UIKey.sightedVolunteer: 'स्वयंसेवक',
      UIKey.iWantToHelp: 'मैं मदद करना चाहता हूँ',
      UIKey.displayName: 'प्रदर्शित नाम',
      UIKey.enterYourName: 'अपना नाम दर्ज करें',
      UIKey.nameRequired: 'नाम आवश्यक है',
      UIKey.startUsingVB: 'VisionBridge शुरू करें',
      UIKey.pleaseSelectYourRole: 'कृपया अपनी भूमिका चुनें',
      UIKey.settings: 'सेटिंग्स',
      UIKey.profile: 'प्रोफ़ाइल',
      UIKey.appearance: 'दिखावट',
      UIKey.theme: 'थीम',
      UIKey.language: 'भाषा / Language',
      UIKey.voiceLanguageSubtitle: 'आवाज़, AI विवरण और आवाज़ आदेश',
      UIKey.chooseVoiceLanguage: 'आवाज़ की भाषा चुनें / Choose Voice Language',
      UIKey.voiceSubtitleBU: 'आवाज़, AI विवरण और आवाज़ आदेश',
      UIKey.voiceSubtitleV: 'आवाज़ और आवाज़ आदेश',
      UIKey.notifications: 'सूचनाएं',
      UIKey.pushNotifications: 'पुश नोटिफिकेशन',
      UIKey.receivingRequests: 'ऑनलाइन होने पर मदद अनुरोध प्राप्त हो रहे हैं',
      UIKey.notificationsDisabled: 'सूचनाएं अक्षम',
      UIKey.soundAndVibration: 'ध्वनि और कंपन',
      UIKey.forIncomingCallAlerts: 'आने वाली कॉल अलर्ट के लिए',
      UIKey.account: 'खाता',
      UIKey.signOut: 'साइन आउट',
      UIKey.editProfile: 'प्रोफ़ाइल और फोटो संपादित करें',
      UIKey.editProfilePhoto: 'प्रोफ़ाइल और फोटो संपादित करें',
      UIKey.uploadPhoto: 'डिवाइस से फोटो अपलोड करें',
      UIKey.enterDisplayName: 'प्रदर्शन नाम दर्ज करें',
      UIKey.cancel: 'रद्द करें',
      UIKey.save: 'सेव करें',
      UIKey.photoUpdated: 'प्रोफ़ाइल फोटो सफलतापूर्वक अपडेट हो गई!',
      UIKey.user: 'उपयोगकर्ता',
      UIKey.volunteer: 'स्वयंसेवक',
      UIKey.dashboard: 'डैशबोर्ड',
      UIKey.youreOnline: 'आप ऑनलाइन हैं',
      UIKey.youreOffline: 'आप ऑफ़लाइन हैं',
      UIKey.readyToReceive: 'मदद अनुरोध प्राप्त करने के लिए तैयार',
      UIKey.tapToStartVolunteering: 'स्वयंसेवा शुरू करने के लिए टैप करें',
      UIKey.availabilityToggleOnline: 'उपलब्धता टॉगल। वर्तमान में ऑनलाइन। ऑफ़लाइन होने के लिए टैप करें।',
      UIKey.availabilityToggleOffline: 'उपलब्धता टॉगल। वर्तमान में ऑफ़लाइन। ऑनलाइन होने के लिए टैप करें।',
      UIKey.callsHelped: 'कॉल सहायता',
      UIKey.timeGiven: 'दिया गया समय',
      UIKey.recentActivity: 'हालिया गतिविधि',
      UIKey.noCallsYet: 'अभी तक कोई कॉल नहीं',
      UIKey.goOnlineToStartHelping: 'मदद शुरू करने के लिए ऑनलाइन जाएँ!',
      UIKey.helpedUser: '{x} की मदद की',
      UIKey.assistedBy: '{x} द्वारा सहायता',
      UIKey.fullHistory: 'पूरा इतिहास',
      UIKey.justNow: 'अभी',
      UIKey.daysAgo: '{x} दिन पहले',
      UIKey.hoursAgo: '{x} घंटे पहले',
      UIKey.minutesAgo: '{x} मिनट पहले',
      UIKey.durationLabel: 'अवधि: {x}',
      UIKey.callHistory: 'कॉल इतिहास',
      UIKey.noCallHistoryYet: 'अभी तक कोई कॉल इतिहास नहीं',
      UIKey.historyWillAppearHere: 'आपका कॉल इतिहास यहाँ दिखेगा',
      UIKey.goOnlineToStartHelpingExcl: 'मदद शुरू करने के लिए ऑनलाइन जाएं!',
      UIKey.visuallyImpairedUser: 'दृष्टिबाधित उपयोगकर्ता',
      UIKey.communityVolunteer: 'समुदाय स्वयंसेवक',
      UIKey.hello: 'नमस्ते,',
      UIKey.aiVisualAssist: 'AI दृश्य सहायता',
      UIKey.tapToSeeAround: 'अपने आस-पास देखने के लिए टैप करें',
      UIKey.aiAssistSemantics: 'AI दृश्य सहायता। अपने आस-पास का दृश्य AI द्वारा जानने के लिए टैप करें।',
      UIKey.history: 'इतिहास',
      UIKey.readText: 'टेक्स्ट पढ़ें',
      UIKey.openSettingsSemantics: 'सेटिंग्स खोलें',
      UIKey.readTextOcr: 'टेक्स्ट पढ़ें (OCR)',
      UIKey.extractedText: 'निकाला गया टेक्स्ट',
      UIKey.tapToSpeakStop: 'बोलने/रुकने के लिए टैप करें',
      UIKey.readTextOutLoud: 'टेक्स्ट पढ़ें',
      UIKey.pointCameraHint: 'कैमरा किसी टेक्स्ट, साइन या दस्तावेज़ की ओर रखें और पढ़ें बटन दबाएँ।',
      UIKey.hiPointCameraHint: 'कैमरा किसी टेक्स्ट, साइन या दस्तावेज़ की ओर रखें और पढ़ें बटन दबाएँ।',
      UIKey.emergencySos: 'आपातकालीन SOS',
      UIKey.sosShareLocation: 'यह आपकी लाइव लोकेशन\nआपातकालीन संपर्कों के साथ साझा करेगा।',
      UIKey.sosCancel: 'रद्द करें',
      UIKey.sendingSos: 'SOS भेजा जा रहा है...',
      UIKey.sendingSosIn: 'SOS भेजा जा रहा है',
      UIKey.sosActivated: 'SOS सक्रिय! आपातकालीन संपर्कों को सूचित किया जा रहा है।',
      UIKey.incomingCall: 'इनकमिंग कॉल',
      UIKey.someoneNeedsHelp: 'किसी को आपकी\nमदद चाहिए',
      UIKey.pickedUpByOther: 'यह अनुरोध किसी अन्य स्वयंसेवक ने उठा लिया।',
      UIKey.connectingLiveCall: 'लाइव कॉल कनेक्ट हो रही है...',
      UIKey.requestingLiveAssistance: 'एक दृष्टिबाधित उपयोगकर्ता लाइव\nविज़ुअल सहायता का अनुरोध कर रहा है',
      UIKey.decline: 'अस्वीकार करें',
      UIKey.accept: 'स्वीकार करें',
      UIKey.connectingVideo: 'लाइव वीडियो कनेक्ट हो रहा है...',
      UIKey.assistingWith: 'सहायता में · {x}',
      UIKey.describeClearlyHint: 'आप जो देख रहे हैं उसे स्पष्ट बताएं — उपयोगकर्ता आपको सुन सकता है।',
      UIKey.mute: 'म्यूट',
      UIKey.unmute: 'अनम्यूट',
      UIKey.speaker: 'स्पीकर',
      UIKey.earpiece: 'ईयरपीस',
      UIKey.connected: 'कनेक्टेड',
      UIKey.waitingForVolunteer: 'स्वयंसेवक की प्रतीक्षा...',
      UIKey.endCall: 'कॉल समाप्त करें',
      UIKey.callAnswered: 'कॉल उठा ली गई',
      UIKey.callRequestExpired: 'कॉल अनुरोध समाप्त या अमान्य है।',
      UIKey.callClaimedOrCancelled: 'कॉल पहले ही किसी अन्य स्वयंसेवक द्वारा ले लिया गया या रद्द कर दिया गया।',
      UIKey.failedToAcceptCall: 'कॉल स्वीकार करने में विफल: {x}',
      UIKey.goBack: 'वापस जाएँ',
      UIKey.analyzingStatus: 'विश्लेषण...',
      UIKey.skipOnboarding: 'ऑनबोर्डिंग छोड़ें',
      UIKey.skip: 'छोड़ें',
      UIKey.next: 'अगला',
      UIKey.getStarted: 'शुरू करें',
      UIKey.onboardingStep: 'ऑनबोर्डिंग चरण {x}',
      UIKey.onboardingStepOf: '/ {x}',
      UIKey.visionbridgeLogo: 'विज़नब्रिज लोगो',
      UIKey.callRequestInvalid: 'कॉल अनुरोध समाप्त या अमान्य है।',
      UIKey.voiceSection: 'आवाज़',
      UIKey.ttsSpeed: 'बोलने की गति',
      UIKey.ttsPitch: 'आवाज़ की पिच',
      UIKey.personaTone: 'AI पर्सोना टोन',
      UIKey.personaDesc: 'AI आवाज़ शैली आपकी आयु वर्ग के अनुसार बदलती है',
      UIKey.detectionSection: 'पहचान',
      UIKey.confidenceThreshold: 'AI विश्वास सीमा',
      UIKey.autoDescribe: 'स्वचालित दृश्य विवरण',
      UIKey.autoDescribeDesc: 'AI से स्वचालित दृश्य विवरण',
      UIKey.accessibilitySection: 'सुगमता',
      UIKey.hapticFeedback: 'हैप्टिक फीडबैक',
      UIKey.hapticDesc: 'मुख्य कार्यों पर कंपन',
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
    uiStrings: {
      UIKey.appNameTagline: 'तुमचा AI-चालित दृश्य सहाय्यक',
      UIKey.welcomeTo: 'व्हिजनब्रिजमध्ये\nस्वागत आहे',
      UIKey.loginSubtitle: 'ॲप वापरण्यास सुरुवात करण्यासाठी Google खात्याद्वारे किंवा पडताळणी कोडने साइन इन करा.',
      UIKey.signInWithGoogle: 'Google सह साइन इन करा',
      UIKey.orUseVerificationCode: 'किंवा पडताळणी कोड वापरा',
      UIKey.phoneNumber: 'फोन नंबर',
      UIKey.sendVerificationCode: 'पडताळणी कोड पाठवा',
      UIKey.verificationCode: 'पडताळणी कोड',
      UIKey.enterOtpHint: '६-अंकी कोड टाका',
      UIKey.changeNumber: 'नंबर बदला',
      UIKey.verifyCode: 'कोड पडताळा',
      UIKey.setUpProfile: 'प्रोफाइल सेटअप',
      UIKey.letUsKnowHow: 'तुम्ही VisionBridge कसे वापराल ते सांगा.',
      UIKey.iAm: 'मी...',
      UIKey.visuallyImpaired: 'दृष्टीदोष',
      UIKey.iNeedAssistance: 'मला मदत हवी आहे',
      UIKey.sightedVolunteer: 'स्वयंसेवक',
      UIKey.iWantToHelp: 'मी मदत करू इच्छितो',
      UIKey.displayName: 'प्रदर्शन नाव',
      UIKey.enterYourName: 'तुमचे नाव टाका',
      UIKey.nameRequired: 'नाव आवश्यक आहे',
      UIKey.startUsingVB: 'VisionBridge सुरू करा',
      UIKey.pleaseSelectYourRole: 'कृपया तुमची भूमिका निवडा',
      UIKey.settings: 'सेटिंग्ज',
      UIKey.profile: 'प्रोफाइल',
      UIKey.appearance: 'दिखावा',
      UIKey.theme: 'थीम',
      UIKey.language: 'भाषा / Language',
      UIKey.voiceLanguageSubtitle: 'आवाज, AI वर्णन आणि आवाज आदेश',
      UIKey.chooseVoiceLanguage: 'आवाजाची भाषा निवडा',
      UIKey.voiceSubtitleBU: 'आवाज, AI वर्णन आणि आवाज आदेश',
      UIKey.voiceSubtitleV: 'आवाज आणि आवाज आदेश',
      UIKey.notifications: 'सूचना',
      UIKey.pushNotifications: 'पुश सूचना',
      UIKey.receivingRequests: 'ऑनलाइन असताना मदत विनंत्या मिळत आहेत',
      UIKey.notificationsDisabled: 'सूचना बंद',
      UIKey.soundAndVibration: 'ध्वनी आणि कंपन',
      UIKey.forIncomingCallAlerts: 'येणाऱ्या कॉल सूचनांसाठी',
      UIKey.account: 'खाते',
      UIKey.signOut: 'साइन आउट',
      UIKey.editProfile: 'प्रोफाइल आणि फोटो संपादित करा',
      UIKey.editProfilePhoto: 'प्रोफाइल आणि फोटो संपादित करा',
      UIKey.uploadPhoto: 'डिव्हाइसमधून फोटो अपलोड करा',
      UIKey.enterDisplayName: 'प्रदर्शन नाव टाका',
      UIKey.cancel: 'रद्द करा',
      UIKey.save: 'जतन करा',
      UIKey.photoUpdated: 'प्रोफाइल फोटो यशस्वीरित्या अपडेट झाले!',
      UIKey.user: 'वापरकर्ता',
      UIKey.volunteer: 'स्वयंसेवक',
      UIKey.dashboard: 'डॅशबोर्ड',
      UIKey.youreOnline: 'तुम्ही ऑनलाइन आहात',
      UIKey.youreOffline: 'तुम्ही ऑफलाइन आहात',
      UIKey.readyToReceive: 'मदत विनंत्या मिळवण्यासाठी तयार',
      UIKey.tapToStartVolunteering: 'स्वयंसेवा सुरू करण्यासाठी टॅप करा',
      UIKey.availabilityToggleOnline: 'उपलब्धता टॉगल. सध्या ऑनलाइन. ऑफलाइन जाण्यासाठी टॅप करा.',
      UIKey.availabilityToggleOffline: 'उपलब्धता टॉगल. सध्या ऑफलाइन. ऑनलाइन येण्यासाठी टॅप करा.',
      UIKey.callsHelped: 'कॉल मदत',
      UIKey.timeGiven: 'दिलेला वेळ',
      UIKey.recentActivity: 'अलीकडील क्रियाकलाप',
      UIKey.noCallsYet: 'अजून कोणतीही कॉल नाही',
      UIKey.goOnlineToStartHelping: 'मदत सुरू करण्यासाठी ऑनलाइन या!',
      UIKey.helpedUser: '{x} यांना मदत केली',
      UIKey.assistedBy: '{x} यांच्याकडून मदत',
      UIKey.fullHistory: 'संपूर्ण इतिहास',
      UIKey.justNow: 'आत्ताच',
      UIKey.daysAgo: '{x} दिवसांपूर्वी',
      UIKey.hoursAgo: '{x} तासांपूर्वी',
      UIKey.minutesAgo: '{x} मिनिटांपूर्वी',
      UIKey.durationLabel: 'कालावधी: {x}',
      UIKey.callHistory: 'कॉल इतिहास',
      UIKey.noCallHistoryYet: 'अजून कॉल इतिहास नाही',
      UIKey.historyWillAppearHere: 'तुमचा कॉल इतिहास येथे दिसेल',
      UIKey.goOnlineToStartHelpingExcl: 'मदत सुरू करण्यासाठी ऑनलाइन या!',
      UIKey.visuallyImpairedUser: 'दृष्टीदोष वापरकर्ता',
      UIKey.communityVolunteer: 'समुदाय स्वयंसेवक',
      UIKey.hello: 'नमस्कार,',
      UIKey.aiVisualAssist: 'AI दृश्य सहाय्य',
      UIKey.tapToSeeAround: 'आसपास काय आहे ते पाहण्यासाठी टॅप करा',
      UIKey.aiAssistSemantics: 'AI दृश्य सहाय्य. AI-चालित दृश्य वर्णन मिळवण्यासाठी कॅमेरा उघडण्यासाठी टॅप करा.',
      UIKey.history: 'इतिहास',
      UIKey.readText: 'मजकूर वाचा',
      UIKey.openSettingsSemantics: 'सेटिंग्ज उघडा',
      UIKey.readTextOcr: 'मजकूर वाचा (OCR)',
      UIKey.extractedText: 'काढलेला मजकूर',
      UIKey.tapToSpeakStop: 'बोलण्यासाठी/थांबवण्यासाठी टॅप करा',
      UIKey.readTextOutLoud: 'मजकूर वाचा',
      UIKey.pointCameraHint: 'कोणत्याही मजकुराकडे, चिन्हाकडे किंवा दस्तऐवजाकडे कॅमेरा धरा आणि वाचा दाबा.',
      UIKey.hiPointCameraHint: 'कोणत्याही मजकुराकडे, चिन्हाकडे किंवा दस्तऐवजाकडे कॅमेरा धरा आणि वाचा दाबा.',
      UIKey.emergencySos: 'आपत्कालीन SOS',
      UIKey.sosShareLocation: 'हे तुमचे लाइव्ह स्थान\nआपत्कालीन संपर्कांसोबत सामायिक करेल.',
      UIKey.sosCancel: 'रद्द करा',
      UIKey.sendingSos: 'SOS पाठवत आहे...',
      UIKey.sendingSosIn: 'SOS पाठवत आहे',
      UIKey.sosActivated: 'SOS सक्रिय! आपत्कालीन संपर्कांना सूचित करत आहे.',
      UIKey.incomingCall: 'येणारा कॉल',
      UIKey.someoneNeedsHelp: 'कोणाला तुमच्या\nमदतीची गरज आहे',
      UIKey.pickedUpByOther: 'ही विनंती दुसऱ्या स्वयंसेवकाने घेतली आहे.',
      UIKey.connectingLiveCall: 'लाइव्ह कॉल कनेक्ट होत आहे...',
      UIKey.requestingLiveAssistance: 'दृष्टीदोष वापरकर्ता लाइव्ह\nदृश्य सहाय्य मागत आहे',
      UIKey.decline: 'नाकारा',
      UIKey.accept: 'स्वीकारा',
      UIKey.connectingVideo: 'लाइव्ह व्हिडिओ कनेक्ट होत आहे...',
      UIKey.assistingWith: 'मदत करत आहे · {x}',
      UIKey.describeClearlyHint: 'तुम्ही काय पाहता ते स्पष्ट सांगा — वापरकर्ता तुम्हाला ऐकू शकतो.',
      UIKey.mute: 'म्यूट',
      UIKey.unmute: 'अनम्यूट',
      UIKey.speaker: 'स्पीकर',
      UIKey.earpiece: 'इअरपिस',
      UIKey.connected: 'कनेक्ट झाले',
      UIKey.waitingForVolunteer: 'स्वयंसेवकाची वाट पाहत आहे...',
      UIKey.endCall: 'कॉल समाप्त करा',
      UIKey.callAnswered: 'कॉल घेतला गया',
      UIKey.callRequestExpired: 'कॉल विनंती कालबाह्य किंवा अवैध आहे.',
      UIKey.callClaimedOrCancelled: 'कॉल आधीच दुसऱ्या स्वयंसेवकाने घेतला किंवा रद्द केला आहे.',
      UIKey.failedToAcceptCall: 'कॉल स्वीकारण्यात अयशस्वी: {x}',
      UIKey.goBack: 'मागे जा',
      UIKey.analyzingStatus: 'विश्लेषण...',
      UIKey.skipOnboarding: 'ऑनबोर्डिंग वगळा',
      UIKey.skip: 'वगळा',
      UIKey.next: 'पुढे',
      UIKey.getStarted: 'सुरू करा',
      UIKey.onboardingStep: 'ऑनबोर्डिंग टप्पा {x}',
      UIKey.onboardingStepOf: '/ {x}',
      UIKey.visionbridgeLogo: 'व्हिजनब्रिज लोगो',
      UIKey.callRequestInvalid: 'कॉल विनंती कालबाह्य किंवा अवैध आहे.',
      UIKey.voiceSection: 'आवाज',
      UIKey.ttsSpeed: 'बोलण्याची गती',
      UIKey.ttsPitch: 'आवाजाची पिच',
      UIKey.personaTone: 'AI पर्सना टोन',
      UIKey.personaDesc: 'AI आवाज शैली तुमच्या वयोगटानुसार बदलते',
      UIKey.detectionSection: 'ओळख',
      UIKey.confidenceThreshold: 'AI विश्वास मर्यादा',
      UIKey.autoDescribe: 'स्वयंचलित दृश्य वर्णन',
      UIKey.autoDescribeDesc: 'AI कडून स्वयंचलित दृश्य वर्णन',
      UIKey.accessibilitySection: 'सुलभता',
      UIKey.hapticFeedback: 'हॅप्टिक अभिप्राय',
      UIKey.hapticDesc: 'मुख्य कृतींवर कंपन',
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
    uiStrings: {
      UIKey.appNameTagline: 'உங்கள் AI-இயங்கு காட்சி உதவியாளர்',
      UIKey.welcomeTo: 'விஷன்பிரிட்ஜில்\nவரவேற்கிறோம்',
      UIKey.loginSubtitle: 'ஆப்பைப் பயன்படுத்தத் தொடங்க Google கணக்கு அல்லது சரிபார்ப்பு குறியீடு மூலம் உள்நுழையுங்கள்.',
      UIKey.signInWithGoogle: 'Google மூலம் உள்நுழையுங்கள்',
      UIKey.orUseVerificationCode: 'அல்லது சரிபார்ப்பு குறியீட்டைப் பயன்படுத்துங்கள்',
      UIKey.phoneNumber: 'தொலைபேசி எண்',
      UIKey.sendVerificationCode: 'சரிபார்ப்பு குறியீட்டை அனுப்பு',
      UIKey.verificationCode: 'சரிபார்ப்பு குறியீடு',
      UIKey.enterOtpHint: '6 இலக்க குறியீட்டை உள்ளிடுங்கள்',
      UIKey.changeNumber: 'எண்ணை மாற்று',
      UIKey.verifyCode: 'குறியீட்டை சரிபார்க்கவும்',
      UIKey.setUpProfile: 'சுயவிவர அமைப்பு',
      UIKey.letUsKnowHow: 'VisionBridge-ஐ எவ்வாறு பயன்படுத்துவீர்கள் என்று எங்களிடம் தெரிவிக்கவும்.',
      UIKey.iAm: 'நான்...',
      UIKey.visuallyImpaired: 'பார்வையற்றவர்',
      UIKey.iNeedAssistance: 'எனக்கு உதவி தேவை',
      UIKey.sightedVolunteer: 'தன்னார்வலர்',
      UIKey.iWantToHelp: 'நான் உதவ விரும்புகிறேன்',
      UIKey.displayName: 'காட்சி பெயர்',
      UIKey.enterYourName: 'உங்கள் பெயரை உள்ளிடுங்கள்',
      UIKey.nameRequired: 'பெயர் தேவை',
      UIKey.startUsingVB: 'VisionBridge-ஐத் தொடங்குங்கள்',
      UIKey.pleaseSelectYourRole: 'உங்கள் பங்கைத் தேர்ந்தெடுக்கவும்',
      UIKey.settings: 'அமைப்புகள்',
      UIKey.profile: 'சுயவிவரம்',
      UIKey.appearance: 'தோற்றம்',
      UIKey.theme: 'தீம்',
      UIKey.language: 'மொழி / Language',
      UIKey.voiceLanguageSubtitle: 'குரல், AI விவரணம் மற்றும் குரல் கட்டளைகள்',
      UIKey.chooseVoiceLanguage: 'குரல் மொழியைத் தேர்வு செய்யுங்கள்',
      UIKey.voiceSubtitleBU: 'குரல், AI விவரணம் மற்றும் குரல் கட்டளைகள்',
      UIKey.voiceSubtitleV: 'குரல் மற்றும் குரல் கட்டளைகள்',
      UIKey.notifications: 'அறிவிப்புகள்',
      UIKey.pushNotifications: 'புஷ் அறிவிப்புகள்',
      UIKey.receivingRequests: 'ஆன்லைனில் இருக்கும்போது உதவி கோரிக்கைகள் பெறப்படுகின்றன',
      UIKey.notificationsDisabled: 'அறிவிப்புகள் முடக்கப்பட்டுள்ளன',
      UIKey.soundAndVibration: 'ஒலி மற்றும் அதிர்வு',
      UIKey.forIncomingCallAlerts: 'வருகை அழைப்பு எச்சரிக்கைகளுக்கு',
      UIKey.account: 'கணக்கு',
      UIKey.signOut: 'வெளியேறு',
      UIKey.editProfile: 'சுயவிவரம் மற்றும் புகைப்படத்தைத் திருத்து',
      UIKey.editProfilePhoto: 'சுயவிவரம் மற்றும் புகைப்படத்தைத் திருத்து',
      UIKey.uploadPhoto: 'சாதனத்திலிருந்து புகைப்படத்தைப் பதிவேற்று',
      UIKey.enterDisplayName: 'காட்சி பெயரை உள்ளிடுங்கள்',
      UIKey.cancel: 'ரத்து செய்',
      UIKey.save: 'சேமி',
      UIKey.photoUpdated: 'சுயவிவர புகைப்படம் வெற்றிகரமாக புதுப்பிக்கப்பட்டது!',
      UIKey.user: 'பயனர்',
      UIKey.volunteer: 'தன்னார்வலர்',
      UIKey.dashboard: 'டாஷ்போர்டு',
      UIKey.youreOnline: 'நீங்கள் ஆன்லைனில் உள்ளீர்கள்',
      UIKey.youreOffline: 'நீங்கள் ஆஃப்லைனில் உள்ளீர்கள்',
      UIKey.readyToReceive: 'உதவி கோரிக்கைகளைப் பெற தயாராக உள்ளது',
      UIKey.tapToStartVolunteering: 'தன்னார்வத்தைத் தொடங்க தட்டவும்',
      UIKey.availabilityToggleOnline: 'கிடைக்கும் தன்மை டாகிள். தற்போது ஆன்லைன். ஆஃப்லைன் செல்ல தட்டவும்.',
      UIKey.availabilityToggleOffline: 'கிடைக்கும் தன்மை டாகிள். தற்போது ஆஃப்லைன். ஆன்லைன் வர தட்டவும்.',
      UIKey.callsHelped: 'அழைப்பு உதவி',
      UIKey.timeGiven: 'வழங்கிய நேரம்',
      UIKey.recentActivity: 'சமீபத்திய செயல்பாடு',
      UIKey.noCallsYet: 'இன்னும் அழைப்புகள் இல்லை',
      UIKey.goOnlineToStartHelping: 'உதவ ஆன்லைனில் வாருங்கள்!',
      UIKey.helpedUser: '{x} அவர்களுக்கு உதவினேன்',
      UIKey.assistedBy: '{x} அவர்களால் உதவி',
      UIKey.fullHistory: 'முழு வரலாறு',
      UIKey.justNow: 'இப்போது',
      UIKey.daysAgo: '{x} நாட்களுக்கு முன்',
      UIKey.hoursAgo: '{x} மணி நேரத்திற்கு முன்',
      UIKey.minutesAgo: '{x} நிமிடங்களுக்கு முன்',
      UIKey.durationLabel: 'கால அளவு: {x}',
      UIKey.callHistory: 'அழைப்பு வரலாறு',
      UIKey.noCallHistoryYet: 'இன்னும் அழைப்பு வரலாறு இல்லை',
      UIKey.historyWillAppearHere: 'உங்கள் அழைப்பு வரலாறு இங்கே தோன்றும்',
      UIKey.goOnlineToStartHelpingExcl: 'உதவ ஆன்லைனில் வாருங்கள்!',
      UIKey.visuallyImpairedUser: 'பார்வையற்ற பயனர்',
      UIKey.communityVolunteer: 'சமூக தன்னார்வலர்',
      UIKey.hello: 'வணக்கம்,',
      UIKey.aiVisualAssist: 'AI காட்சி உதவி',
      UIKey.tapToSeeAround: 'உங்களை சுற்றி என்ன இருக்கிறது என்று பார்க்க தட்டவும்',
      UIKey.aiAssistSemantics: 'AI காட்சி உதவி. AI-இயங்கு காட்சி விவரணம் பெற கேமராவைத் திறக்க தட்டவும்.',
      UIKey.history: 'வரலாறு',
      UIKey.readText: 'உரையைப் படிக்கவும்',
      UIKey.openSettingsSemantics: 'அமைப்புகளைத் திற',
      UIKey.readTextOcr: 'உரையைப் படிக்கவும் (OCR)',
      UIKey.extractedText: 'பெறப்பட்ட உரை',
      UIKey.tapToSpeakStop: 'பேச/நிறுத்த தட்டவும்',
      UIKey.readTextOutLoud: 'உரையைப் படிக்கவும்',
      UIKey.pointCameraHint: 'ஏதேனும் உரை, அடையாள அல்லது ஆவணத்தை நோக்கி கேமராவை சூட்டி படிக்கவும் தட்டவும்.',
      UIKey.hiPointCameraHint: 'ஏதேனும் உரை, அடையாள அல்லது ஆவணத்தை நோக்கி கேமராவை சூட்டி படிக்கவும் தட்டவும்.',
      UIKey.emergencySos: 'அவசர SOS',
      UIKey.sosShareLocation: 'இது உங்கள் நேரடி இருப்பிடத்தை\nஅவசர தொடர்புகளுடன் பகிரும்.',
      UIKey.sosCancel: 'ரத்து செய்',
      UIKey.sendingSos: 'SOS அனுப்பப்படுகிறது...',
      UIKey.sendingSosIn: 'SOS அனுப்பப்படுகிறது',
      UIKey.sosActivated: 'SOS செயல்படுத்தப்பட்டது! அவசர தொடர்புகளுக்கு தெரிவிக்கப்படுகிறது.',
      UIKey.incomingCall: 'வருகை அழைப்பு',
      UIKey.someoneNeedsHelp: 'யாருக்கோ உங்கள்\nஉதவி தேவை',
      UIKey.pickedUpByOther: 'இந்த கோரிக்கையை மற்றொரு தன்னார்வலர் ஏற்றுக்கொண்டார்.',
      UIKey.connectingLiveCall: 'நேரடி அழைப்பு இணைக்கப்படுகிறது...',
      UIKey.requestingLiveAssistance: 'பார்வையற்ற பயனர் நேரடி\nகாட்சி உதவியைக் கோருகிறார்',
      UIKey.decline: 'நிராகரி',
      UIKey.accept: 'ஏற்றுக்கொள்',
      UIKey.connectingVideo: 'நேரடி வீடியோ இணைக்கப்படுகிறது...',
      UIKey.assistingWith: 'உதவுகிறது · {x}',
      UIKey.describeClearlyHint: 'நீங்கள் பார்ப்பதை தெளிவாக விவரியுங்கள் — பயனர் உங்களைக் கேட்கலாம்.',
      UIKey.mute: 'மைக் அணை',
      UIKey.unmute: 'மைக் அணைவி',
      UIKey.speaker: 'ஸ்பீக்கர்',
      UIKey.earpiece: 'இயர்பீஸ்',
      UIKey.connected: 'இணைக்கப்பட்டது',
      UIKey.waitingForVolunteer: 'தன்னார்வலருக்காக காத்திருக்கிறது...',
      UIKey.endCall: 'அழைப்பை முடி',
      UIKey.callAnswered: 'அழைப்பு ஏற்றுக்கொள்ளப்பட்டது',
      UIKey.callRequestExpired: 'அழைப்பு கோரிக்கை காலாவதியானது அல்லது தவறானது.',
      UIKey.callClaimedOrCancelled: 'அழைப்பு ஏற்கனவே மற்றொரு தன்னார்வலரால் எடுக்கப்பட்டது அல்லது ரத்து செய்யப்பட்டது.',
      UIKey.failedToAcceptCall: 'அழைப்பை ஏற்க முடியவில்லை: {x}',
      UIKey.goBack: 'பின்செல்',
      UIKey.analyzingStatus: 'பகுப்பாய்வு...',
      UIKey.skipOnboarding: 'ஆன்போர்டிங் தவிர்',
      UIKey.skip: 'தவிர்',
      UIKey.next: 'அடுத்து',
      UIKey.getStarted: 'தொடங்கு',
      UIKey.onboardingStep: 'ஆன்போர்டிங் படி {x}',
      UIKey.onboardingStepOf: '/ {x}',
      UIKey.visionbridgeLogo: 'விஷன்பிரிட்ஜ் லோகோ',
      UIKey.callRequestInvalid: 'அழைப்பு கோரிக்கை காலாவதியானது அல்லது தவறானது.',
      UIKey.voiceSection: 'குரல்',
      UIKey.ttsSpeed: 'பேச்சு வேகம்',
      UIKey.ttsPitch: 'குரல் பிட்ச்',
      UIKey.personaTone: 'AI பெர்சனா டோன்',
      UIKey.personaDesc: 'AI குரல் நடை உங்கள் வயதுப் பிரிவுக்கு ஏற்ப மாறும்',
      UIKey.detectionSection: 'கண்டறிதல்',
      UIKey.confidenceThreshold: 'AI நம்பக்கூறு வரம்பு',
      UIKey.autoDescribe: 'தானியங்கு காட்சி விவரணம்',
      UIKey.autoDescribeDesc: 'AI மூலம் தானாக காட்சிகளை விவரித்தல்',
      UIKey.accessibilitySection: 'அணுகல்',
      UIKey.hapticFeedback: 'ஹாப்டிக் பின்னூட்டம்',
      UIKey.hapticDesc: 'முக்கிய செயல்களில் அதிர்வு',
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
    uiStrings: {
      UIKey.appNameTagline: 'మీ AI-ఆధారిత దృశ్య సహాయకుడు',
      UIKey.welcomeTo: 'విజన్‌బ్రిడ్జ్‌కి\nస్వాగతం',
      UIKey.loginSubtitle: 'యాప్ ఉపయోగించడం ప్రారంభించడానికి Google ఖాతా లేదా ధృవీకరణ కోడ్‌తో సైన్ ఇన్ చేయండి.',
      UIKey.signInWithGoogle: 'Googleతో సైన్ ఇన్ చేయండి',
      UIKey.orUseVerificationCode: 'లేదా ధృవీకరణ కోడ్ ఉపయోగించండి',
      UIKey.phoneNumber: 'ఫోన్ నంబర్',
      UIKey.sendVerificationCode: 'ధృవీకరణ కోడ్ పంపండి',
      UIKey.verificationCode: 'ధృవీకరణ కోడ్',
      UIKey.enterOtpHint: '6-అంకెల కోడ్ నమోదు చేయండి',
      UIKey.changeNumber: 'నంబర్ మార్చండి',
      UIKey.verifyCode: 'కోడ్‌ను ధృవీకరించండి',
      UIKey.setUpProfile: 'ప్రొఫైల్ సెటప్',
      UIKey.letUsKnowHow: 'మీరు VisionBridge‌ను ఎలా ఉపయోగిస్తారో మాకు తెలియజేయండి.',
      UIKey.iAm: 'నేను...',
      UIKey.visuallyImpaired: 'దృష్టి లోపం',
      UIKey.iNeedAssistance: 'నాకు సహాయం కావాలి',
      UIKey.sightedVolunteer: 'స్వచ్ఛంద సేవకుడు',
      UIKey.iWantToHelp: 'నేను సహాయం చేయాలనుకుంటున్నాను',
      UIKey.displayName: 'ప్రదర్శన పేరు',
      UIKey.enterYourName: 'మీ పేరు నమోదు చేయండి',
      UIKey.nameRequired: 'పేరు అవసరం',
      UIKey.startUsingVB: 'VisionBridge ప్రారంభించండి',
      UIKey.pleaseSelectYourRole: 'దయచేసి మీ పాత్రను ఎంచుకోండి',
      UIKey.settings: 'సెట్టింగ్‌లు',
      UIKey.profile: 'ప్రొఫైల్',
      UIKey.appearance: 'రూపం',
      UIKey.theme: 'థీమ్',
      UIKey.language: 'భాష / Language',
      UIKey.voiceLanguageSubtitle: 'వాయిస్, AI వివరణలు మరియు వాయిస్ కమాండ్‌లు',
      UIKey.chooseVoiceLanguage: 'వాయిస్ భాషను ఎంచుకోండి',
      UIKey.voiceSubtitleBU: 'వాయిస్, AI వివరణలు మరియు వాయిస్ కమాండ్‌లు',
      UIKey.voiceSubtitleV: 'వాయిస్ మరియు వాయిస్ కమాండ్‌లు',
      UIKey.notifications: 'నోటిఫికేషన్లు',
      UIKey.pushNotifications: 'పుష్ నోటిఫికేషన్లు',
      UIKey.receivingRequests: 'ఆన్‌లైన్‌లో ఉన్నప్పుడు సహాయ అభ్యర్థనలు అందుతున్నాయి',
      UIKey.notificationsDisabled: 'నోటిఫికేషన్లు నిలిపివేయబడ్డాయి',
      UIKey.soundAndVibration: 'ధ్వని మరియు వైబ్రేషన్',
      UIKey.forIncomingCallAlerts: 'రాక కాల్ హెచ్చరికల కోసం',
      UIKey.account: 'ఖాతా',
      UIKey.signOut: 'సైన్ అవుట్',
      UIKey.editProfile: 'ప్రొఫైల్ మరియు ఫోటోను సవరించండి',
      UIKey.editProfilePhoto: 'ప్రొఫైల్ మరియు ఫోటోను సవరించండి',
      UIKey.uploadPhoto: 'పరికరం నుండి ఫోటో అప్‌లోడ్ చేయండి',
      UIKey.enterDisplayName: 'ప్రదర్శన పేరు నమోదు చేయండి',
      UIKey.cancel: 'రద్దు చేయండి',
      UIKey.save: 'సేవ్ చేయండి',
      UIKey.photoUpdated: 'ప్రొఫైల్ ఫోటో విజయవంతంగా నవీకరించబడింది!',
      UIKey.user: 'వినియోగదారు',
      UIKey.volunteer: 'స్వచ్ఛంద సేవకుడు',
      UIKey.dashboard: 'డాష్‌బోర్డ్',
      UIKey.youreOnline: 'మీరు ఆన్‌లైన్‌లో ఉన్నారు',
      UIKey.youreOffline: 'మీరు ఆఫ్‌లైన్‌లో ఉన్నారు',
      UIKey.readyToReceive: 'సహాయ అభ్యర్థనలు స్వీకరించడానికి సిద్ధంగా ఉంది',
      UIKey.tapToStartVolunteering: 'స్వచ్ఛంద సేవ ప్రారంభించడానికి ట్యాప్ చేయండి',
      UIKey.availabilityToggleOnline: 'అందుబాటు టాగుల్. ప్రస్తుతం ఆన్‌లైన్. ఆఫ్‌లైన్ కావడానికి ట్యాప్ చేయండి.',
      UIKey.availabilityToggleOffline: 'అందుబాటు టాగుల్. ప్రస్తుతం ఆఫ్‌లైన్. ఆన్‌లైన్ రావడానికి ట్యాప్ చేయండి.',
      UIKey.callsHelped: 'కాల్ సహాయం',
      UIKey.timeGiven: 'ఇచ్చిన సమయం',
      UIKey.recentActivity: 'ఇటీవలి కార్యకలాపం',
      UIKey.noCallsYet: 'ఇంకా కాల్స్ లేవు',
      UIKey.goOnlineToStartHelping: 'సహాయం చేయడానికి ఆన్‌లైన్‌కి రండి!',
      UIKey.helpedUser: '{x} కు సహాయం చేశాను',
      UIKey.assistedBy: '{x} ద్వారా సహాయం',
      UIKey.fullHistory: 'పూర్తి చరిత్ర',
      UIKey.justNow: 'ఇప్పుడే',
      UIKey.daysAgo: '{x} రోజుల క్రితం',
      UIKey.hoursAgo: '{x} గంటల క్రితం',
      UIKey.minutesAgo: '{x} నిమిషాల క్రితం',
      UIKey.durationLabel: 'వ్యవధి: {x}',
      UIKey.callHistory: 'కాల్ చరిత్ర',
      UIKey.noCallHistoryYet: 'ఇంకా కాల్ చరిత్ర లేదు',
      UIKey.historyWillAppearHere: 'మీ కాల్ చరిత్ర ఇక్కడ కనిపిస్తుంది',
      UIKey.goOnlineToStartHelpingExcl: 'సహాయం చేయడానికి ఆన్‌లైన్‌కి రండి!',
      UIKey.visuallyImpairedUser: 'దృష్టి లోపం వినియోగదారు',
      UIKey.communityVolunteer: 'కమ్యూనిటీ స్వచ్ఛంద సేవకుడు',
      UIKey.hello: 'నమస్కారం,',
      UIKey.aiVisualAssist: 'AI దృశ్య సహాయం',
      UIKey.tapToSeeAround: 'మీ చుట్టూ ఏముందో చూడటానికి ట్యాప్ చేయండి',
      UIKey.aiAssistSemantics: 'AI దృశ్య సహాయం. AI-ఆధారిత దృశ్య వివరణ పొందడానికి కెమెరా తెరవడానికి ట్యాప్ చేయండి.',
      UIKey.history: 'చరిత్ర',
      UIKey.readText: 'టెక్స్ట్ చదువు',
      UIKey.openSettingsSemantics: 'సెట్టింగ్‌లను తెరవండి',
      UIKey.readTextOcr: 'టెక్స్ట్ చదువు (OCR)',
      UIKey.extractedText: 'సేకరించిన టెక్స్ట్',
      UIKey.tapToSpeakStop: 'మాట్లాడటానికి/ఆపడానికి ట్యాప్ చేయండి',
      UIKey.readTextOutLoud: 'టెక్స్ట్ చదువు',
      UIKey.pointCameraHint: 'ఏదైనా టెక్స్ట్, సైన్ లేదా డాక్యుమెంట్ వైపు కెమెరా చూపి చదవండి నొక్కండి.',
      UIKey.hiPointCameraHint: 'ఏదైనా టెక్స్ట్, సైన్ లేదా డాక్యుమెంట్ వైపు కెమెరా చూపి చదవండి నొక్కండి.',
      UIKey.emergencySos: 'అత్యవసర SOS',
      UIKey.sosShareLocation: 'ఇది మీ ప్రత్యక్ష స్థానాన్ని\nఅత్యవసర పరిచయస్తులతో పంచుకుంటుంది.',
      UIKey.sosCancel: 'రద్దు చేయి',
      UIKey.sendingSos: 'SOS పంపుతోంది...',
      UIKey.sendingSosIn: 'SOS పంపుతోంది',
      UIKey.sosActivated: 'SOS సక్రియం! అత్యవసర పరిచయస్తులకు తెలియజేస్తోంది.',
      UIKey.incomingCall: 'రాక కాల్',
      UIKey.someoneNeedsHelp: 'ఎవరైనా మీ\nసహాయం కోరుతున్నారు',
      UIKey.pickedUpByOther: 'ఈ అభ్యర్థనను మరొక స్వచ్ఛంద సేవకుడు స్వీకరించారు.',
      UIKey.connectingLiveCall: 'ప్రత్యక్ష కాల్ కనెక్ట్ అవుతోంది...',
      UIKey.requestingLiveAssistance: 'దృష్టి లోపం ఉన్న వినియోగదారు ప్రత్యక్ష\nదృశ్య సహాయం కోరుతున్నారు',
      UIKey.decline: 'తిరస్కరించండి',
      UIKey.accept: 'అంగీకరించండి',
      UIKey.connectingVideo: 'ప్రత్యక్ష వీడియో కనెక్ట్ అవుతోంది...',
      UIKey.assistingWith: 'సహాయం చేస్తోంది · {x}',
      UIKey.describeClearlyHint: 'మీరు చూసేది స్పష్టంగా వివరించండి — వినియోగదారు మిమ్మల్ని వినగలరు.',
      UIKey.mute: 'మ్యూట్',
      UIKey.unmute: 'అన్‌మ్యూట్',
      UIKey.speaker: 'స్పీకర్',
      UIKey.earpiece: 'ఇయర్‌పీస్',
      UIKey.connected: 'కనెక్ట్ అయింది',
      UIKey.waitingForVolunteer: 'స్వచ్ఛంద సేవకుడి కోసం వేచి ఉంది...',
      UIKey.endCall: 'కాల్ ముగించండి',
      UIKey.callAnswered: 'కాల్ స్వీకరించబడింది',
      UIKey.callRequestExpired: 'కాల్ అభ్యర్థన గడువు ముగిసింది లేదా చెల్లదు.',
      UIKey.callClaimedOrCancelled: 'కాల్ ఇప్పటికే మరొక స్వచ్ఛంద సేవకుడు తీసుకున్నారు లేదా రద్దు చేయబడింది.',
      UIKey.failedToAcceptCall: 'కాల్ స్వీకరించడంలో విఫలమైంది: {x}',
      UIKey.goBack: 'వెనక్కి',
      UIKey.analyzingStatus: 'విశ్లేషణ...',
      UIKey.skipOnboarding: 'ఆన్‌బోర్డింగ్ స్కిప్',
      UIKey.skip: 'స్కిప్',
      UIKey.next: 'తర్వాత',
      UIKey.getStarted: 'ప్రారంభించండి',
      UIKey.onboardingStep: 'ఆన్‌బోర్డింగ్ దశ {x}',
      UIKey.onboardingStepOf: '/ {x}',
      UIKey.visionbridgeLogo: 'విజన్‌బ్రిడ్జ్ లోగో',
      UIKey.callRequestInvalid: 'కాల్ అభ్యర్థన గడువు ముగిసింది లేదా చెల్లదు.',
      UIKey.voiceSection: 'వాయిస్',
      UIKey.ttsSpeed: 'మాట్లాడే వేగం',
      UIKey.ttsPitch: 'వాయిస్ పిచ్',
      UIKey.personaTone: 'AI పర్సోనా టోన్',
      UIKey.personaDesc: 'AI వాయిస్ శైలి మీ వయసు వర్గాన్ని బట్టి మారుతుంది',
      UIKey.detectionSection: 'గుర్తింపు',
      UIKey.confidenceThreshold: 'AI విశ్వాస పరిమితి',
      UIKey.autoDescribe: 'స్వీయచాలిత దృశ్య వివరణ',
      UIKey.autoDescribeDesc: 'AI ద్వారా దృశ్యాలను స్వయంగా వివరించడం',
      UIKey.accessibilitySection: 'ప్రవేశం',
      UIKey.hapticFeedback: 'హాప్టిక్ ఫీడ్‌బ్యాక్',
      UIKey.hapticDesc: 'ముఖ్య చర్యలపై వైబ్రేషన్',
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
    uiStrings: {
      UIKey.appNameTagline: 'আপনার AI-চালিত দৃশ্য সহায়ক',
      UIKey.welcomeTo: 'ভিশনব্রিজে\nস্বাগতম',
      UIKey.loginSubtitle: 'অ্যাপ ব্যবহার শুরু করতে Google অ্যাকাউন্ট বা যাচাইকরণ কোড দিয়ে সাইন ইন করুন।',
      UIKey.signInWithGoogle: 'Google দিয়ে সাইন ইন করুন',
      UIKey.orUseVerificationCode: 'অথবা যাচাইকরণ কোড ব্যবহার করুন',
      UIKey.phoneNumber: 'ফোন নম্বর',
      UIKey.sendVerificationCode: 'যাচাইকরণ কোড পাঠান',
      UIKey.verificationCode: 'যাচাইকরণ কোড',
      UIKey.enterOtpHint: '৬-সংখ্যার কোড লিখুন',
      UIKey.changeNumber: 'নম্বর পরিবর্তন করুন',
      UIKey.verifyCode: 'কোড যাচাই করুন',
      UIKey.setUpProfile: 'প্রোফাইল সেটআপ',
      UIKey.letUsKnowHow: 'আপনি কীভাবে VisionBridge ব্যবহার করবেন জানান।',
      UIKey.iAm: 'আমি...',
      UIKey.visuallyImpaired: 'দৃষ্টি প্রতিবন্ধী',
      UIKey.iNeedAssistance: 'আমার সহায়তা দরকার',
      UIKey.sightedVolunteer: 'স্বেচ্ছাসেবক',
      UIKey.iWantToHelp: 'আমি সাহায্য করতে চাই',
      UIKey.displayName: 'প্রদর্শন নাম',
      UIKey.enterYourName: 'আপনার নাম লিখুন',
      UIKey.nameRequired: 'নাম প্রয়োজন',
      UIKey.startUsingVB: 'VisionBridge শুরু করুন',
      UIKey.pleaseSelectYourRole: 'অনুগ্রহ করে আপনার ভূমিকা নির্বাচন করুন',
      UIKey.settings: 'সেটিংস',
      UIKey.profile: 'প্রোফাইল',
      UIKey.appearance: 'চেহারা',
      UIKey.theme: 'থিম',
      UIKey.language: 'ভাষা / Language',
      UIKey.voiceLanguageSubtitle: 'ভয়েস, AI বর্ণনা এবং ভয়েস কমান্ড',
      UIKey.chooseVoiceLanguage: 'ভয়েস ভাষা নির্বাচন করুন',
      UIKey.voiceSubtitleBU: 'ভয়েস, AI বর্ণনা এবং ভয়েস কমান্ড',
      UIKey.voiceSubtitleV: 'ভয়েস এবং ভয়েস কমান্ড',
      UIKey.notifications: 'বিজ্ঞপ্তি',
      UIKey.pushNotifications: 'পুশ বিজ্ঞপ্তি',
      UIKey.receivingRequests: 'অনলাইনে থাকলে সাহায্যের অনুরোধ আসছে',
      UIKey.notificationsDisabled: 'বিজ্ঞপ্তি বন্ধ',
      UIKey.soundAndVibration: 'শব্দ এবং ভাইব্রেশন',
      UIKey.forIncomingCallAlerts: 'আসন্ন কল সতর্কতার জন্য',
      UIKey.account: 'অ্যাকাউন্ট',
      UIKey.signOut: 'সাইন আউট',
      UIKey.editProfile: 'প্রোফাইল এবং ছবি সম্পাদনা করুন',
      UIKey.editProfilePhoto: 'প্রোফাইল এবং ছবি সম্পাদনা করুন',
      UIKey.uploadPhoto: 'ডিভাইস থেকে ছবি আপলোড করুন',
      UIKey.enterDisplayName: 'প্রদর্শন নাম লিখুন',
      UIKey.cancel: 'বাতিল করুন',
      UIKey.save: 'সংরক্ষণ করুন',
      UIKey.photoUpdated: 'প্রোফাইল ছবি সফলভাবে আপডেট হয়েছে!',
      UIKey.user: 'ব্যবহারকারী',
      UIKey.volunteer: 'স্বেচ্ছাসেবক',
      UIKey.dashboard: 'ড্যাশবোর্ড',
      UIKey.youreOnline: 'আপনি অনলাইনে আছেন',
      UIKey.youreOffline: 'আপনি অফলাইনে আছেন',
      UIKey.readyToReceive: 'সাহায্যের অনুরোধ পেতে প্রস্তুত',
      UIKey.tapToStartVolunteering: 'স্বেচ্ছাসেবা শুরু করতে ট্যাপ করুন',
      UIKey.availabilityToggleOnline: 'উপলব্ধতা টগল. বর্তমানে অনলাইন. অফলাইন হতে ট্যাপ করুন.',
      UIKey.availabilityToggleOffline: 'উপলব্ধতা টগল. বর্তমানে অফলাইন. অনলাইনে আসতে ট্যাপ করুন.',
      UIKey.callsHelped: 'কল সহায়তা',
      UIKey.timeGiven: 'দেওয়া সময়',
      UIKey.recentActivity: 'সাম্প্রতিক কার্যকলাপ',
      UIKey.noCallsYet: 'এখনও কোনো কল নেই',
      UIKey.goOnlineToStartHelping: 'সাহায্য শুরু করতে অনলাইনে আসুন!',
      UIKey.helpedUser: '{x} কে সাহায্য করেছি',
      UIKey.assistedBy: '{x} দ্বারা সহায়তা',
      UIKey.fullHistory: 'সম্পূর্ণ ইতিহাস',
      UIKey.justNow: 'এইমাত্র',
      UIKey.daysAgo: '{x} দিন আগে',
      UIKey.hoursAgo: '{x} ঘণ্টা আগে',
      UIKey.minutesAgo: '{x} মিনিট আগে',
      UIKey.durationLabel: 'সময়কাল: {x}',
      UIKey.callHistory: 'কল ইতিহাস',
      UIKey.noCallHistoryYet: 'এখনও কল ইতিহাস নেই',
      UIKey.historyWillAppearHere: 'আপনার কল ইতিহাস এখানে দেখা যাবে',
      UIKey.goOnlineToStartHelpingExcl: 'সাহায্য শুরু করতে অনলাইনে আসুন!',
      UIKey.visuallyImpairedUser: 'দৃষ্টি প্রতিবন্ধী ব্যবহারকারী',
      UIKey.communityVolunteer: 'কমিউনিটি স্বেচ্ছাসেবক',
      UIKey.hello: 'নমস্কার,',
      UIKey.aiVisualAssist: 'AI দৃশ্য সহায়তা',
      UIKey.tapToSeeAround: 'আপনার চারপাশে কী আছে দেখতে ট্যাপ করুন',
      UIKey.aiAssistSemantics: 'AI দৃশ্য সহায়তা। AI-চালিত দৃশ্য বর্ণনা পেতে ক্যামেরা খুলতে ট্যাপ করুন।',
      UIKey.history: 'ইতিহাস',
      UIKey.readText: 'টেক্সট পড়ুন',
      UIKey.openSettingsSemantics: 'সেটিংস খুলুন',
      UIKey.readTextOcr: 'টেক্সট পড়ুন (OCR)',
      UIKey.extractedText: 'নেওয়া টেক্সট',
      UIKey.tapToSpeakStop: 'বলা/থামানোর জন্য ট্যাপ করুন',
      UIKey.readTextOutLoud: 'টেক্সট পড়ুন',
      UIKey.pointCameraHint: 'যেকোনো টেক্সট, সাইন বা ডকুমেন্টের দিকে ক্যামেরা ধরুন এবং পড়ুন চাপুন।',
      UIKey.hiPointCameraHint: 'যেকোনো টেক্সট, সাইন বা ডকুমেন্টের দিকে ক্যামেরা ধরুন এবং পড়ুন চাপুন।',
      UIKey.emergencySos: 'জরুরি SOS',
      UIKey.sosShareLocation: 'এটি আপনার লাইভ অবস্থান\nজরুরি পরিচিতিগুলির সাথে শেয়ার করবে।',
      UIKey.sosCancel: 'বাতিল করুন',
      UIKey.sendingSos: 'SOS পাঠানো হচ্ছে...',
      UIKey.sendingSosIn: 'SOS পাঠানো হচ্ছে',
      UIKey.sosActivated: 'SOS সক্রিয়! জরুরি পরিচিতিগুলিকে জানানো হচ্ছে।',
      UIKey.incomingCall: 'আসন্ন কল',
      UIKey.someoneNeedsHelp: 'কারো আপনার\nসাহায্য দরকার',
      UIKey.pickedUpByOther: 'এই অনুরোধ অন্য একজন স্বেচ্ছাসেবক গ্রহণ করেছেন।',
      UIKey.connectingLiveCall: 'লাইভ কল সংযোগ হচ্ছে...',
      UIKey.requestingLiveAssistance: 'দৃষ্টি প্রতিবন্ধী ব্যবহারকারী লাইভ\nদৃশ্য সহায়তা চাইছেন',
      UIKey.decline: 'প্রত্যাখ্যান করুন',
      UIKey.accept: 'গ্রহণ করুন',
      UIKey.connectingVideo: 'লাইভ ভিডিও সংযোগ হচ্ছে...',
      UIKey.assistingWith: 'সাহায্য করছে · {x}',
      UIKey.describeClearlyHint: 'আপনি যা দেখছেন স্পষ্টভাবে বর্ণনা করুন — ব্যবহারকারী আপনাকে শুনতে পারেন।',
      UIKey.mute: 'মিউট',
      UIKey.unmute: 'আনমিউট',
      UIKey.speaker: 'স্পিকার',
      UIKey.earpiece: 'ইয়ারপিস',
      UIKey.connected: 'সংযুক্ত',
      UIKey.waitingForVolunteer: 'স্বেচ্ছাসেবকের জন্য অপেক্ষা...',
      UIKey.endCall: 'কল শেষ করুন',
      UIKey.callAnswered: 'কল গৃহীত হয়েছে',
      UIKey.callRequestExpired: 'কল অনুরোধের মেয়াদ শেষ বা অবৈধ।',
      UIKey.callClaimedOrCancelled: 'কল ইতিমধ্যে অন্য স্বেচ্ছাসেবক নিয়েছেন বা বাতিল হয়েছে।',
      UIKey.failedToAcceptCall: 'কল গ্রহণ করতে ব্যর্থ: {x}',
      UIKey.goBack: 'পিছনে যান',
      UIKey.analyzingStatus: 'বিশ্লেষণ...',
      UIKey.skipOnboarding: 'অনবোর্ডিং এড়িয়ে যান',
      UIKey.skip: 'এড়িয়ে যান',
      UIKey.next: 'পরবর্তী',
      UIKey.getStarted: 'শুরু করুন',
      UIKey.onboardingStep: 'অনবোর্ডিং ধাপ {x}',
      UIKey.onboardingStepOf: '/ {x}',
      UIKey.visionbridgeLogo: 'ভিশনব্রিজ লোগো',
      UIKey.callRequestInvalid: 'কল অনুরোধের মেয়াদ শেষ বা অবৈধ।',
      UIKey.voiceSection: 'ভয়েস',
      UIKey.ttsSpeed: 'কথা বলার গতি',
      UIKey.ttsPitch: 'ভয়েস পিচ',
      UIKey.personaTone: 'AI পারসোনা টোন',
      UIKey.personaDesc: 'AI ভয়েস স্টাইল আপনার বয়সের গোষ্ঠী অনুযায়ী পরিবর্তিত হয়',
      UIKey.detectionSection: 'সনাক্তকরণ',
      UIKey.confidenceThreshold: 'AI আত্মবিশ্বাসের সীমা',
      UIKey.autoDescribe: 'স্বয়ংক্রিয় দৃশ্য বর্ণনা',
      UIKey.autoDescribeDesc: 'AI দিয়ে স্বয়ংক্রিয়ভাবে দৃশ্য বর্ণনা',
      UIKey.accessibilitySection: 'অ্যাক্সেসিবিলিটি',
      UIKey.hapticFeedback: 'হ্যাপটিক ফিডব্যাক',
      UIKey.hapticDesc: 'গুরুত্বপূর্ণ ক্রিয়ায় কম্পন',
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
    uiStrings: {
      UIKey.appNameTagline: 'ನಿಮ್ಮ AI-ಚಾಲಿತ ದೃಶ್ಯ ಸಹಾಯಕ',
      UIKey.welcomeTo: 'ವಿಷನ್‌ಬ್ರಿಡ್ಜ್‌ಗೆ\nಸ್ವಾಗತ',
      UIKey.loginSubtitle: 'ಆ್ಯಪ್ ಬಳಸಲು ಪ್ರಾರಂಭಿಸಲು Google ಖಾತೆ ಅಥವಾ ಪರಿಶೀಲನೆ ಕೋಡ್‌ನೊಂದಿಗೆ ಸೈನ್ ಇನ್ ಮಾಡಿ.',
      UIKey.signInWithGoogle: 'Google ಜೊತೆ ಸೈನ್ ಇನ್ ಮಾಡಿ',
      UIKey.orUseVerificationCode: 'ಅಥವಾ ಪರಿಶೀಲನೆ ಕೋಡ್ ಬಳಸಿ',
      UIKey.phoneNumber: 'ಫೋನ್ ಸಂಖ್ಯೆ',
      UIKey.sendVerificationCode: 'ಪರಿಶೀಲನೆ ಕೋಡ್ ಕಳುಹಿಸಿ',
      UIKey.verificationCode: 'ಪರಿಶೀಲನೆ ಕೋಡ್',
      UIKey.enterOtpHint: '6-ಅಂಕಿಯ ಕೋಡ್ ನಮೂದಿಸಿ',
      UIKey.changeNumber: 'ಸಂಖ್ಯೆ ಬದಲಿಸಿ',
      UIKey.verifyCode: 'ಕೋಡ್ ಪರಿಶೀಲಿಸಿ',
      UIKey.setUpProfile: 'ಪ್ರೊಫೈಲ್ ಸೆಟಪ್',
      UIKey.letUsKnowHow: 'ನೀವು VisionBridge ಅನ್ನು ಹೇಗೆ ಬಳಸುತ್ತೀರಿ ಎಂದು ತಿಳಿಸಿ.',
      UIKey.iAm: 'ನಾನು...',
      UIKey.visuallyImpaired: 'ದೃಷ್ಟಿ ಸಮಸ್ಯೆ',
      UIKey.iNeedAssistance: 'ನನಗೆ ಸಹಾಯ ಬೇಕು',
      UIKey.sightedVolunteer: 'ಸ್ವಯಂಸೇವಕ',
      UIKey.iWantToHelp: 'ನಾನು ಸಹಾಯ ಮಾಡಲು ಬಯಸುತ್ತೇನೆ',
      UIKey.displayName: 'ಪ್ರದರ್ಶನ ಹೆಸರು',
      UIKey.enterYourName: 'ನಿಮ್ಮ ಹೆಸರನ್ನು ನಮೂದಿಸಿ',
      UIKey.nameRequired: 'ಹೆಸರು ಅಗತ್ಯವಿದೆ',
      UIKey.startUsingVB: 'VisionBridge ಪ್ರಾರಂಭಿಸಿ',
      UIKey.pleaseSelectYourRole: 'ದಯವಿಟ್ಟು ನಿಮ್ಮ ಪಾತ್ರವನ್ನು ಆಯ್ಕೆ ಮಾಡಿ',
      UIKey.settings: 'ಸೆಟ್ಟಿಂಗ್‌ಗಳು',
      UIKey.profile: 'ಪ್ರೊಫೈಲ್',
      UIKey.appearance: 'ನೋಟ',
      UIKey.theme: 'ಥೀಮ್',
      UIKey.language: 'ಭಾಷೆ / Language',
      UIKey.voiceLanguageSubtitle: 'ಧ್ವನಿ, AI ವಿವರಣೆ ಮತ್ತು ಧ್ವನಿ ಆದೇಶಗಳು',
      UIKey.chooseVoiceLanguage: 'ಧ್ವನಿ ಭಾಷೆಯನ್ನು ಆಯ್ಕೆಮಾಡಿ',
      UIKey.voiceSubtitleBU: 'ಧ್ವನಿ, AI ವಿವರಣೆ ಮತ್ತು ಧ್ವನಿ ಆದೇಶಗಳು',
      UIKey.voiceSubtitleV: 'ಧ್ವನಿ ಮತ್ತು ಧ್ವನಿ ಆದೇಶಗಳು',
      UIKey.notifications: 'ಅಧಿಸೂಚನೆಗಳು',
      UIKey.pushNotifications: 'ಪುಷ್ ಅಧಿಸೂಚನೆಗಳು',
      UIKey.receivingRequests: 'ಆನ್‌ಲೈನ್‌ನಲ್ಲಿರುವಾಗ ಸಹಾಯ ವಿನಂತಿಗಳು ಬರುತ್ತಿವೆ',
      UIKey.notificationsDisabled: 'ಅಧಿಸೂಚನೆಗಳು ನಿಷ್ಕ್ರಿಯಗೊಂಡಿವೆ',
      UIKey.soundAndVibration: 'ಧ್ವನಿ ಮತ್ತು ಕಂಪನ',
      UIKey.forIncomingCallAlerts: 'ಒಳಬರುವ ಕರೆ ಎಚ್ಚರಿಕೆಗಳಿಗಾಗಿ',
      UIKey.account: 'ಖಾತೆ',
      UIKey.signOut: 'ಸೈನ್ ಔಟ್',
      UIKey.editProfile: 'ಪ್ರೊಫೈಲ್ ಮತ್ತು ಫೋಟೋ ಸಂಪಾದಿಸಿ',
      UIKey.editProfilePhoto: 'ಪ್ರೊಫೈಲ್ ಮತ್ತು ಫೋಟೋ ಸಂಪಾದಿಸಿ',
      UIKey.uploadPhoto: 'ಸಾಧನದಿಂದ ಫೋಟೋ ಅಪ್‌ಲೋಡ್ ಮಾಡಿ',
      UIKey.enterDisplayName: 'ಪ್ರದರ್ಶನ ಹೆಸರನ್ನು ನಮೂದಿಸಿ',
      UIKey.cancel: 'ರದ್ದುಮಾಡಿ',
      UIKey.save: 'ಉಳಿಸಿ',
      UIKey.photoUpdated: 'ಪ್ರೊಫೈಲ್ ಫೋಟೋ ಯಶಸ್ವಿಯಾಗಿ ನವೀಕರಿಸಲಾಗಿದೆ!',
      UIKey.user: 'ಬಳಕೆದಾರ',
      UIKey.volunteer: 'ಸ್ವಯಂಸೇವಕ',
      UIKey.dashboard: 'ಡ್ಯಾಶ್‌ಬೋರ್ಡ್',
      UIKey.youreOnline: 'ನೀವು ಆನ್‌ಲೈನ್‌ನಲ್ಲಿದ್ದೀರಿ',
      UIKey.youreOffline: 'ನೀವು ಆಫ್‌ಲೈನ್‌ನಲ್ಲಿದ್ದೀರಿ',
      UIKey.readyToReceive: 'ಸಹಾಯ ವಿನಂತಿಗಳನ್ನು ಸ್ವೀಕರಿಸಲು ಸಿದ್ಧವಾಗಿದೆ',
      UIKey.tapToStartVolunteering: 'ಸ್ವಯಂಸೇವೆ ಪ್ರಾರಂಭಿಸಲು ಟ್ಯಾಪ್ ಮಾಡಿ',
      UIKey.availabilityToggleOnline: 'ಲಭ್ಯತೆ ಟಾಗಲ್. ಪ್ರಸ್ತುತ ಆನ್‌ಲೈನ್. ಆಫ್‌ಲೈನ್ ಆಗಲು ಟ್ಯಾಪ್ ಮಾಡಿ.',
      UIKey.availabilityToggleOffline: 'ಲಭ್ಯತೆ ಟಾಗಲ್. ಪ್ರಸ್ತುತ ಆಫ್‌ಲೈನ್. ಆನ್‌ಲೈನ್ ಆಗಲು ಟ್ಯಾಪ್ ಮಾಡಿ.',
      UIKey.callsHelped: 'ಕರೆ ಸಹಾಯ',
      UIKey.timeGiven: 'ನೀಡಿದ ಸಮಯ',
      UIKey.recentActivity: 'ಇತ್ತೀಚಿನ ಚಟುವಟಿಕೆ',
      UIKey.noCallsYet: 'ಇನ್ನೂ ಯಾವುದೇ ಕರೆಗಳಿಲ್ಲ',
      UIKey.goOnlineToStartHelping: 'ಸಹಾಯ ಮಾಡಲು ಆನ್‌ಲೈನ್‌ಗೆ ಬನ್ನಿ!',
      UIKey.helpedUser: '{x} ಅವರಿಗೆ ಸಹಾಯ ಮಾಡಿದೆ',
      UIKey.assistedBy: '{x} ಅವರಿಂದ ಸಹಾಯ',
      UIKey.fullHistory: 'ಪೂರ್ಣ ಇತಿಹಾಸ',
      UIKey.justNow: 'ಈಗಷ್ಟೇ',
      UIKey.daysAgo: '{x} ದಿನಗಳ ಹಿಂದೆ',
      UIKey.hoursAgo: '{x} ಗಂಟೆಗಳ ಹಿಂದೆ',
      UIKey.minutesAgo: '{x} ನಿಮಿಷಗಳ ಹಿಂದೆ',
      UIKey.durationLabel: 'ಅವಧಿ: {x}',
      UIKey.callHistory: 'ಕರೆ ಇತಿಹಾಸ',
      UIKey.noCallHistoryYet: 'ಇನ್ನೂ ಕರೆ ಇತಿಹಾಸವಿಲ್ಲ',
      UIKey.historyWillAppearHere: 'ನಿಮ್ಮ ಕರೆ ಇತಿಹಾಸ ಇಲ್ಲಿ ಕಾಣಿಸುತ್ತದೆ',
      UIKey.goOnlineToStartHelpingExcl: 'ಸಹಾಯ ಮಾಡಲು ಆನ್‌ಲೈನ್‌ಗೆ ಬನ್ನಿ!',
      UIKey.visuallyImpairedUser: 'ದೃಷ್ಟಿ ಸಮಸ್ಯೆ ಬಳಕೆದಾರ',
      UIKey.communityVolunteer: 'ಸಮುದಾಯ ಸ್ವಯಂಸೇವಕ',
      UIKey.hello: 'ನಮಸ್ಕಾರ,',
      UIKey.aiVisualAssist: 'AI ದೃಶ್ಯ ಸಹಾಯ',
      UIKey.tapToSeeAround: 'ನಿಮ್ಮ ಸುತ್ತಮುತ್ತ ಏನಿದೆ ಎಂದು ನೋಡಲು ಟ್ಯಾಪ್ ಮಾಡಿ',
      UIKey.aiAssistSemantics: 'AI ದೃಶ್ಯ ಸಹಾಯ. AI-ಚಾಲಿತ ದೃಶ್ಯ ವಿವರಣೆ ಪಡೆಯಲು ಕ್ಯಾಮೆರಾ ತೆರೆಯಲು ಟ್ಯಾಪ್ ಮಾಡಿ.',
      UIKey.history: 'ಇತಿಹಾಸ',
      UIKey.readText: 'ಪಠ್ಯ ಓದಿ',
      UIKey.openSettingsSemantics: 'ಸೆಟ್ಟಿಂಗ್‌ಗಳನ್ನು ತೆರೆಯಿರಿ',
      UIKey.readTextOcr: 'ಪಠ್ಯ ಓದಿ (OCR)',
      UIKey.extractedText: 'ಪಡೆದ ಪಠ್ಯ',
      UIKey.tapToSpeakStop: 'ಮಾತನಾಡಲು/ನಿಲ್ಲಿಸಲು ಟ್ಯಾಪ್ ಮಾಡಿ',
      UIKey.readTextOutLoud: 'ಪಠ್ಯ ಓದಿ',
      UIKey.pointCameraHint: 'ಯಾವುದೇ ಪಠ್ಯ, ಚಿಹ್ನೆ ಅಥವಾ ದಸ್ತಾವೇಜಿನ ಕಡೆಗೆ ಕ್ಯಾಮೆರಾ ತೋರಿಸಿ ಓದಿ ಒತ್ತಿರಿ.',
      UIKey.hiPointCameraHint: 'ಯಾವುದೇ ಪಠ್ಯ, ಚಿಹ್ನೆ ಅಥವಾ ದಸ್ತಾವೇಜಿನ ಕಡೆಗೆ ಕ್ಯಾಮೆರಾ ತೋರಿಸಿ ಓದಿ ಒತ್ತಿರಿ.',
      UIKey.emergencySos: 'ತುರ್ತು SOS',
      UIKey.sosShareLocation: 'ಇದು ನಿಮ್ಮ ನೇರ ಸ್ಥಳವನ್ನು\nತುರ್ತು ಸಂಪರ್ಕಗಳೊಂದಿಗೆ ಹಂಚಿಕೊಳ್ಳುತ್ತದೆ.',
      UIKey.sosCancel: 'ರದ್ದುಮಾಡಿ',
      UIKey.sendingSos: 'SOS ಕಳುಹಿಸಲಾಗುತ್ತಿದೆ...',
      UIKey.sendingSosIn: 'SOS ಕಳುಹಿಸಲಾಗುತ್ತಿದೆ',
      UIKey.sosActivated: 'SOS ಸಕ್ರಿಯ! ತುರ್ತು ಸಂಪರ್ಕಗಳಿಗೆ ತಿಳಿಸಲಾಗುತ್ತಿದೆ.',
      UIKey.incomingCall: 'ಒಳಬರುವ ಕರೆ',
      UIKey.someoneNeedsHelp: 'ಯಾರಿಗೊ ನಿಮ್ಮ\nಸಹಾಯ ಬೇಕು',
      UIKey.pickedUpByOther: 'ಈ ವಿನಂತಿಯನ್ನು ಇನ್ನೊಬ್ಬ ಸ್ವಯಂಸೇವಕ ಸ್ವೀಕರಿಸಿದ್ದಾರೆ.',
      UIKey.connectingLiveCall: 'ನೇರ ಕರೆ ಸಂಪರ್ಕಗೊಳ್ಳುತ್ತಿದೆ...',
      UIKey.requestingLiveAssistance: 'ದೃಷ್ಟಿ ಸಮಸ್ಯೆ ಬಳಕೆದಾರ ನೇರ\nದೃಶ್ಯ ಸಹಾಯ ಕೋರುತ್ತಿದ್ದಾರೆ',
      UIKey.decline: 'ನಿರಾಕರಿಸಿ',
      UIKey.accept: 'ಸ್ವೀಕರಿಸಿ',
      UIKey.connectingVideo: 'ನೇರ ವೀಡಿಯೊ ಸಂಪರ್ಕಗೊಳ್ಳುತ್ತಿದೆ...',
      UIKey.assistingWith: 'ಸಹಾಯ ಮಾಡುತ್ತಿದೆ · {x}',
      UIKey.describeClearlyHint: 'ನೀವು ನೋಡುತ್ತಿರುವುದನ್ನು ಸ್ಪಷ್ಟವಾಗಿ ವಿವರಿಸಿ — ಬಳಕೆದಾರರು ನಿಮ್ಮನ್ನು ಕೇಳಬಲ್ಲರು.',
      UIKey.mute: 'ಮ್ಯೂಟ್',
      UIKey.unmute: 'ಅನ್‌ಮ್ಯೂಟ್',
      UIKey.speaker: 'ಸ್ಪೀಕರ್',
      UIKey.earpiece: 'ಇಯರ್‌ಪೀಸ್',
      UIKey.connected: 'ಸಂಪರ್ಕಗೊಂಡಿದೆ',
      UIKey.waitingForVolunteer: 'ಸ್ವಯಂಸೇವಕರಿಗಾಗಿ ಕಾಯುತ್ತಿದೆ...',
      UIKey.endCall: 'ಕರೆ ಕೊನೆಗೊಳಿಸಿ',
      UIKey.callAnswered: 'ಕರೆ ಸ್ವೀಕರಿಸಲಾಗಿದೆ',
      UIKey.callRequestExpired: 'ಕರೆ ವಿನಂತಿ ಅವಧಿ ಮೀರಿದೆ ಅಥವಾ ಅಮಾನ್ಯವಾಗಿದೆ.',
      UIKey.callClaimedOrCancelled: 'ಕರೆಯನ್ನು ಈಗಾಗಲೇ ಇನ್ನೊಬ್ಬ ಸ್ವಯಂಸೇವಕ ಸ್ವೀಕರಿಸಿದ್ದಾರೆ ಅಥವಾ ರದ್ದುಮಾಡಲಾಗಿದೆ.',
      UIKey.failedToAcceptCall: 'ಕರೆ ಸ್ವೀಕರಿಸಲು ವಿಫಲವಾಗಿದೆ: {x}',
      UIKey.goBack: 'ಹಿಂದೆ ಹೋಗಿ',
      UIKey.analyzingStatus: 'ವಿಶ್ಲೇಷಣ...',
      UIKey.skipOnboarding: 'ಆನ್‌ಬೋರ್ಡಿಂಗ್ ಬಿಟ್ಟುಬಿಡಿ',
      UIKey.skip: 'ಬಿಟ್ಟುಬಿಡಿ',
      UIKey.next: 'ಮುಂದೆ',
      UIKey.getStarted: 'ಪ್ರಾರಂಭಿಸಿ',
      UIKey.onboardingStep: 'ಆನ್‌ಬೋರ್ಡಿಂಗ್ ಹಂತ {x}',
      UIKey.onboardingStepOf: '/ {x}',
      UIKey.visionbridgeLogo: 'ವಿಷನ್‌ಬ್ರಿಡ್ಜ್ ಲೋಗೋ',
      UIKey.callRequestInvalid: 'ಕರೆ ವಿನಂತಿ ಅವಧಿ ಮೀರಿದೆ ಅಥವಾ ಅಮಾನ್ಯವಾಗಿದೆ.',
      UIKey.voiceSection: 'ಧ್ವನಿ',
      UIKey.ttsSpeed: 'ಮಾತನಾಡುವ ವೇಗ',
      UIKey.ttsPitch: 'ಧ್ವನಿ ಪಿಚ್',
      UIKey.personaTone: 'AI ಪರ್ಸೋನಾ ಟೋನ್',
      UIKey.personaDesc: 'AI ಧ್ವನಿ ಶೈಲಿ ನಿಮ್ಮ ವಯಸ್ಸಿನ ಗುಂಪಿಗೆ ಅನುಗುಣವಾಗಿ ಬದಲಾಗುತ್ತದೆ',
      UIKey.detectionSection: 'ಪತ್ತೆ',
      UIKey.confidenceThreshold: 'AI ವಿಶ್ವಾಸ ಮಿತಿ',
      UIKey.autoDescribe: 'ಸ್ವಯಂಚಾಲಿತ ದೃಶ್ಯ ವಿವರಣೆ',
      UIKey.autoDescribeDesc: 'AI ಮೂಲಕ ಸ್ವಯಂಚಾಲಿತವಾಗಿ ದೃಶ್ಯಗಳನ್ನು ವಿವರಿಸುವುದು',
      UIKey.accessibilitySection: 'ಪ್ರವೇಶಿಸುವಿಕೆ',
      UIKey.hapticFeedback: 'ಹ್ಯಾಪ್ಟಿಕ್ ಪ್ರತಿಕ್ರಿಯೆ',
      UIKey.hapticDesc: 'ಪ್ರಮುಖ ಕ್ರಿಯೆಗಳಲ್ಲಿ ಕಂಪನ',
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
