/// VisionBridge — BU In-Call Screen (WebRTC)
///
/// Active during WebRTC session. Shows local camera feed, call timer, "End Call".
/// One-way video out (rear camera), two-way audio.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/locale/supported_voice_languages.dart';
import '../../../../services/call_orchestration_service.dart';
import '../../../../services/webrtc_service.dart';
import '../../../../services/user_settings_service.dart';

class BUInCallScreen extends StatefulWidget {
  const BUInCallScreen({super.key});

  @override
  State<BUInCallScreen> createState() => _BUInCallScreenState();
}

class _BUInCallScreenState extends State<BUInCallScreen> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  bool _isMuted = false;
  bool _isSpeakerOn = true;
  int _callDurationSeconds = 0;
  bool _isConnected = false;
  bool _hasBeenConnected = false;
  double _callZoom = 1.0;
  double _baseCallZoom = 1.0;
  StreamSubscription<WebRTCConnectionState>? _stateSub;
  Timer? _timer;
  String _localeCode = 'en';

  /// UI strings for the current language (from the registry).
  VBLanguage get _lang => VBLanguages.byCode(_localeCode);

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
    _loadLocale();
    _setupVideo();

    final webrtcService = CallOrchestrationService.instance.webrtcService;
    if (webrtcService.currentConnectionState == WebRTCConnectionState.connected) {
      _isConnected = true;
      _hasBeenConnected = true;
      _startTimer();
    }

    _stateSub = webrtcService.connectionState.listen((state) {
      if (!mounted) return;
      if (state == WebRTCConnectionState.connected && !_isConnected) {
        setState(() => _isConnected = true);
        _hasBeenConnected = true;
        _startTimer();
      } else if (state == WebRTCConnectionState.disconnected && _hasBeenConnected) {
        _endCall();
      }
    });
  }

  Future<void> _loadLocale() async {
    try {
      _localeCode = await UserSettingsService.getLocaleCode();
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _setupVideo() async {
    // Step 1: Initialize renderer (creates native texture)
    await _localRenderer.initialize();
    if (!mounted) return;

    // Step 2: Rebuild so RTCVideoView is added to widget tree with the texture
    setState(() {});

    // Step 3: Wait for the widget to actually paint (next frame)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Step 4: NOW set srcObject — the native texture surface is active
      final localStream = CallOrchestrationService.instance.webrtcService.localStream;
      if (localStream != null) {
        _localRenderer.srcObject = localStream;
        debugPrint('[BUInCall] ✅ srcObject set: '
            'videoTracks=${localStream.getVideoTracks().length}, '
            'textureId=${_localRenderer.textureId}');
      } else {
        debugPrint('[BUInCall] ⚠️ localStream is null!');
      }
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _isConnected) {
        setState(() => _callDurationSeconds++);
      }
    });
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _endCall() async {
    _timer?.cancel();
    _stateSub?.cancel();
    HapticFeedback.heavyImpact();
    if (_hasBeenConnected) {
      await CallOrchestrationService.instance.endCall(
        durationSeconds: _callDurationSeconds,
      );
    } else {
      await CallOrchestrationService.instance.cancelCall();
    }
    if (mounted) {
      context.go(AppRoutes.buHome);
    }
  }

  void _toggleMute() {
    HapticFeedback.selectionClick();
    setState(() {
      _isMuted = !_isMuted;
    });
    CallOrchestrationService.instance.webrtcService.setMicrophoneMuted(_isMuted);
  }

  void _toggleSpeaker() {
    HapticFeedback.selectionClick();
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
    });
    CallOrchestrationService.instance.webrtcService.setSpeakerEnabled(_isSpeakerOn);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stateSub?.cancel();
    _localRenderer.srcObject = null;
    _localRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? VBDarkColors.primary : VBLightColors.primary;
    final successColor = isDark ? VBDarkColors.success : VBLightColors.success;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview — RTCVideoView is ALWAYS in the tree
          // (renders blank if srcObject not yet set, which is fine)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onScaleStart: (details) {
                _baseCallZoom = _callZoom;
              },
              onScaleUpdate: (details) async {
                final newZoom = (_baseCallZoom * details.scale).clamp(1.0, 5.0);
                if ((newZoom - _callZoom).abs() > 0.05) {
                  _callZoom = newZoom;
                  await CallOrchestrationService.instance.webrtcService.setZoomLevel(_callZoom);
                  HapticFeedback.selectionClick();
                }
              },
              child: RTCVideoView(
                _localRenderer,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                mirror: false,
              ),
            ),
          ),

          // Connection status + timer
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(VBSpacing.lg),
                child: Column(
                  children: [
                    // Status
                    Semantics(
                      liveRegion: true,
                      label: _isConnected
                          ? 'Connected to volunteer. Call duration ${_formatDuration(_callDurationSeconds)}'
                          : 'Connecting to volunteer...',
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: VBSpacing.md,
                          vertical: VBSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(VBRadius.full),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _isConnected
                                    ? successColor
                                    : primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: VBSpacing.sm),
                            Text(
                              _isConnected
                                  ? _lang.ui(UIKey.connected)
                                  : _lang.ui(UIKey.waitingForVolunteer),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (_isConnected) ...[
                              const SizedBox(width: VBSpacing.sm),
                              Text(
                                _formatDuration(_callDurationSeconds),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (!_isConnected) ...[
                      const SizedBox(height: VBSpacing.md),
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(VBSpacing.xl),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Mute toggle
                    Semantics(
                      button: true,
                      label: _isMuted ? 'Unmute microphone' : 'Mute microphone',
                      child: _CallControl(
                        icon: _isMuted
                            ? Icons.mic_off_rounded
                            : Icons.mic_rounded,
                        label: _isMuted ? _lang.ui(UIKey.unmute) : _lang.ui(UIKey.mute),
                        isActive: !_isMuted,
                        onTap: _toggleMute,
                      ),
                    ),
                    // End call
                    Semantics(
                      button: true,
                      label: 'End call',
                      child: GestureDetector(
                        onTap: _endCall,
                        child: Container(
                          width: VBTouchTarget.sosButton,
                          height: VBTouchTarget.sosButton,
                          decoration: BoxDecoration(
                            color: isDark
                                ? VBDarkColors.sos
                                : VBLightColors.sos,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.call_end_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                    // Speaker toggle
                    Semantics(
                      button: true,
                      label: 'Toggle speaker',
                      child: _CallControl(
                        icon: _isSpeakerOn
                            ? Icons.volume_up_rounded
                            : Icons.volume_down_rounded,
                        label: _isSpeakerOn ? _lang.ui(UIKey.speaker) : _lang.ui(UIKey.earpiece),
                        isActive: _isSpeakerOn,
                        onTap: _toggleSpeaker,
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

class _CallControl extends StatelessWidget {
  const _CallControl({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: VBTouchTarget.primaryAction,
            height: VBTouchTarget.primaryAction,
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white.withOpacity(0.15)
                  : Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isActive
                  ? Colors.white
                  : Colors.white.withOpacity(0.5),
              size: 28,
            ),
          ),
          const SizedBox(height: VBSpacing.sm),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
