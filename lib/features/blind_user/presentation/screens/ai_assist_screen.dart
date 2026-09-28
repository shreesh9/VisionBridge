/// VisionBridge — AI Assist Screen (Camera + Detection)
///
/// Live camera feed with detection overlays, spoken results.
/// Confidence-based escalation per build spec Section 1.
/// Fully voice-driven — TTS narration, STT commands.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/locale/supported_voice_languages.dart';
import '../../../../services/tts_stt_service.dart';
import '../../../../services/permission_service.dart';
import '../../../../services/call_orchestration_service.dart';
import '../../../../services/user_settings_service.dart';
import '../../../../services/vision_ai_service.dart';
import '../../../../shared/widgets/glass_container.dart';

class AIAssistScreen extends StatefulWidget {
  const AIAssistScreen({super.key});

  @override
  State<AIAssistScreen> createState() => _AIAssistScreenState();
}

class _AIAssistScreenState extends State<AIAssistScreen> with WidgetsBindingObserver {
  // Camera
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  String? _cameraError;
  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  double _currentZoom = 1.0;
  double _baseZoom = 1.0;

  // AI & Detection
  late final ObjectDetector _objectDetector;
  final TTSSTTService _ttsService = TTSSTTService();
  final PermissionService _permissionService = PermissionService();

  List<DetectedObject> _mlKitObjects = [];
  Size _capturedImageSize = Size.zero;

  bool _isDetecting = false;
  bool _isDescribing = false;
  bool _isEscalating = false;
  String _lastDescription = 'Point your camera to start detecting...';
  final List<String> _detectedObjects = [];
  String? _descriptionSource;

  StreamSubscription<VoiceCommand>? _commandSub;
  Timer? _descriptionDismissTimer;
  bool _isSpeakingDescription = false;
  String _localeCode = 'en'; // Current app locale for TTS language

  /// Voice narration strings for the current language. All spoken prompts
  /// MUST come from here so narration is always in the selected language
  /// (an English string spoken by an Indic voice sounds wrong/accented).
  VBLanguage get _lang => VBLanguages.byCode(_localeCode);

  void _stopSpeaking() {
    _descriptionDismissTimer?.cancel();
    _ttsService.stopSpeaking();
    if (mounted) {
      setState(() {
        _isSpeakingDescription = false;
        _isDescribing = false;
        _mlKitObjects = [];
      });
    }
  }

  void _scheduleAutoDismiss(String text) {
    _descriptionDismissTimer?.cancel();

    // Calculate reading duration based on word count (approx 1.8 words per second). Minimum 20 seconds!
    final wordCount =
        text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final int durationSeconds = (wordCount / 1.8).ceil().clamp(20, 90);

    _descriptionDismissTimer = Timer(Duration(seconds: durationSeconds), () {
      if (mounted) {
        setState(() {
          _isSpeakingDescription = false;
          _mlKitObjects = [];
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize ML Kit Object Detector
    final options = ObjectDetectorOptions(
      mode: DetectionMode.single,
      classifyObjects: true,
      multipleObjects: true,
    );
    _objectDetector = ObjectDetector(options: options);

    _initializeCamera();
    _initializeTTS();
    _loadLocale();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _stopSpeaking();
      _ttsService.stopSpeaking();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _descriptionDismissTimer?.cancel();
    _commandSub?.cancel();
    _stopSpeaking();
    _ttsService.stopSpeaking();
    _cameraController?.dispose();
    _objectDetector.close();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    // Request camera + mic permissions
    final granted = await _permissionService.requestAIAssistPermissions();
    if (!granted) {
      setState(() {
        _cameraError = _lang.voice(VoiceKey.cameraPermission);
      });
      _ttsService.speak(_lang.voice(VoiceKey.cameraPermission), force: true);
      return;
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _cameraError = 'No cameras found on this device.');
        return;
      }

      // Use back camera for scene detection
      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
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
        setState(() {
          _isCameraInitialized = true;
          _isDetecting = true;
        });
        _ttsService.speak(_lang.voice(VoiceKey.cameraReady), force: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cameraError = 'Failed to initialize camera: $e');
      }
    }
  }

  Future<void> _initializeTTS() async {
    await _ttsService.initialize();

    // Listen for voice commands
    _commandSub = _ttsService.commands.listen((command) {
      switch (command) {
        case VoiceCommand.describe:
          _describeScene();
          break;
        case VoiceCommand.call:
          _requestVolunteer();
          break;
        case VoiceCommand.stop:
          _ttsService.stopSpeaking();
          break;
        case VoiceCommand.emergency:
          if (mounted) context.push(AppRoutes.sos);
          break;
        default:
          break;
      }
    });
  }

  Future<void> _loadLocale() async {
    try {
      _localeCode = await UserSettingsService.getLocaleCode();
      await _ttsService.setLocale(_localeCode);
      if (mounted) {
        setState(() {
          // Show the analyzing prompt in the current language so the
          // description card is consistent before the first scan.
          _lastDescription = _lang.voice(VoiceKey.analyzingScene);
        });
      }
    } catch (_) {}
  }

  /// Compress and downsample captured photo bytes to 640px JPEG for fast sub-second Groq API transmission
  Future<String> _compressAndEncodeImage(Uint8List rawBytes) async {
    try {
      final codec = await ui.instantiateImageCodec(
        rawBytes,
        targetWidth: 640,
      );
      final frameInfo = await codec.getNextFrame();
      final image = frameInfo.image;
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (byteData != null) {
        return base64Encode(byteData.buffer.asUint8List());
      }
    } catch (_) {}
    return base64Encode(rawBytes);
  }

  /// Capture current frame and process through AI-First Vision Pipeline
  Future<void> _describeScene() async {
    if (_isDescribing ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      _localeCode = await UserSettingsService.getLocaleCode();
    } catch (_) {}

    // Ensure TTS engine is set to the correct language before speaking
    await _ttsService.setLocale(_localeCode);

    _descriptionDismissTimer?.cancel();
    setState(() {
      _isDescribing = true;
      _isSpeakingDescription = false;
      _lastDescription = _lang.voice(VoiceKey.analyzingScene);
      _descriptionSource = null;
      _mlKitObjects = [];
    });
    HapticFeedback.selectionClick();
    await _ttsService.stopSpeaking();
    _ttsService.speak(_lang.voice(VoiceKey.analyzingScene), force: true);

    try {
      // 1. Capture photo from camera feed
      final XFile photo = await _cameraController!.takePicture();
      final Uint8List rawImageBytes = await photo.readAsBytes();

      // 2. Fast sub-second downsampling to 640px
      final String base64Image = await _compressAndEncodeImage(rawImageBytes);

      // 3. Decode image dimensions for bounding box overlay
      final codec = await ui.instantiateImageCodec(rawImageBytes);
      final frameInfo = await codec.getNextFrame();
      final double imgW = frameInfo.image.width.toDouble();
      final double imgH = frameInfo.image.height.toDouble();
      frameInfo.image.dispose();

      // 4. Run On-Device ML Kit Object Detection
      final inputImage = InputImage.fromFilePath(photo.path);
      final List<DetectedObject> detectedObjects =
          await _objectDetector.processImage(inputImage);

      const genericCategories = {
        'Food',
        'Fashion good',
        'Home good',
        'Place',
        'Plant',
        'Goods',
        'Unknown'
      };

      final double confidenceThreshold =
          await UserSettingsService.getConfidenceThreshold();

      final List<String> objectLabels = [];
      for (final obj in detectedObjects) {
        for (final label in obj.labels) {
          if (!genericCategories.contains(label.text) &&
              label.confidence >= confidenceThreshold) {
            objectLabels.add(label.text);
          }
        }
      }

      if (mounted) {
        setState(() {
          _mlKitObjects = detectedObjects;
          _capturedImageSize = Size(imgW, imgH);
          _detectedObjects.clear();
          _detectedObjects.addAll(objectLabels.toSet().take(6));
        });

        // Grid lines stay on screen for ONLY 2 seconds after clicking describe, then vanish!
        Timer(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _mlKitObjects = [];
            });
          }
        });
      }

      // 5. Query Universal Vision AI Engine (Gemini 1.5 Flash -> Groq -> On-Device)
      final visionService = VisionAIService();
      final customGeminiKey = await UserSettingsService.getGeminiApiKey();
      final customGroqKey = await UserSettingsService.getGroqApiKey();

      final result = await visionService.describeScene(
        base64Image: base64Image,
        detectedObjects: _detectedObjects,
        customGeminiKey: customGeminiKey,
        customGroqKey: customGroqKey,
      );

      if (mounted) {
        setState(() {
          _lastDescription = result.description;
          _descriptionSource = result.provider;
          _isDescribing = false;
          _isSpeakingDescription = true;
          _mlKitObjects = [];
        });

        // Narrate AI vision description out loud
        await _ttsService.speak(result.description, force: true);

        // Schedule auto-dismiss safety fallback based on dynamic reading duration
        _scheduleAutoDismiss(result.description);
      }
    } catch (e) {
      if (mounted) {
        final String errorMsg = e.toString().contains('429')
            ? _lang.errorRateLimit()
            : 'AI Vision Error: ${e.toString()}';
        setState(() {
          _lastDescription = errorMsg;
          _descriptionSource = '⚠️ Error';
          _isDescribing = false;
          _isSpeakingDescription = true;
        });

        await _ttsService.stopSpeaking();
        await _ttsService.speak(errorMsg, force: true);
        _scheduleAutoDismiss(errorMsg);
      }
    }
  }

  Future<void> _requestVolunteer() async {
    HapticFeedback.lightImpact();

    // *** CRITICAL: Null out the camera reference INSIDE setState ***
    // so the build method immediately stops rendering CameraPreview.
    // Save the reference so we can dispose it after the UI update.
    final controllerToDispose = _cameraController;
    setState(() {
      _isEscalating = true;
      _cameraController = null;
      _isCameraInitialized = false;
    });

    _ttsService.speak(_lang.voice(VoiceKey.connectingVolunteer), force: true);

    // Now dispose the saved camera controller reference safely
    try {
      await controllerToDispose?.dispose();
    } catch (_) {
      // Ignore disposal errors — camera may already be released
    }

    // Wait for Android to fully release the camera hardware lock.
    await Future.delayed(const Duration(milliseconds: 300));

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final callRequestId = await CallOrchestrationService.instance
            .requestVolunteerHelp(
          blindUserId: uid,
          detectedObjects: _detectedObjects,
          aiDescription: _lastDescription,
        );
        if (mounted) {
          setState(() => _isEscalating = false);
          context.push(AppRoutes.buInCall);
        }
      } catch (e) {
        debugPrint('[AI Assist] Call request failed: $e');
        if (mounted) {
          setState(() => _isEscalating = false);
          _ttsService.speak(_lang.voice(VoiceKey.connectFailed), force: true);
        }
      }
    } else {
      setState(() => _isEscalating = false);
      _ttsService.speak(_lang.voice(VoiceKey.signInToCall), force: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? VBDarkColors.primary : VBLightColors.primary;
    final surfaceColor = isDark ? VBDarkColors.surface : VBLightColors.surface;
    final textColor = isDark ? VBDarkColors.onSurface : VBLightColors.onSurface;
    final subtextColor =
        isDark ? VBDarkColors.onSurfaceVariant : VBLightColors.onSurfaceVariant;
    final successColor = isDark ? VBDarkColors.success : VBLightColors.success;
    final warningColor = isDark ? VBDarkColors.warning : VBLightColors.warning;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview area (full screen)
          if (_isCameraInitialized && _cameraController != null && _cameraController!.value.isInitialized)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onScaleStart: (details) {
                _baseZoom = _currentZoom;
              },
              onScaleUpdate: (details) async {
                if (_cameraController == null || !_isCameraInitialized) return;
                final newZoom = (_baseZoom * details.scale).clamp(_minZoom, _maxZoom);
                if ((newZoom - _currentZoom).abs() > 0.04) {
                  _currentZoom = newZoom;
                  try {
                    await _cameraController!.setZoomLevel(_currentZoom);
                  } catch (_) {}
                  HapticFeedback.selectionClick();
                  if (mounted) setState(() {});
                }
              },
              child: SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _cameraController!.value.previewSize?.height ?? 1,
                    height: _cameraController!.value.previewSize?.width ?? 1,
                    child: CameraPreview(_cameraController!),
                  ),
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_cameraError != null) ...[
                      const Icon(
                        Icons.camera_alt_outlined,
                        size: 64,
                        color: Colors.white24,
                      ),
                      const SizedBox(height: VBSpacing.md),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: VBSpacing.xl),
                        child: Text(
                          _cameraError!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 14),
                        ),
                      ),
                      const SizedBox(height: VBSpacing.lg),
                      OutlinedButton(
                        onPressed: () => _permissionService.openSettings(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white38),
                        ),
                        child: Text(_lang.voice(VoiceKey.openSettings)),
                      ),
                    ] else ...[
                      const CircularProgressIndicator(color: Colors.white54),
                      const SizedBox(height: VBSpacing.md),
                      Text(
                        _lang.voice(VoiceKey.startingCamera),
                        style: const TextStyle(color: Colors.white38, fontSize: 14),
                      ),
                    ],
                  ],
                ),
              ),
            ),

          // Live Object Detection Bounding Box Overlay
          if (_mlKitObjects.isNotEmpty && _capturedImageSize != Size.zero)
            Positioned.fill(
              child: CustomPaint(
                painter: _ObjectBoundingBoxPainter(
                  objects: _mlKitObjects,
                  imageSize: _capturedImageSize,
                  color: primaryColor,
                ),
              ),
            ),

          // Top bar — back button + status
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(VBSpacing.md),
                child: Row(
                  children: [
                    // Back
                    Semantics(
                      button: true,
                      label: 'Go back',
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            _ttsService.stopSpeaking();
                            context.pop();
                          },
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Detection status indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: VBSpacing.md,
                        vertical: VBSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(VBRadius.full),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _isCameraInitialized
                                  ? (_isDescribing
                                      ? warningColor
                                      : successColor)
                                  : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: VBSpacing.sm),
                          Text(
                            _isDescribing
                                ? _lang.voice(VoiceKey.analyzing)
                                : _isCameraInitialized
                                    ? _lang.voice(VoiceKey.aiReady)
                                    : _lang.voice(VoiceKey.starting),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Detected Object Chip Overlay
          if (_detectedObjects.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + 70,
              left: VBSpacing.md,
              right: VBSpacing.md,
              child: Wrap(
                spacing: VBSpacing.sm,
                runSpacing: VBSpacing.sm,
                children: _detectedObjects.map((obj) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: VBSpacing.sm,
                      vertical: VBSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(VBRadius.sm),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Text(
                      obj,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          // Escalation banner
          if (_isEscalating)
            Positioned(
              top: MediaQuery.of(context).padding.top + 120,
              left: VBSpacing.md,
              right: VBSpacing.md,
              child: Semantics(
                liveRegion: true,
                label: 'Connecting you to a volunteer.',
                child: Container(
                  padding: const EdgeInsets.all(VBSpacing.md),
                  decoration: BoxDecoration(
                    color: warningColor.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(VBRadius.md),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: VBSpacing.sm),
                      Expanded(
                        child: Text(
                          _lang.voice(VoiceKey.connectingVolunteer),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Floating Glassmorphic Description Card (Shown ONLY during analyzing or scene description speaking)
          if (_isDescribing || _isSpeakingDescription)
            Positioned(
              bottom: 110,
              left: VBSpacing.md,
              right: VBSpacing.md,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.35,
                ),
                child: GestureDetector(
                  onTap: () async {
                    HapticFeedback.selectionClick();
                    if (_ttsService.isSpeaking) {
                      await _ttsService.stopSpeaking();
                    } else if (_lastDescription.isNotEmpty) {
                      await _ttsService.stopSpeaking();
                      _ttsService.speak(_lastDescription, force: true);
                    }
                  },
                  child: GlassContainer(
                    width: double.infinity,
                    borderRadius: VBRadius.xl,
                    blur: 16.0,
                    opacity: 0.18,
                    borderColor: primaryColor.withOpacity(0.4),
                    borderWidth: 1.5,
                    padding: const EdgeInsets.all(VBSpacing.md),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Window Header Bar with AI Provider Pill
                        if (_descriptionSource != null)
                          Padding(
                            padding:
                                const EdgeInsets.only(bottom: VBSpacing.xs),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: VBSpacing.sm,
                                vertical: VBSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.2),
                                borderRadius:
                                    BorderRadius.circular(VBRadius.sm),
                                border: Border.all(
                                  color: primaryColor.withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: primaryColor,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: primaryColor,
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: VBSpacing.xs),
                                  Flexible(
                                    child: Text(
                                      _descriptionSource!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: primaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: VBSpacing.sm),
                        // Scrollable Description Text Body
                        Flexible(
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            child: Text(
                              _lastDescription,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 16,
                                height: 1.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Bottom Action Bar (Glassmorphic Floating Bar with Soft Rounded Edges)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: EdgeInsets.only(
                left: VBSpacing.sm,
                right: VBSpacing.sm,
                bottom: MediaQuery.of(context).padding.bottom > 0
                    ? MediaQuery.of(context).padding.bottom + 4
                    : VBSpacing.sm,
              ),
              child: GlassContainer(
                width: double.infinity,
                borderRadius: 28.0,
                blur: 24.0,
                opacity: isDark ? 0.25 : 0.45,
                borderColor: Colors.white.withOpacity(0.25),
                borderWidth: 1.5,
                padding: const EdgeInsets.symmetric(
                  horizontal: VBSpacing.md,
                  vertical: VBSpacing.sm + 2,
                ),
                child: Row(
                  children: [
                    // Describe / Stop button (Primary action)
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: VBTouchTarget.primaryAction,
                        child: ElevatedButton.icon(
                          onPressed: (_isDescribing || _isSpeakingDescription)
                              ? _stopSpeaking
                              : _describeScene,
                          style: (_isDescribing || _isSpeakingDescription)
                              ? ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade600,
                                  foregroundColor: Colors.white,
                                )
                              : null,
                          icon: _isDescribing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon((_isDescribing || _isSpeakingDescription)
                                  ? Icons.stop_circle_rounded
                                  : Icons.remove_red_eye_rounded),
                          label: Text(
                            _isDescribing
                                ? _lang.voice(VoiceKey.analyzing)
                                : _isSpeakingDescription
                                    ? _lang.voice(VoiceKey.stop)
                                    : _lang.voice(VoiceKey.describeScene),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: VBSpacing.md),

                    // Call Help button (Secondary / Emergency action)
                    Expanded(
                      child: SizedBox(
                        height: VBTouchTarget.primaryAction,
                        child: OutlinedButton.icon(
                          onPressed: _isEscalating ? null : _requestVolunteer,
                          icon: const Icon(Icons.call_rounded),
                          label: Text(_lang.voice(VoiceKey.callHelp)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark
                                ? VBDarkColors.secondary
                                : VBLightColors.secondary,
                            side: BorderSide(
                              color: isDark
                                  ? VBDarkColors.secondary
                                  : VBLightColors.secondary,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for on-device object detection bounding boxes
class _ObjectBoundingBoxPainter extends CustomPainter {

  _ObjectBoundingBoxPainter({
    required this.objects,
    required this.imageSize,
    required this.color,
  });
  final List<DetectedObject> objects;
  final Size imageSize;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (objects.isEmpty || imageSize.width == 0 || imageSize.height == 0) {
      return;
    }

    final double scale =
        math.max(size.width / imageSize.width, size.height / imageSize.height);
    final double renderedW = imageSize.width * scale;
    final double renderedH = imageSize.height * scale;
    final double offsetX = (size.width - renderedW) / 2;
    final double offsetY = (size.height - renderedH) / 2;

    final Paint boxPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (final obj in objects) {
      final Rect rect = obj.boundingBox;

      final double left = rect.left * scale + offsetX;
      final double top = rect.top * scale + offsetY;
      final double width = rect.width * scale;
      final double height = rect.height * scale;

      final RRect screenRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, width, height),
        const Radius.circular(8),
      );

      // Draw bounding box
      canvas.drawRRect(screenRRect, boxPaint);

      // Label text
      if (obj.labels.isNotEmpty) {
        final label = obj.labels.first;
        const genericCategories = {
          'Food',
          'Fashion good',
          'Home good',
          'Place',
          'Plant',
          'Goods',
          'Unknown'
        };
        if (genericCategories.contains(label.text)) continue;

        final String labelText =
            '${label.text} (${(label.confidence * 100).round()}%)';

        textPainter.text = TextSpan(
          text: labelText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            backgroundColor: Color(0xCC6C5CE7),
          ),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(left, math.max(0, top - 20)));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ObjectBoundingBoxPainter oldDelegate) {
    return oldDelegate.objects != objects || oldDelegate.color != color;
  }
}
