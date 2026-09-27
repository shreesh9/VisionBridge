/// VisionBridge — AI Bridge Layer State Machine
///
/// Implements the confidence-based escalation from Build Spec Section 1:
///   On-device (TFLite YOLOv8 / ML Kit) → Groq Vision API → Human (WebRTC)
///
/// State machine: Idle → Detecting → Processing → Narrating → (loop or Escalating)
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import 'groq_client.dart';

/// States the AI Bridge can be in.
enum AIBridgeState {
  idle,       // Not running
  detecting,  // On-device detection active (TFLite / ML Kit)
  processing, // Groq cloud reasoning in progress
  narrating,  // TTS speaking the result
  escalating, // Below threshold → requesting human volunteer
  error,      // Recoverable error state
}

/// Event emitted by the bridge for UI consumption.
class AIBridgeEvent {
  const AIBridgeEvent({
    required this.state,
    this.detectedObjects = const [],
    this.description,
    this.confidence,
    this.source,
    this.errorMessage,
  });

  final AIBridgeState state;
  final List<String> detectedObjects;
  final String? description;
  final String? confidence;

  /// "on-device", "groq", "cache", "fallback"
  final String? source;
  final String? errorMessage;
}

/// The AI Bridge Layer — orchestrates the detection → reasoning → narration pipeline.
class AIBridgeService {
  AIBridgeService({
    required GroqClient groqClient,
  }) : _groqClient = groqClient;

  final GroqClient _groqClient;

  final _eventController = StreamController<AIBridgeEvent>.broadcast();
  Stream<AIBridgeEvent> get events => _eventController.stream;

  AIBridgeState _currentState = AIBridgeState.idle;
  AIBridgeState get currentState => _currentState;

  Timer? _captureTimer;
  bool _isRunning = false;

  /// Start the AI Bridge pipeline.
  /// Begins periodic frame capture → detection → optional Groq → TTS.
  void start() {
    if (_isRunning) return;
    _isRunning = true;
    _updateState(const AIBridgeEvent(state: AIBridgeState.detecting));

    // Periodic capture loop
    _captureTimer = Timer.periodic(
      const Duration(milliseconds: AppConstants.frameCaptureIntervalMs),
      (_) => _processPipeline(),
    );

    // First run immediately
    _processPipeline();
  }

  /// Stop the AI Bridge pipeline.
  void stop() {
    _isRunning = false;
    _captureTimer?.cancel();
    _captureTimer = null;
    _updateState(const AIBridgeEvent(state: AIBridgeState.idle));
  }

  /// Process one frame through the pipeline.
  Future<void> _processPipeline() async {
    if (!_isRunning) return;

    try {
      // Step 1: On-device detection
      _updateState(const AIBridgeEvent(state: AIBridgeState.detecting));

      final detectedObjects = await _runOnDeviceDetection();
      final ocrText = await _runOCR();

      // Step 2: Evaluate confidence
      // If on-device detection has high confidence AND sufficient objects,
      // we can narrate directly without burning Groq quota.
      if (detectedObjects.length >= 3 || (detectedObjects.isNotEmpty && ocrText != null)) {
        // Try Groq for richer description (if within rate limits)
        _updateState(AIBridgeEvent(
          state: AIBridgeState.processing,
          detectedObjects: detectedObjects,
        ));

        try {
          final groqResult = await _groqClient.describeScene(
            detectedObjects: detectedObjects,
            sceneContext: ocrText,
          );

          if (groqResult.isHighConfidence || groqResult.source == 'cache') {
            // High confidence → narrate
            _updateState(AIBridgeEvent(
              state: AIBridgeState.narrating,
              detectedObjects: detectedObjects,
              description: groqResult.description,
              confidence: groqResult.confidence,
              source: groqResult.source,
            ));
            // TODO: Feed description to TTS service
          } else {
            // Low confidence from Groq → escalate to human
            _updateState(AIBridgeEvent(
              state: AIBridgeState.escalating,
              detectedObjects: detectedObjects,
              description: groqResult.description,
              confidence: 'low',
              source: groqResult.source,
            ));
          }
        } on GroqRateLimitError {
          // Rate limited — fall back to on-device labels
          _updateState(AIBridgeEvent(
            state: AIBridgeState.narrating,
            detectedObjects: detectedObjects,
            description: 'I detect: ${detectedObjects.join(", ")}.',
            confidence: 'low',
            source: 'fallback',
          ));
        } on GroqTimeoutError {
          _updateState(AIBridgeEvent(
            state: AIBridgeState.narrating,
            detectedObjects: detectedObjects,
            description: 'I detect: ${detectedObjects.join(", ")}.',
            confidence: 'low',
            source: 'fallback',
          ));
        }
      } else if (detectedObjects.isNotEmpty) {
        // Some objects but not enough for Groq — narrate on-device labels
        _updateState(AIBridgeEvent(
          state: AIBridgeState.narrating,
          detectedObjects: detectedObjects,
          description: 'I detect: ${detectedObjects.join(", ")}.',
          confidence: 'low',
          source: 'on-device',
        ));
      } else {
        // Nothing detected
        _updateState(const AIBridgeEvent(
          state: AIBridgeState.narrating,
          description: 'I don\'t see any clear objects right now. Try adjusting your camera.',
          confidence: 'low',
          source: 'on-device',
        ));
      }
    } catch (e) {
      _updateState(AIBridgeEvent(
        state: AIBridgeState.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// On-device detection stub — will wire to TFLite YOLOv8.
  Future<List<String>> _runOnDeviceDetection() async {
    // TODO: Integrate tflite_flutter + YOLOv8 nano model
    // Returns list of detected object labels with confidence > threshold
    await Future.delayed(const Duration(milliseconds: 200));
    return ['Person', 'Table', 'Bottle']; // Mock data
  }

  /// On-device OCR stub — will wire to ML Kit.
  Future<String?> _runOCR() async {
    // TODO: Integrate google_mlkit_text_recognition
    await Future.delayed(const Duration(milliseconds: 100));
    return null; // Mock: no text detected
  }

  void _updateState(AIBridgeEvent event) {
    _currentState = event.state;
    _eventController.add(event);
  }

  void dispose() {
    stop();
    _eventController.close();
    _groqClient.dispose();
  }
}

/// Riverpod provider for the AI Bridge service.
/// Lazily created — only when AI Assist screen is opened.
final aiBridgeProvider = Provider.autoDispose<AIBridgeService>((ref) {
  // TODO: Inject real Groq API key from secure storage / env
  final groqClient = GroqClient(
    apiKey: const String.fromEnvironment('GROQ_API_KEY', defaultValue: ''),
    modelName: 'llama-3.2-90b-vision-preview',
  );

  final service = AIBridgeService(groqClient: groqClient);
  ref.onDispose(() => service.dispose());
  return service;
});
