/// Voice & Speech Synthesis Service developed by Shreesh Nalawade
///
/// VisionBridge — TTS/STT Service
///
/// Voice-first UX: TTS speaks descriptions, STT accepts commands.
/// Queue-based: maxTtsQueueDepth = 1 (drop new if busy).
library;

import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';

import 'user_settings_service.dart';

/// Supported voice commands.
enum VoiceCommand {
  help,      // "help" / "what's around me" → start AI assist
  describe,  // "describe" / "what do you see" → trigger scene description
  stop,      // "stop" / "quiet" → stop TTS
  emergency, // "emergency" / "SOS" → activate SOS
  call,      // "call" → request volunteer
  endCall,   // "end call" / "hang up"
  yes,       // confirmation
  no,        // rejection
  unknown,
}

class TTSSTTService {
  TTSSTTService();

  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _stt = stt.SpeechToText();

  bool _isSpeaking = false;
  bool get isSpeaking => _isSpeaking;
  bool _isListening = false;
  bool _isInitialized = false;

  void Function(bool isSpeaking)? onSpeakingStateChanged;

  final _commandController = StreamController<VoiceCommand>.broadcast();
  Stream<VoiceCommand> get commands => _commandController.stream;

  final _rawTranscriptController = StreamController<String>.broadcast();
  Stream<String> get rawTranscripts => _rawTranscriptController.stream;

  /// Initialize TTS + STT engines.
  /// Reads saved speed/pitch from UserSettingsService so slider changes persist.
  /// Also reads the saved locale for language switching.
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Load user-saved TTS preferences (defaults: speed 0.5, pitch 1.0)
    final savedSpeed = await UserSettingsService.getTTSSpeed();
    final savedPitch = await UserSettingsService.getTTSPitch();
    final savedLocale = await UserSettingsService.getLocaleCode();

    // TTS setup with user preferences
    _currentLocaleCode = savedLocale;
    await _tts.setLanguage(_ttsLocaleTag(savedLocale));
    await _tts.setSpeechRate(savedSpeed);
    await _tts.setPitch(savedPitch);
    await _tts.setVolume(1.0);

    _tts.setStartHandler(() {
      _isSpeaking = true;
      onSpeakingStateChanged?.call(true);
    });

    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      onSpeakingStateChanged?.call(false);
    });

    _tts.setCancelHandler(() {
      _isSpeaking = false;
      onSpeakingStateChanged?.call(false);
    });

    _tts.setErrorHandler((msg) {
      _isSpeaking = false;
      onSpeakingStateChanged?.call(false);
    });

    // STT setup
    await _stt.initialize(
      onStatus: (status) {
        _isListening = status == 'listening';
      },
      onError: (error) {
        _isListening = false;
      },
    );

    _isInitialized = true;
  }

  /// Locale code currently in use ('en' or 'hi').
  String _currentLocaleCode = 'en';
  String get currentLocaleCode => _currentLocaleCode;

  /// Map app locale code to TTS/STT BCP-47 locale tag.
  String _ttsLocaleTag(String code) {
    switch (code) {
      case 'hi':
        return 'hi-IN';
      case 'en':
      default:
        return 'en-US';
    }
  }

  /// Switch TTS and STT language at runtime.
  /// Called when user changes language in settings.
  Future<void> setLocale(String localeCode) async {
    _currentLocaleCode = localeCode;
    await _tts.setLanguage(_ttsLocaleTag(localeCode));
  }

  /// Speak text in a specific language, then restore the current app locale.
  /// Used by OCR to read Hindi text as Hindi and English text as English,
  /// independent of the app toggle.
  Future<void> speakWithLanguage(String text, String langCode, {bool force = true}) async {
    if (!_isInitialized) await initialize();

    if (force) {
      await _tts.stop();
    } else if (_isSpeaking) {
      return;
    }

    // Temporarily switch to the detected text language
    final targetTag = _ttsLocaleTag(langCode);
    await _tts.setLanguage(targetTag);

    _isSpeaking = true;
    onSpeakingStateChanged?.call(true);
    await _tts.speak(text);

    // Restore to app locale after speech completes
    // (the completion handler will fire, but we also restore language)
    await _tts.setLanguage(_ttsLocaleTag(_currentLocaleCode));
  }

  // === TTS ===

  /// Speak text. If force is true (default), cancels any ongoing speech first.
  Future<void> speak(String text, {bool force = true}) async {
    if (!_isInitialized) await initialize();

    if (force) {
      await _tts.stop();
    } else if (_isSpeaking) {
      return;
    }

    _isSpeaking = true;
    onSpeakingStateChanged?.call(true);
    await _tts.speak(text);
  }

  /// Immediately stop TTS.
  Future<void> stopSpeaking() async {
    _isSpeaking = false;
    await _tts.stop();
    onSpeakingStateChanged?.call(false);
  }

  /// Update TTS speed (0.0 to 1.0).
  Future<void> setSpeed(double speed) async {
    await _tts.setSpeechRate(speed);
  }

  /// Update TTS pitch (0.5 to 2.0).
  Future<void> setPitch(double pitch) async {
    await _tts.setPitch(pitch);
  }

  // === STT ===

  /// Start listening for voice commands.
  Future<void> startListening() async {
    if (!_isInitialized) await initialize();
    if (_isListening) return;
    if (!_stt.isAvailable) return;

    // Stop TTS while listening (avoid echo)
    await stopSpeaking();

    await _stt.listen(
      onResult: (SpeechRecognitionResult result) {
        if (result.finalResult) {
          final transcript = result.recognizedWords.toLowerCase().trim();
          _rawTranscriptController.add(transcript);
          final command = _parseCommand(transcript);
          _commandController.add(command);
        }
      },
      localeId: _ttsLocaleTag(_currentLocaleCode),
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
      ),
    );
  }

  /// Stop listening.
  Future<void> stopListening() async {
    if (_isListening) {
      await _stt.stop();
      _isListening = false;
    }
  }

  /// Parse a raw transcript into a VoiceCommand.
  /// Supports both English and Hindi keywords.
  VoiceCommand _parseCommand(String transcript) {
    // Normalize
    final words = transcript.toLowerCase().split(RegExp(r'\s+'));

    // Emergency / SOS
    if (words.contains('emergency') ||
        words.contains('sos') ||
        words.contains('help me') ||
        words.contains('\u0906\u092A\u093E\u0924\u0915\u093E\u0932') || // आपातकाल
        words.contains('\u092E\u0926\u0926') ||            // मदद
        words.contains('\u092C\u091A\u093E\u0913') ||      // बचाओ
        words.contains('\u0916\u0924\u0930\u093E')) {       // खतरा
      return VoiceCommand.emergency;
    }
    if (words.contains('help') ||
        transcript.contains("what's around") ||
        transcript.contains('\u0906\u0938\u092A\u093E\u0938') || // आसपास
        transcript.contains('\u092E\u0926\u0926')) {              // मदद
      return VoiceCommand.help;
    }
    if (words.contains('describe') ||
        transcript.contains('what do you see') ||
        transcript.contains('tell me') ||
        transcript.contains('\u092C\u0924\u093E\u0913') ||     // बताओ
        transcript.contains('\u0915\u094D\u092F\u093E \u0926\u093F\u0916 \u0930\u0939\u093E')) { // क्या दिख रहा
      return VoiceCommand.describe;
    }
    if (words.contains('stop') ||
        words.contains('quiet') ||
        words.contains('silence') ||
        words.contains('\u0930\u0941\u0915\u094B') ||     // रुको
        words.contains('\u0936\u093E\u0902\u0924') ||     // शांत
        words.contains('\u092C\u0902\u0926')) {           // बंद
      return VoiceCommand.stop;
    }
    if (words.contains('call') ||
        words.contains('volunteer') ||
        words.contains('\u0915\u0949\u0932') ||            // कॉल
        words.contains('\u0938\u094D\u0935\u092F\u0902\u0938\u0947\u0935\u0915')) { // स्वयंसेवक
      return VoiceCommand.call;
    }
    if (transcript.contains('end call') ||
        transcript.contains('hang up') ||
        transcript.contains('\u0915\u0949\u0932 \u0916\u0924\u094D\u092E') || // कॉल खत्म
        transcript.contains('\u0930\u0916\u094B')) {                           // रखो
      return VoiceCommand.endCall;
    }
    if (words.contains('yes') ||
        words.contains('yeah') ||
        words.contains('confirm') ||
        words.contains('\u0939\u093E\u0901') ||      // हाँ
        words.contains('\u0939\u093E\u0902')) {       // हां
      return VoiceCommand.yes;
    }
    if (words.contains('no') ||
        words.contains('cancel') ||
        words.contains('nevermind') ||
        words.contains('\u0928\u0939\u0940\u0902') ||   // नहीं
        words.contains('\u0928\u093E')) {               // ना
      return VoiceCommand.no;
    }

    return VoiceCommand.unknown;
  }

  bool get isListening => _isListening;

  void dispose() {
    stopSpeaking();
    stopListening();
    _commandController.close();
    _rawTranscriptController.close();
    _tts.stop();
  }
}
