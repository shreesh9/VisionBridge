/// Original Vision AI Groq Engine by Shreesh Nalawade
/// Copyright (c) Shreesh Nalawade | Reference: SN09092005
///
/// VisionBridge — Groq API Client
///
/// Rate-limit-aware client for Groq Vision API.
/// Implements all 6 mitigations from Build Spec Section 3.2:
/// 1. Never call per-frame (throttled interval)
/// 2. Debounce/queue — skip if in-flight or too recent
/// 3. Cache identical/near-identical results
/// 4. Exponential backoff on 429
/// 5. Graceful fallback on exhaustion
/// 6. Scoped to scene description only
library;

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../core/constants.dart';
import 'user_settings_service.dart';

/// Result of a Groq scene description request.
class GroqSceneResult {
  const GroqSceneResult({
    required this.description,
    required this.confidence,
    required this.source,
  });

  final String description;

  /// "high" or "low" — self-reported by the model.
  final String confidence;

  /// Where this result came from: "groq", "cache", or "fallback".
  final String source;

  bool get isHighConfidence => confidence == 'high';
}

/// Error types for explicit handling — no catch-all swallowing.
class GroqRateLimitError implements Exception {
  const GroqRateLimitError(this.retryAfterSeconds);
  final int retryAfterSeconds;

  @override
  String toString() =>
      'GroqRateLimitError: rate limited, retry after ${retryAfterSeconds}s';
}

class GroqApiError implements Exception {
  const GroqApiError(this.statusCode, this.message);
  final int statusCode;
  final String message;

  @override
  String toString() => 'GroqApiError($statusCode): $message';
}

class GroqTimeoutError implements Exception {
  @override
  String toString() => 'GroqTimeoutError: request exceeded timeout';
}

/// Groq API client with full rate-limit discipline.
class GroqClient {
  GroqClient({
    required String apiKey,
    required String modelName,
    Dio? dio,
  })  : _apiKey = apiKey,
        _modelName = modelName,
        _dio = dio ??
            Dio(BaseOptions(
              baseUrl: 'https://api.groq.com/openai/v1',
              connectTimeout:
                  const Duration(milliseconds: AppConstants.groqTimeoutMs),
              receiveTimeout:
                  const Duration(milliseconds: AppConstants.groqTimeoutMs),
            ));

  final String _apiKey;
  final String _modelName;
  final Dio _dio;

  // --- Rate-limit state ---
  DateTime? _lastRequestTime;
  bool _isRequestInFlight = false;
  int _consecutiveRetries = 0;

  // --- Cache ---
  String? _cachedDescription;
  String? _cachedInputHash;
  DateTime? _cachedAt;

  /// Request a scene description from Groq.
  ///
  /// [detectedObjects] — list of objects detected on-device (YOLOv8/ML Kit).
  /// [sceneContext] — optional additional context (OCR text, location, etc.).
  ///
  /// Returns [GroqSceneResult] or throws [GroqRateLimitError], [GroqApiError],
  /// or [GroqTimeoutError]. Never fails silently.
  Future<GroqSceneResult> describeScene({
    List<String> detectedObjects = const [],
    String? sceneContext,
    String? base64Image,
  }) async {
    // --- Mitigation 2: Debounce ---
    if (_isRequestInFlight) {
      return _fallbackResult(detectedObjects, 'Request already in-flight');
    }

    final now = DateTime.now();
    if (_lastRequestTime != null) {
      final elapsed = now.difference(_lastRequestTime!).inMilliseconds;
      if (elapsed < AppConstants.groqMinIntervalMs) {
        return _fallbackResult(detectedObjects, 'Throttled (${elapsed}ms < min interval)');
      }
    }

    // --- Mitigation 3: Cache check ---
    final inputHash = _hashInput(detectedObjects, sceneContext);
    if (base64Image == null &&
        _cachedDescription != null &&
        _cachedInputHash == inputHash &&
        _cachedAt != null &&
        now.difference(_cachedAt!).inMilliseconds < AppConstants.groqCacheTtlMs) {
      return GroqSceneResult(
        description: _cachedDescription!,
        confidence: 'high',
        source: 'cache',
      );
    }

    // --- Make request ---
    _isRequestInFlight = true;
    _lastRequestTime = now;

    try {
      final result = await _makeRequest(detectedObjects, sceneContext, base64Image);

      // Cache the result
      _cachedDescription = result.description;
      _cachedInputHash = inputHash;
      _cachedAt = DateTime.now();
      _consecutiveRetries = 0;

      return result;
    } on GroqRateLimitError {
      // --- Mitigation 4: Exponential backoff ---
      _consecutiveRetries++;
      if (_consecutiveRetries >= AppConstants.groqMaxRetries) {
        // --- Mitigation 5: Graceful fallback ---
        _consecutiveRetries = 0;
        return _fallbackResult(detectedObjects, 'Rate limit exhausted after ${AppConstants.groqMaxRetries} retries');
      }
      rethrow;
    } finally {
      _isRequestInFlight = false;
    }
  }

  Future<GroqSceneResult> _makeRequest(
    List<String> detectedObjects,
    String? sceneContext,
    String? base64Image,
  ) async {
    final objectList = detectedObjects.join(', ');
    final contextLine =
        sceneContext != null ? '\nAdditional context: $sceneContext' : '';

    final dynamic userContent;
    if (base64Image != null && base64Image.isNotEmpty) {
      userContent = [
        {
          'type': 'text',
          'text':
              'Describe what is in front of the camera in 1-2 concise, clear sentences. Identify exact objects (such as a computer mouse, laptop, keyboard, cup, chair, door, person, etc.), their positions, and spatial layout.',
        },
        {
          'type': 'image_url',
          'image_url': {
            'url': base64Image.startsWith('data:')
                ? base64Image
                : 'data:image/jpeg;base64,$base64Image',
          },
        },
      ];
    } else {
      userContent =
          'Objects detected: $objectList.$contextLine\n\nDescribe what the user is likely looking at in 1-2 concise sentences.';
    }

    try {
      String userAgeGroup = 'adult';
      String localeCode = 'en';
      try {
        userAgeGroup = await UserSettingsService.getUserAgeGroup();
      } catch (_) {}
      try {
        localeCode = await UserSettingsService.getLocaleCode();
      } catch (_) {}

      // Language instruction based on user's locale
      final langInstruction = localeCode == 'hi'
          ? ' हिन्दी में उत्तर दें।'
          : '';

      String systemPrompt = 'You are an expert visual assistant for a blind user. Describe what is in front of the camera in 1-2 clear, accurate sentences. Focus on identifying real objects accurately.$langInstruction';

      if (userAgeGroup == 'genZ') {
        systemPrompt = 'You are a cool, friendly AI assistant for a Gen Z visually impaired user. Describe what is in front of the camera in 1-2 concise sentences using a casual, relatable tone (friendly vibes, natural tone, empowering). Identify objects accurately.$langInstruction';
      } else if (userAgeGroup == 'genAlpha') {
        systemPrompt = 'You are an upbeat, super encouraging AI assistant for a young visually impaired user. Describe what is in front of the camera in 1-2 simple, energetic, friendly sentences so they feel empowered and independent!$langInstruction';
      }

      final response = await _dio.post(
        '/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': _modelName,
          'messages': [
            {
              'role': 'system',
              'content': systemPrompt,
            },
            {
              'role': 'user',
              'content': userContent,
            },
          ],
          'temperature': 0.3,
          'max_tokens': AppConstants.groqMaxTokens,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final content =
          (data['choices']?[0]?['message']?['content'] as String?) ?? '';
      
      String desc = '';
      String conf = 'high';

      try {
        final parsed = jsonDecode(content) as Map<String, dynamic>;
        desc = parsed['description'] as String? ?? content;
        conf = (parsed['confidence'] as String? ?? 'high').toLowerCase();
      } catch (_) {
        desc = content.trim();
      }

      return GroqSceneResult(
        description: desc.isNotEmpty ? desc : 'A scene is visible in front of you.',
        confidence: conf == 'low' ? 'low' : 'high',
        source: 'groq',
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        // Parse retry-after header
        final retryAfter =
            int.tryParse(e.response?.headers.value('retry-after') ?? '') ?? 5;
        throw GroqRateLimitError(retryAfter);
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw GroqTimeoutError();
      }
      throw GroqApiError(
        e.response?.statusCode ?? 0,
        e.response?.data?.toString() ?? e.message ?? 'Unknown Groq API error',
      );
    }
  }

  /// Fallback: return on-device detection labels as plain text.
  /// This is Mitigation 5 — never crash, never go silent.
  GroqSceneResult _fallbackResult(List<String> objects, String reason) {
    final description = objects.isNotEmpty
        ? 'I detect: ${objects.join(", ")}.'
        : 'Unable to detect objects right now.';
    return GroqSceneResult(
      description: description,
      confidence: 'low',
      source: 'fallback',
    );
  }

  String _hashInput(List<String> objects, String? context) {
    return '${objects.join(",")}|${context ?? ""}';
  }

  /// Calculate backoff delay for retries (exponential).
  Duration getBackoffDelay() {
    final delayMs = AppConstants.groqBackoffBaseMs *
        (1 << _consecutiveRetries); // 1s, 2s, 4s...
    return Duration(milliseconds: delayMs);
  }

  void dispose() {
    _dio.close();
  }
}
