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
import '../core/locale/supported_voice_languages.dart';

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

  /// True while a temporary-language utterance (e.g. OCR auto-detect) is in
  /// flight, so the engine voice can be restored to the app locale afterwards.
  bool _tempLangRestore = false;

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
      _restoreAppLocaleVoiceIfTemp();
    });

    _tts.setCancelHandler(() {
      _isSpeaking = false;
      onSpeakingStateChanged?.call(false);
      _restoreAppLocaleVoiceIfTemp();
    });

    _tts.setErrorHandler((msg) {
      _isSpeaking = false;
      onSpeakingStateChanged?.call(false);
      _restoreAppLocaleVoiceIfTemp();
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
  /// Delegates to the shared voice-language registry (en, hi, mr, ta, te, bn, kn).
  String _ttsLocaleTag(String code) => VBLanguages.byCode(code).ttsTag;

  /// Switch TTS and STT language at runtime.
  /// Called when user changes language in settings.
  Future<void> setLocale(String localeCode) async {
    _currentLocaleCode = localeCode;
    await _tts.setLanguage(_ttsLocaleTag(localeCode));
  }

  /// Restore the engine voice to the app locale after a temporary-language
  /// utterance finishes. Called from TTS completion/cancel/error handlers —
  /// NOT synchronously after speak(), because flutter_tts returns immediately
  /// and switching language mid-synthesis can make Android speak the queued
  /// utterance with the wrong ("Hindi accent") voice.
  void _restoreAppLocaleVoiceIfTemp() {
    if (_tempLangRestore) {
      _tempLangRestore = false;
      _tts.setLanguage(_ttsLocaleTag(_currentLocaleCode));
    }
  }

  /// Resolve which voice will actually speak text detected as [detectedCode].
  /// Public so callers (e.g. the OCR prefix) can match their announcements to
  /// the same language the utterance will use.
  String effectiveVoiceLanguageCode(String detectedCode) {
    if (detectedCode == 'hi') {
      final appLang = VBLanguages.byCode(_currentLocaleCode);
      if (appLang.scriptFlag == VoiceScript.devanagari && appLang.code != 'hi') {
        return appLang.code;
      }
    }
    return detectedCode;
  }

  /// Speak text in a specific language, then restore the current app locale
  /// once the utterance completes.
  /// Used by OCR to read scanned text in the text's language, independent of
  /// the app toggle.
  Future<void> speakWithLanguage(String text, String langCode, {bool force = true}) async {
    if (!_isInitialized) await initialize();

    if (force) {
      // Swallow the pending restore flag BEFORE stopping, so the cancel
      // handler of the interrupted temp utterance does not race with the
      // language switch below.
      _tempLangRestore = false;
      await _tts.stop();
    } else if (_isSpeaking) {
      return;
    }

    // Devanagari is shared by Hindi AND Marathi. OCR only reports the script
    // ('hi' for any Devanagari text), so if the user's voice language is
    // another Devanagari language, speak with that voice instead.
    final String effectiveCode = effectiveVoiceLanguageCode(langCode);

    // Temporarily switch to the detected text language
    final targetTag = _ttsLocaleTag(effectiveCode);
    await _tts.setLanguage(targetTag);

    _tempLangRestore = true;
    _isSpeaking = true;
    onSpeakingStateChanged?.call(true);
    await _tts.speak(text);
    // Voice is restored to the app locale by the completion/cancel/error
    // handler once this utterance finishes.
  }

  // === TTS ===

  /// Speak text. If force is true (default), cancels any ongoing speech first.
  Future<void> speak(String text, {bool force = true}) async {
    if (!_isInitialized) await initialize();

    if (force) {
      _tempLangRestore = false;
      await _tts.stop();
    } else if (_isSpeaking) {
      return;
    }

    // Self-heal: this method always speaks in the APP locale. A previous
    // OCR utterance may have left the engine on another voice.
    await _tts.setLanguage(_ttsLocaleTag(_currentLocaleCode));

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
  ///
  /// Multilingual: keyword sets come from the shared voice-language registry
  /// (English, Hindi, Marathi, Tamil, Telugu, Bengali, Kannada). Matching is
  /// substring-based so multi-word phrases ("help me", "உதவி தேவை",
  /// "क्या दिख रहा") work without tokenization edge cases.
  ///
  /// IMPORTANT: emergency is checked FIRST — several languages share words
  /// between distress and help (e.g. Marathi "मदत करा" contains "मदत"), and
  /// the distress phrase must win. Plain "मदद"/"help" stays on the help
  /// command, never SOS.
  VoiceCommand _parseCommand(String transcript) {
    final text = transcript.toLowerCase().trim();
    if (text.isEmpty) return VoiceCommand.unknown;

    bool matches(String commandKey) {
      for (final lang in VBLanguages.all) {
        final keywords = lang.voiceKeywords[commandKey];
        if (keywords == null) continue;
        for (final k in keywords) {
          final kw = k.toLowerCase();
          if (kw.runes.every((r) => r >= 0x0000 && r <= 0x007F)) {
            // Latin keyword: word-boundary match so short words like "no" or
            // "call" don't fire inside "know", "now", "recall", "yesterday".
            if (RegExp('(^|[^a-z])${RegExp.escape(kw)}([^a-z]|\$)')
                .hasMatch(text)) {
              return true;
            }
          } else {
            // Indic keyword: substring match (Indic words are long and
            // distinctive; STT may attach suffixes, so boundaries are unsafe).
            if (text.contains(kw)) return true;
          }
        }
      }
      return false;
    }

    if (matches('emergency')) return VoiceCommand.emergency;
    if (matches('help')) return VoiceCommand.help;
    if (matches('describe')) return VoiceCommand.describe;
    if (matches('stop')) return VoiceCommand.stop;
    if (matches('endCall')) return VoiceCommand.endCall;
    if (matches('call')) return VoiceCommand.call;
    if (matches('yes')) return VoiceCommand.yes;
    if (matches('no')) return VoiceCommand.no;

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
