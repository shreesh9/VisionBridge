/// Multi-Provider AI Vision Engine | Original implementation by Shreesh Nalawade (SN09092005)
///
/// VisionBridge — Universal AI Vision Service
///
/// Multi-provider AI Vision Engine (Groq Vision + OpenRouter + On-Device Fallback).
library;

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

import 'user_settings_service.dart';

class VisionResult {

  VisionResult({
    required this.description,
    required this.provider,
    this.isSuccess = true,
  });
  final String description;
  final String provider;
  final bool isSuccess;
}

class VisionAIService {
  // Explicit timeouts are critical: without them a single hung key can stall
  // the whole failover chain and the user hears nothing at all.
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    sendTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 20),
  ));

  // Multi-Account Failover Pool for Groq Qwen (3 Independent Accounts)
  static const List<String> _defaultGroqKeys = [
    String.fromEnvironment('GROQ_KEY_1'),
    String.fromEnvironment('GROQ_KEY_2'),
    String.fromEnvironment('GROQ_KEY_3'),
  ];

  static const String _openRouterKeyFromDefine =
      String.fromEnvironment('OPENROUTER_API_KEY');

  static int _currentKeyIndex = 0; // Active key index

  /// Parsed assets/.env cache so we only hit rootBundle once per session.
  static Map<String, String>? _envCache;

  /// Load and cache all key/value pairs from assets/.env (or .env).
  static Future<Map<String, String>> _loadEnv() async {
    if (_envCache != null) return _envCache!;

    final Map<String, String> env = {};
    for (final path in ['assets/.env', '.env']) {
      try {
        final envContent = await rootBundle.loadString(path);
        for (final line in envContent.split('\n')) {
          final trimmed = line.trim();
          if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

          final idx = trimmed.indexOf('=');
          if (idx <= 0) continue;

          final key = trimmed.substring(0, idx).trim();
          final value = trimmed.substring(idx + 1).trim();
          if (key.isNotEmpty && value.isNotEmpty) {
            env.putIfAbsent(key, () => value);
          }
        }
      } catch (_) {}
    }

    _envCache = env;
    return env;
  }

  /// Resolve the OpenRouter API key from --dart-define first, then assets/.env.
  /// Returns an empty string when no key is configured.
  Future<String> _resolveOpenRouterKey() async {
    if (_openRouterKeyFromDefine.trim().isNotEmpty) {
      return _openRouterKeyFromDefine.trim();
    }
    final env = await _loadEnv();
    return (env['OPENROUTER_API_KEY'] ?? '').trim();
  }

  /// Describe scene image strictly using Groq qwen/qwen3.6-27b with 3-Key Failover
  Future<VisionResult> describeScene({
    required String base64Image,
    List<String> detectedObjects = const [],
    String? customGeminiKey,
    String? customGroqKey,
  }) async {
    // Build 3-Account Groq Key Pool
    final List<String> groqKeys = [];

    for (final k in _defaultGroqKeys) {
      final trimmedKey = k.trim();
      if (trimmedKey.isNotEmpty && !groqKeys.contains(trimmedKey)) {
        groqKeys.add(trimmedKey);
      }
    }

    if (customGroqKey != null && customGroqKey.trim().isNotEmpty) {
      final trimmedCustom = customGroqKey.trim();
      if (!groqKeys.contains(trimmedCustom)) {
        groqKeys.add(trimmedCustom);
      }
    }

    // Load keys from assets/.env or .env asset if any of Key 1, Key 2, Key 3 are missing
    if (groqKeys.length < 3) {
      final env = await _loadEnv();
      for (final entry in env.entries) {
        if (!entry.key.startsWith('GROQ_KEY_')) continue;
        final val = entry.value.trim();
        if (val.isNotEmpty && !groqKeys.contains(val)) {
          groqKeys.add(val);
        }
      }
    }

    // Guaranteed Key Pool Fallback
    // Removed hardcoded keys for security. We now load keys exclusively via .env (GROQ_KEY_1, etc.)
    const List<String> fallbackKeys = [];

    if (groqKeys.length < 3) {
      for (final fbKey in fallbackKeys) {
        if (!groqKeys.contains(fbKey)) {
          groqKeys.add(fbKey);
        }
      }
    }

    // Clean base64 string
    String cleanBase64 = base64Image;
    if (cleanBase64.contains(',')) {
      cleanBase64 = cleanBase64.split(',').last;
    }

    // Detect the real image format. The capture path falls back to raw JPEG
    // bytes when PNG re-encoding fails, and mislabelling those as PNG makes
    // some vision providers reject the request outright.
    final String mimeType =
        cleanBase64.startsWith('/9j/') ? 'image/jpeg' : 'image/png';
    final String imageDataUri = cleanBase64.startsWith('data:')
        ? cleanBase64
        : 'data:$mimeType;base64,$cleanBase64';

    String lastError = '';
    const List<String> groqModels = [
      'llama-3.2-11b-vision-preview',
      'llama-3.2-90b-vision-preview',
    ];

    // Read user's language preference for locale-aware prompts
    String localeCode = 'en';
    try {
      localeCode = await UserSettingsService.getLocaleCode();
    } catch (_) {}

    final String systemPrompt = localeCode == 'hi'
        ? 'आप दृष्टिबाधित उपयोगकर्ताओं के लिए एक AI दृश्य सहायक हैं। हमेशा केवल और केवल देवनागरी लिपि हिंदी (शुद्ध हिन्दी) में उत्तर दें। अंग्रेजी अक्षरों या अंग्रेजी शब्दों का उपयोग बिल्कुल न करें।'
        : 'You are an AI visual assistant helping blind users. Describe what is in front of the camera in 1-2 clear, direct sentences.';

    final String userPrompt = localeCode == 'hi'
        ? 'कैमरे के सामने क्या दिख रहा है? 1-2 स्पष्ट वाक्यों में शुद्ध हिन्दी में बताओ।'
        : 'What do you see? Describe in 1-2 clear sentences. Identify exact objects.';

    // --- Provider 1: Groq Vision API (llama-3.2-11b-vision-preview / llama-3.2-90b-vision-preview) ---
    if (groqKeys.isNotEmpty) {
      final int totalKeys = groqKeys.length;
      for (final modelName in groqModels) {
        for (int attempt = 0; attempt < totalKeys; attempt++) {
          final int keyIndex = (_currentKeyIndex + attempt) % totalKeys;
          final String key = groqKeys[keyIndex];

          try {
            final response = await _dio.post(
              'https://api.groq.com/openai/v1/chat/completions',
              options: Options(headers: {
                'Authorization': 'Bearer $key',
                'Content-Type': 'application/json',
              }),
              data: {
                'model': modelName,
                'messages': [
                  {
                    'role': 'system',
                    'content': systemPrompt,
                  },
                  {
                    'role': 'user',
                    'content': [
                      {
                        'type': 'text',
                        'text': userPrompt,
                      },
                      {
                        'type': 'image_url',
                        'image_url': {
                          'url': imageDataUri,
                        },
                      },
                    ],
                  }
                ],
                'max_tokens': 200,
                'temperature': 0.1,
              },
            );

            if (response.statusCode == 200 && response.data != null) {
              final content =
                  response.data['choices']?[0]?['message']?['content'] as String?;
              if (content != null && content.trim().isNotEmpty) {
                _currentKeyIndex = keyIndex; // Lock onto working key
                final cleanedText = _cleanModelResponse(content, localeCode);
                return VisionResult(
                  description: cleanedText,
                  provider: '🤖 Groq Vision ($modelName, Key ${keyIndex + 1})',
                );
              }
            }
          } catch (e) {
            final errorDetails = e is DioException && e.response != null
                ? '${e.response?.statusCode}: ${e.response?.data}'
                : e.toString();
            lastError =
                'Groq Key ${keyIndex + 1} ($modelName): $errorDetails';

            _currentKeyIndex = (keyIndex + 1) % totalKeys;

            print(
                '⚠️ Groq Key ${keyIndex + 1} ($modelName) rate limited or failed: $errorDetails.');
          }
        }
      }
    }

    // --- Provider 2: OpenRouter Qwen 2.5/3.6 Vision Fallback ---
    // OpenRouter rejects unauthenticated requests with HTTP 401, so skip the
    // provider entirely when no key is configured rather than burning ~40s of
    // timeouts on calls that can never succeed.
    final String openRouterKey = await _resolveOpenRouterKey();

    if (openRouterKey.isEmpty) {
      print(
          'ℹ️ OpenRouter fallback skipped: no OPENROUTER_API_KEY configured in --dart-define or assets/.env.');
    } else {
      final List<String> openRouterQwenModels = [
        'qwen/qwen-2.5-vl-72b-instruct:free',
        'qwen/qwen-2.5-vl-72b-instruct',
      ];

      for (final model in openRouterQwenModels) {
        try {
          final response = await _dio.post(
            'https://openrouter.ai/api/v1/chat/completions',
            options: Options(headers: {
              'Authorization': 'Bearer $openRouterKey',
              'Content-Type': 'application/json',
              'HTTP-Referer': 'https://visionbridge.app',
              'X-Title': 'VisionBridge',
            }),
            data: {
              'model': model,
              'messages': [
                {
                  'role': 'user',
                  'content': [
                    {
                      'type': 'text',
                      'text': userPrompt,
                    },
                    {
                      'type': 'image_url',
                      'image_url': {
                        'url': imageDataUri,
                      },
                    },
                  ],
                }
              ],
              'max_tokens': 200,
              'temperature': 0.1,
            },
          );

          if (response.statusCode == 200 && response.data != null) {
            final content =
                response.data['choices']?[0]?['message']?['content'] as String?;
            if (content != null && content.trim().isNotEmpty) {
              final cleanedText = _cleanModelResponse(content, localeCode);
              return VisionResult(
                description: cleanedText,
                provider: '🤖 Qwen 2.5 Vision AI ($model)',
              );
            }
          }
        } catch (e) {
          final errorDetails = e is DioException && e.response != null
              ? '${e.response?.statusCode}: ${e.response?.data}'
              : e.toString();
          lastError = 'OpenRouter ($model): $errorDetails';
          print('⚠️ OpenRouter Qwen Vision model $model failed: $errorDetails');
        }
      }
    }

    // --- Provider 3: On-Device Detection Fallback ---
    if (detectedObjects.isNotEmpty) {
      String fallbackDesc;
      if (localeCode == 'hi') {
        // Never pass raw English detector labels into the hi-IN synthesizer.
        // Translate what we recognise, and drop the rest rather than letting
        // Android phonetically mangle English words with Hindi voice rules.
        final List<String> hindiLabels = _localizeLabelsHi(detectedObjects);
        fallbackDesc = hindiLabels.isNotEmpty
            ? 'मुझे सामने ${hindiLabels.join(", ")} दिख रहा है। अधिक जानने के लिए दोबारा दृश्य बताएँ बटन दबाएँ, या मदद के लिए कॉल करें।'
            : 'मुझे सामने कुछ वस्तुएँ दिख रही हैं। अधिक जानने के लिए दोबारा दृश्य बताएँ बटन दबाएँ, या मदद के लिए कॉल करें।';
      } else {
        fallbackDesc =
            'I see ${detectedObjects.join(", ")} ahead. If you want to know anything else, tap on the Describe button again or call for help.';
      }
      return VisionResult(
        description: fallbackDesc,
        provider: '📱 On-Device Vision',
      );
    }

    String userFriendlyError = localeCode == 'hi'
        ? 'AI विज़न मॉडल अभी व्यस्त हैं। कृपया कुछ क्षण बाद पुनः प्रयास करें।'
        : 'AI vision models are currently busy. Please try again in a moment.';
    if (lastError.contains('429') ||
        lastError.toLowerCase().contains('rate limit')) {
      userFriendlyError = localeCode == 'hi'
          ? 'AI विज़न मॉडल की अस्थायी सीमा पूरी हो गई। कृपया कुछ सेकंड प्रतीक्षा करें और पुनः प्रयास करें।'
          : 'AI vision models reached a temporary limit. Please wait a few seconds and try again.';
    }

    return VisionResult(
      description: userFriendlyError,
      provider: '⚠️ AI Unavailable',
      isSuccess: false,
    );
  }

  /// Minimal English -> Hindi dictionary for on-device detector labels.
  /// Keys are lowercase. Anything absent is dropped rather than spoken in
  /// English by the hi-IN synthesizer.
  static const Map<String, String> _hiLabels = {
    'person': 'व्यक्ति',
    'people': 'लोग',
    'man': 'आदमी',
    'woman': 'महिला',
    'child': 'बच्चा',
    'chair': 'कुर्सी',
    'table': 'मेज़',
    'dining table': 'खाने की मेज़',
    'desk': 'डेस्क',
    'bed': 'बिस्तर',
    'couch': 'सोफ़ा',
    'sofa': 'सोफ़ा',
    'door': 'दरवाज़ा',
    'window': 'खिड़की',
    'stairs': 'सीढ़ियाँ',
    'laptop': 'लैपटॉप',
    'computer': 'कंप्यूटर',
    'keyboard': 'कीबोर्ड',
    'mouse': 'माउस',
    'tv': 'टीवी',
    'television': 'टीवी',
    'cell phone': 'मोबाइल फ़ोन',
    'phone': 'फ़ोन',
    'book': 'किताब',
    'clock': 'घड़ी',
    'bottle': 'बोतल',
    'cup': 'कप',
    'glass': 'गिलास',
    'wine glass': 'गिलास',
    'bowl': 'कटोरा',
    'plate': 'प्लेट',
    'fork': 'काँटा',
    'knife': 'चाकू',
    'spoon': 'चम्मच',
    'food': 'खाना',
    'fruit': 'फल',
    'apple': 'सेब',
    'banana': 'केला',
    'orange': 'संतरा',
    'bread': 'रोटी',
    'car': 'कार',
    'bus': 'बस',
    'truck': 'ट्रक',
    'bicycle': 'साइकिल',
    'motorcycle': 'मोटरसाइकिल',
    'train': 'ट्रेन',
    'traffic light': 'ट्रैफ़िक लाइट',
    'stop sign': 'रुकने का चिन्ह',
    'bench': 'बेंच',
    'backpack': 'बैग',
    'handbag': 'हैंडबैग',
    'suitcase': 'सूटकेस',
    'umbrella': 'छाता',
    'dog': 'कुत्ता',
    'cat': 'बिल्ली',
    'bird': 'पक्षी',
    'cow': 'गाय',
    'horse': 'घोड़ा',
    'tree': 'पेड़',
    'plant': 'पौधा',
    'potted plant': 'गमले का पौधा',
    'flower': 'फूल',
    'home good': 'घरेलू सामान',
    'fashion good': 'पहनने का सामान',
    'place': 'स्थान',
    'goods': 'सामान',
    'sink': 'सिंक',
    'toilet': 'शौचालय',
    'refrigerator': 'फ्रिज',
    'microwave': 'माइक्रोवेव',
    'oven': 'ओवन',
    'scissors': 'कैंची',
    'vase': 'फूलदान',
    'remote': 'रिमोट',
  };

  /// Translate detector labels to Hindi, dropping any that cannot be translated.
  List<String> _localizeLabelsHi(List<String> labels) {
    final List<String> out = [];
    for (final raw in labels) {
      final hi = _hiLabels[raw.trim().toLowerCase()];
      if (hi != null && !out.contains(hi)) {
        out.add(hi);
      }
    }
    return out;
  }

  /// Clean model response: strip all meta/reasoning, keep only physical object descriptions.
  String _cleanModelResponse(String rawText, String localeCode) {
    String cleaned = rawText;

    // 1. Remove <think>...</think> reasoning blocks
    cleaned = cleaned.replaceAll(
        RegExp(r'<think>[\s\S]*?</think>', caseSensitive: false), '');
    cleaned =
        cleaned.replaceAll(RegExp(r'</?think>', caseSensitive: false), '');

    // 2. Remove ALL markdown formatting
    cleaned = cleaned.replaceAll(RegExp(r'[*#`]+'), '');

    // 3. Remove leading list bullets/dashes ("- ", "1. ")
    cleaned = cleaned.replaceAll(RegExp(r'^[\s]*[-•]\s*', multiLine: true), '');
    cleaned = cleaned.replaceAll(RegExp(r'^\s*\d+\.\s*', multiLine: true), '');

    // For Hindi responses, skip the English-specific cleaning and just trim
    if (localeCode == 'hi') {
      // Remove markdown and reasoning blocks but preserve Hindi content
      cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (cleaned.isEmpty) {
        cleaned = 'कोई विवरण उपलब्ध नहीं है।';
      }
      // Append Hindi call-to-action if not already present
      const String hiCta =
          ' और कुछ जानना हो तो दोबारा दृश्य बताएँ बटन दबाएँ, या मदद के लिए कॉल करें।';
      if (!cleaned.contains('दृश्य बताएँ') &&
          !cleaned.contains('कॉल करें')) {
        cleaned = '$cleaned$hiCta';
      }
      return cleaned;
    }

    // 4. Remove section labels inline (English only)
    cleaned = cleaned.replaceAll(
      RegExp(
        r'\b(?:Image|Photo|Frame|View|Mid-ground|Foreground|Background|Top Left|Top Right|Bottom Left|Bottom Right|Perspective|Subject|Details|Key elements|Key objects|Visible objects|Objects seen|Items detected|Main items)\s*\d*\s*:?\s*',
        caseSensitive: false,
      ),
      '',
    );

    // 5. Normalize punctuation spacing
    cleaned = cleaned.replaceAll(RegExp(r'\s+([.!?])'), r'$1');

    // 6. Split into sentences, keep only content sentences
    final List<String> sentences = cleaned.split(RegExp(r'(?<=[.!?])\s+|\n+'));
    final List<String> kept = [];

    for (final s in sentences) {
      final t = s.trim();
      if (t.isEmpty || t.length < 5) continue;

      final lower = t.toLowerCase();

      // SKIP any sentence that contains meta/reasoning/instruction keywords
      if (lower.contains('i need to') ||
          lower.contains('i should') ||
          lower.contains('i will') ||
          lower.contains('let me') ||
          lower.contains('the user') ||
          lower.contains('user wants') ||
          lower.contains('direct list') ||
          lower.contains('need to scan') ||
          lower.contains('identify the') ||
          lower.contains('looking at the') ||
          lower.contains('camera frame') ||
          lower.contains('description of') ||
          lower.contains('should avoid') ||
          lower.contains('introductory') ||
          lower.contains('be concise') ||
          lower.contains('collage') ||
          lower.contains('different views') ||
          lower.contains('multiple views') ||
          lower.contains('perspective is') ||
          lower.contains('visible objects') ||
          lower.contains('objects seen')) {
        continue;
      }

      kept.add(t);
    }

    if (kept.isNotEmpty) {
      cleaned = kept.join(' ');
    }

    // 7. Clean whitespace
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    // 8. Prepend "I see " and ensure direct content follows
    if (cleaned.isNotEmpty) {
      // Strip any existing "I see" / "There appears to be" / "In front of you" prefix
      cleaned = cleaned
          .replaceAll(
            RegExp(
              r'^(?:I see|I can see|There appears to be|In front of you is|There is|There are|Here we have|This shows|The image shows|The photo shows)\s+',
              caseSensitive: false,
            ),
            '',
          )
          .trim();

      if (cleaned.isNotEmpty) {
        final String firstChar = cleaned[0].toLowerCase();
        final String rest = cleaned.substring(1);
        cleaned = 'I see $firstChar$rest';
      }
    }

    // 9. Append closing call-to-action
    const String cta =
        ' If you want to know anything else, tap on the Describe button again or call for help.';
    if (!cleaned.contains('Describe button') &&
        !cleaned.contains('call for help')) {
      cleaned = '$cleaned$cta';
    }

    return cleaned;
  }
}
