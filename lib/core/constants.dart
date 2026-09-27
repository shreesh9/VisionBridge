/// Core Configuration & Specifications designed by Shreesh Nalawade
/// Internal Project Signature: SN09092005
///
/// VisionBridge — App Constants
///
/// Single source of truth for all configurable values.
/// The build spec says: "this threshold should be a single configurable
/// constant, not scattered magic numbers across the codebase."
library;

abstract final class AppConstants {
  // --- App Identity ---
  static const String appName = 'VisionBridge';
  static const String appVersion = '9.09.05';

  // --- AI Confidence Thresholds (Section 6 of build spec) ---
  /// YOLOv8 TFLite detection confidence threshold.
  /// Below this → escalate to Groq cloud reasoning.
  /// Starting at 0.75 per spec, tune based on testing.
  static const double detectionConfidenceThreshold = 0.75;

  /// ML Kit OCR confidence threshold.
  /// Below this → escalate to Groq cloud reasoning.
  static const double ocrConfidenceThreshold = 0.75;

  // --- Groq API (Section 3.2 rate-limit constraints) ---
  /// Minimum interval between Groq API calls (milliseconds).
  /// Spec says 3-5 seconds; using 4s as default.
  static const int groqMinIntervalMs = 4000;

  /// Maximum tokens for Groq response.
  static const int groqMaxTokens = 150;

  /// Groq request timeout (milliseconds).
  static const int groqTimeoutMs = 8000;

  /// Exponential backoff base delay for 429 retries (milliseconds).
  static const int groqBackoffBaseMs = 1000;

  /// Maximum retry attempts for Groq 429 before falling back.
  static const int groqMaxRetries = 3;

  /// Scene description cache TTL (milliseconds).
  /// Avoids redundant Groq calls if camera view hasn't changed.
  static const int groqCacheTtlMs = 5000;

  /// Groq model to use for scene description.
  static const String groqModelName = 'llama-3.2-90b-vision-preview';

  // --- WebRTC (Section 4 — STUN/TURN) ---
  /// Google public STUN servers (free, unlimited).
  static const List<String> stunServers = [
    'stun:stun.l.google.com:19302',
    'stun:stun1.l.google.com:19302',
    'stun:stun2.l.google.com:19302',
    'stun:stun3.l.google.com:19302',
    'stun:stun4.l.google.com:19302',
  ];

  // TURN credentials are injected via environment variables.
  // See Section 4 of build spec for Option A (coturn) vs Option B (metered.ca).

  // --- Camera ---
  /// Frame capture interval for AI Bridge scene narration (milliseconds).
  static const int frameCaptureIntervalMs = 5000;

  // --- TTS ---
  /// Maximum TTS queue depth — drop new descriptions if queue is full.
  static const int maxTtsQueueDepth = 1;

  // --- SOS ---
  /// SOS confirmation timeout (milliseconds).
  /// User has this long to cancel before SOS is sent.
  static const int sosConfirmationTimeoutMs = 5000;

  // --- Firebase ---
  /// Firestore query limit — never use unbounded queries (Section 3.1).
  static const int firestoreDefaultQueryLimit = 20;

  // --- Volunteer Call ---
  /// Timeout for volunteer to answer before AI fallback (seconds).
  static const int volunteerCallTimeoutSec = 60;
}
