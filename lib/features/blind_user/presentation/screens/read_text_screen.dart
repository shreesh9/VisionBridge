/// VisionBridge — Read Text Screen (ML Kit OCR)
///
/// Dedicated high-speed OCR document & sign reader.
/// Uses Google ML Kit Text Recognition on-device for zero-latency,
/// offline-capable text extraction and automatic TTS narration.
library;

import 'dart:io';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../../../services/tts_stt_service.dart';
import '../../../../services/permission_service.dart';
import '../../../../services/user_settings_service.dart';
import '../../../../core/locale/supported_voice_languages.dart';
import '../../../../shared/widgets/glass_container.dart';

class ReadTextScreen extends StatefulWidget {
  const ReadTextScreen({super.key});

  @override
  State<ReadTextScreen> createState() => _ReadTextScreenState();
}

class _ReadTextScreenState extends State<ReadTextScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  String? _cameraError;
  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  double _currentZoom = 1.0;
  double _baseZoom = 1.0;

  final TTSSTTService _ttsService = TTSSTTService();
  final PermissionService _permissionService = PermissionService();

  bool _isScanning = false;
  String _extractedText = 'Point camera at any text, sign, or document and tap Read.';
  Size _containerSize = Size.zero;
  String _localeCode = 'en';

  /// Voice narration strings for the current language — all spoken prompts
  /// come from the registry so narration is always in the selected language.
  VBLanguage get _lang => VBLanguages.byCode(_localeCode);

  late AnimationController _scanAnimationController;

  @override
  void initState() {
    super.initState();
    _scanAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _initializeCamera();
    _loadLocaleAndTTS();
  }

  Future<void> _initializeCamera() async {
    final granted = await _permissionService.requestAIAssistPermissions();
    if (!granted) {
      if (mounted) {
        setState(() => _cameraError = 'Camera permission required to read text.');
      }
      return;
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _cameraError = 'No camera found on device.');
        return;
      }

      final backCamera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      try {
        _minZoom = await _cameraController!.getMinZoomLevel();
        final maxZ = await _cameraController!.getMaxZoomLevel();
        _maxZoom = (maxZ > 1.0) ? maxZ : 8.0;
        _currentZoom = _minZoom;
      } catch (_) {
        _minZoom = 1.0;
        _maxZoom = 8.0;
        _currentZoom = 1.0;
      }

      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cameraError = 'Failed to initialize camera: $e');
      }
    }
  }

  Future<void> _loadLocaleAndTTS() async {
    try {
      _localeCode = await UserSettingsService.getLocaleCode();
    } catch (_) {}
    await _ttsService.initialize();
    await _ttsService.setLocale(_localeCode);
    if (!mounted) return;
    // Placeholder hint shown in the result card, in the current language.
    _extractedText = _lang.ui(UIKey.pointCameraHint);
    _ttsService.speak(_lang.voice(VoiceKey.scannerReady), force: true);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _scanAnimationController.dispose();
    _cameraController?.dispose();
    _ttsService.dispose();
    super.dispose();
  }

  /// Run one ML Kit text recognition pass with a freshly created recognizer
  /// that is closed immediately after use.
  ///
  /// CRITICAL: The google_mlkit_text_recognition plugin crashes natively
  /// (app killed, no Dart exception) when 2+ TextRecognizers are created or
  /// used at the same time (flutter-ml issue #519). The old code held Latin
  /// AND Devanagari recognizers as long-lived fields and ran them in parallel
  /// via Future.wait — which crashed the app on every scan on many devices.
  /// Never instantiate two recognizers concurrently.
  Future<RecognizedText?> _runRecognition(
    InputImage inputImage,
    TextRecognitionScript script,
  ) async {
    TextRecognizer? recognizer;
    try {
      recognizer = TextRecognizer(script: script);
      return await recognizer.processImage(inputImage);
    } catch (e) {
      debugPrint('[ReadText] ${script.name} recognition failed: $e');
      return null;
    } finally {
      try {
        recognizer?.close();
      } catch (_) {}
    }
  }

  /// Detect whether a string is predominantly Hindi (Devanagari), English
  /// (Latin) or another Indic script.
  ///
  /// Returns the app language code whose SCRIPT matches the text:
  /// 'hi' for ANY Devanagari text (also read by Marathi users — see
  /// TTSSTTService.speakWithLanguage), 'en' for Latin, or 'ta'/'te'/'bn'/'kn'
  /// when the majority of letters belong to that script.
  String _detectTextLanguage(String text) {
    final counts = <String, int>{
      'en': 0,
      'hi': 0,
      'ta': 0,
      'te': 0,
      'bn': 0,
      'kn': 0,
    };
    for (final rune in text.runes) {
      // Basic Latin letters A-Z, a-z
      if ((rune >= 0x0041 && rune <= 0x005A) ||
          (rune >= 0x0061 && rune <= 0x007A)) {
        counts['en'] = counts['en']! + 1;
      } else {
        switch (VBLanguages.scriptOfRune(rune)) {
          case VoiceScript.latin:
            break; // non-letter ASCII/punctuation — ignore
          case VoiceScript.devanagari:
            counts['hi'] = counts['hi']! + 1;
          case VoiceScript.bengali:
            counts['bn'] = counts['bn']! + 1;
          case VoiceScript.dravidian:
            // Distinguish Tamil (0x0B80–0x0BFF) vs Telugu (0x0C00–0x0C7F)
            // vs Kannada (0x0C80–0x0CFF) blocks.
            if (rune <= 0x0BFF) {
              counts['ta'] = counts['ta']! + 1;
            } else if (rune <= 0x0C7F) {
              counts['te'] = counts['te']! + 1;
            } else {
              counts['kn'] = counts['kn']! + 1;
            }
        }
      }
    }

    String best = 'en';
    int bestCount = counts['en']!;
    for (final entry in counts.entries) {
      if (entry.key == 'en') continue;
      if (entry.value > bestCount) {
        best = entry.key;
        bestCount = entry.value;
      }
    }
    return best;
  }

  Future<void> _scanAndReadText() async {
    if (_isScanning || _cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      _localeCode = await UserSettingsService.getLocaleCode();
    } catch (_) {}

    // Stop any ongoing speech immediately before starting a new scan
    await _ttsService.stopSpeaking();

    setState(() => _isScanning = true);
    HapticFeedback.selectionClick();
    _ttsService.speak(_lang.voice(VoiceKey.scanningText), force: true);

    try {
      final XFile photo = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(photo.path);

      // Run recognizers SEQUENTIALLY, one at a time (see _runRecognition —
      // parallel recognizers crash the app natively). Same merged quality as
      // before: whichever script finds the richer text wins.
      final RecognizedText? latinResult =
          await _runRecognition(inputImage, TextRecognitionScript.latin);
      final RecognizedText? devanagariResult =
          await _runRecognition(inputImage, TextRecognitionScript.devanagiri);

      // Decode exact captured image dimensions to map viewfinder crop bounds
      final bytes = await File(photo.path).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frameInfo = await codec.getNextFrame();
      final double imgW = frameInfo.image.width.toDouble();
      final double imgH = frameInfo.image.height.toDouble();
      frameInfo.image.dispose();

      // Extract visible lines from both recognizers
      List<String> extractVisibleLines(RecognizedText? recognized) {
        final List<String> lines = [];
        if (recognized == null) return lines;
        if (_containerSize.width > 0 &&
            _containerSize.height > 0 &&
            imgW > 0 &&
            imgH > 0) {
          final double containerW = _containerSize.width;
          final double containerH = _containerSize.height;
          final double scale = math.max(containerW / imgW, containerH / imgH);
          final double renderedW = imgW * scale;
          final double renderedH = imgH * scale;
          final double offsetX = (containerW - renderedW) / 2;
          final double offsetY = (containerH - renderedH) / 2;
          final double minX = -offsetX / scale;
          final double maxX = (containerW - offsetX) / scale;
          final double minY = -offsetY / scale;
          final double maxY = (containerH - offsetY) / scale;

          for (final TextBlock block in recognized.blocks) {
            for (final TextLine line in block.lines) {
              final Rect lineRect = line.boundingBox;
              final Offset center = lineRect.center;
              if (center.dx >= minX &&
                  center.dx <= maxX &&
                  center.dy >= minY &&
                  center.dy <= maxY) {
                lines.add(line.text);
              }
            }
          }
        } else {
          for (final TextBlock block in recognized.blocks) {
            for (final TextLine line in block.lines) {
              lines.add(line.text);
            }
          }
        }
        return lines;
      }

      final List<String> latinLines = extractVisibleLines(latinResult);
      final List<String> devanagariLines = extractVisibleLines(devanagariResult);

      // Merge: use whichever recognizer found more text, or combine both
      final String latinText = latinLines.join('\n').trim();
      final String devanagariText = devanagariLines.join('\n').trim();

      // Pick the best result — prefer the one with more meaningful content
      // (Latin and Devanagari are the two bundled script passes).
      String text;
      if (devanagariText.isNotEmpty && latinText.isNotEmpty) {
        // Both found text — use the longer one (more characters = more accurate match)
        text = devanagariText.length >= latinText.length ? devanagariText : latinText;
      } else if (devanagariText.isNotEmpty) {
        text = devanagariText;
      } else {
        text = latinText;
      }

      // Auto-detect the language of the extracted text.
      // NOTE: ML Kit (google_mlkit_text_recognition 0.13.x) only ships Latin
      // and Devanagari (plus CJK) recognizers — there is NO Tamil/Telugu/
      // Bengali/Kannada on-device recognition. Scans of those scripts return
      // "No text found"; reading them aloud would need Google Cloud Vision
      // (server-based). Voice support for those languages is otherwise full
      // (TTS, AI descriptions, voice commands).
      final String detectedLang = _detectTextLanguage(text);

      if (mounted) {
        setState(() {
          _isScanning = false;
          if (text.isNotEmpty) {
            _extractedText = text;
          } else {
            _extractedText = _lang.voice(VoiceKey.noTextFound);
          }
        });

        // Always stop previous speech before reading newly extracted text out loud
        await _ttsService.stopSpeaking();

        if (text.isNotEmpty) {
          // OCR reads in the DETECTED language, NOT the app toggle language.
          // (Devanagari text maps to the app's Devanagari voice language —
          // see TTSSTTService.speakWithLanguage.) The spoken prefix must be
          // in that same effective voice language, not the app language.
          final String effectiveLang =
              _ttsService.effectiveVoiceLanguageCode(detectedLang);
          final String prefix = effectiveLang == 'en'
              ? ''
              : VBLanguages.byCode(effectiveLang).readAloudPrefix();
          await _ttsService.speakWithLanguage(
            '$prefix$text',
            detectedLang,
            force: true,
          );
        } else {
          _ttsService.speak(_lang.voice(VoiceKey.noTextRetry), force: true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _extractedText = '${_lang.ui(UIKey.readTextOcr)}: $e';
        });
        await _ttsService.stopSpeaking();
        _ttsService.speak(_lang.voice(VoiceKey.ocrError), force: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? VBDarkColors.background : VBLightColors.background;
    final textColor = isDark ? VBDarkColors.onSurface : VBLightColors.onSurface;
    final primaryColor = isDark ? VBDarkColors.primary : VBLightColors.primary;
    final frameColor = _isScanning ? Colors.amber : primaryColor;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textColor),
          onPressed: () {
            _ttsService.stopSpeaking();
            context.pop();
          },
        ),
        title: Text(
          _lang.ui(UIKey.readTextOcr),
          style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Fitted Camera Feed Container with Full-Window Framing Reticle
            Expanded(
              flex: 5,
              child: Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: VBSpacing.md,
                  vertical: VBSpacing.xs,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(VBRadius.xl),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.15),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(VBRadius.xl),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Camera Preview with Fitted Aspect Ratio
                      if (_isCameraInitialized &&
                          _cameraController != null &&
                          _cameraController!.value.isInitialized)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            _containerSize = Size(
                              constraints.maxWidth,
                              constraints.maxHeight,
                            );
                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onScaleStart: (details) {
                                _baseZoom = _currentZoom;
                              },
                              onScaleUpdate: (details) async {
                                if (_cameraController == null || !_isCameraInitialized) return;
                                final newZoom = (_baseZoom * details.scale).clamp(_minZoom, _maxZoom);
                                if ((newZoom - _currentZoom).abs() > 0.04) {
                                  _currentZoom = newZoom;
                                  await _cameraController!.setZoomLevel(_currentZoom);
                                  HapticFeedback.selectionClick();
                                  if (mounted) setState(() {});
                                }
                              },
                              child: SizedBox(
                                width: constraints.maxWidth,
                                height: constraints.maxHeight,
                                child: FittedBox(
                                  fit: BoxFit.cover,
                                  child: SizedBox(
                                    width: _cameraController!.value.previewSize!.height,
                                    height: _cameraController!.value.previewSize!.width,
                                    child: CameraPreview(_cameraController!),
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                      else
                        Container(
                          color: const Color(0xFF181A24),
                          child: Center(
                            child: _cameraError != null
                                ? Text(_cameraError!, style: TextStyle(color: textColor))
                                : CircularProgressIndicator(color: primaryColor),
                          ),
                        ),

                      // Full Viewfinder Framing Reticle Overlay
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.all(VBSpacing.sm),
                          child: AnimatedBuilder(
                            animation: _scanAnimationController,
                            builder: (context, child) {
                              return CustomPaint(
                                painter: _ScannerReticlePainter(
                                  color: frameColor,
                                  isScanning: _isScanning,
                                  scanProgress: _scanAnimationController.value,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Extracted Text Glass Card (Interactive: Tap to Replay or Stop Speech)
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: VBSpacing.md,
                  vertical: VBSpacing.xs,
                ),
                child: GestureDetector(
                  onTap: () async {
                    HapticFeedback.selectionClick();
                    if (_ttsService.isSpeaking) {
                      await _ttsService.stopSpeaking();
                    } else if (_extractedText.isNotEmpty &&
                        !_extractedText.startsWith('Point camera') &&
                        !_extractedText.startsWith('\u0915\u0948\u092e\u0930\u093e \u0915\u093f\u0938\u0940')) {
                      await _ttsService.stopSpeaking();
                      // Replay in the detected language of the text
                      final replayLang = _detectTextLanguage(_extractedText);
                      _ttsService.speakWithLanguage(_extractedText, replayLang, force: true);
                    }
                  },
                  child: GlassContainer(
                    width: double.infinity,
                    borderRadius: VBRadius.lg,
                    opacity: 0.12,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.menu_book_rounded, color: primaryColor, size: 20),
                                  const SizedBox(width: VBSpacing.xs),
                                  Text(
                                    _lang.ui(UIKey.extractedText),
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Icon(
                                    _ttsService.isSpeaking
                                        ? Icons.volume_up_rounded
                                        : Icons.volume_mute_rounded,
                                    color: primaryColor.withOpacity(0.7),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _lang.ui(UIKey.tapToSpeakStop),
                                    style: TextStyle(
                                      color: primaryColor.withOpacity(0.6),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: VBSpacing.sm),
                          Text(
                            _extractedText,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Scan Action Button (Press to Read / Re-scan & Interrupt)
            Padding(
              padding: const EdgeInsets.all(VBSpacing.md),
              child: SizedBox(
                width: double.infinity,
                height: VBTouchTarget.primaryAction,
                child: ElevatedButton.icon(
                  onPressed: _isScanning ? null : _scanAndReadText,
                  icon: _isScanning
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.document_scanner_rounded),
                  label: Text(_isScanning
                      ? _lang.voice(VoiceKey.scanningText)
                      : _lang.ui(UIKey.readTextOutLoud)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for camera viewfinder framing reticle & scanning laser beam
class _ScannerReticlePainter extends CustomPainter {

  _ScannerReticlePainter({
    required this.color,
    required this.isScanning,
    required this.scanProgress,
  });
  final Color color;
  final bool isScanning;
  final double scanProgress;

  @override
  void paint(Canvas canvas, Size size) {
    const double radius = 20.0;
    const double cornerLength = 32.0;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(radius),
    );

    // Full bounding frame line
    final Paint borderPaint = Paint()
      ..color = color.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(rrect, borderPaint);

    // Glowing L-bracket corners
    final Paint cornerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    // Top-Left
    canvas.drawPath(
      Path()
        ..moveTo(0, cornerLength)
        ..lineTo(0, radius)
        ..arcToPoint(const Offset(radius, 0), radius: const Radius.circular(radius))
        ..lineTo(cornerLength, 0),
      cornerPaint,
    );

    // Top-Right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - cornerLength, 0)
        ..lineTo(size.width - radius, 0)
        ..arcToPoint(Offset(size.width, radius), radius: const Radius.circular(radius))
        ..lineTo(size.width, cornerLength),
      cornerPaint,
    );

    // Bottom-Left
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height - cornerLength)
        ..lineTo(0, size.height - radius)
        ..arcToPoint(Offset(radius, size.height), radius: const Radius.circular(radius))
        ..lineTo(cornerLength, size.height),
      cornerPaint,
    );

    // Bottom-Right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - cornerLength, size.height)
        ..lineTo(size.width - radius, size.height)
        ..arcToPoint(Offset(size.width, size.height - radius), radius: const Radius.circular(radius))
        ..lineTo(size.width, size.height - cornerLength),
      cornerPaint,
    );

    // Animated scan line beam
    if (isScanning) {
      final double lineY = size.height * scanProgress;
      final Paint scanLinePaint = Paint()
        ..shader = LinearGradient(
          colors: [
            color.withOpacity(0.0),
            color,
            color.withOpacity(0.0),
          ],
        ).createShader(Rect.fromLTWH(0, lineY, size.width, 3))
        ..strokeWidth = 3.5;

      canvas.drawLine(
        Offset(12, lineY),
        Offset(size.width - 12, lineY),
        scanLinePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ScannerReticlePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.isScanning != isScanning ||
        oldDelegate.scanProgress != scanProgress;
  }
}
