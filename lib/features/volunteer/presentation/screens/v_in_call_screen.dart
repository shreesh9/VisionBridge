/// VisionBridge — Volunteer In-Call Screen (WebRTC)
///
/// Receives BU's rear camera video feed via WebRTC. Two-way audio.
/// Shows video feed, audio controls, call timer, end call.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../services/call_orchestration_service.dart';
import '../../../../services/webrtc_service.dart';
import '../../../../services/user_settings_service.dart';

class VInCallScreen extends StatefulWidget {
  const VInCallScreen({super.key});

  @override
  State<VInCallScreen> createState() => _VInCallScreenState();
}

class _VInCallScreenState extends State<VInCallScreen> {
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  bool _isMuted = false;
  bool _isSpeakerOn = true;
  bool _isConnected = false;
  bool _hasBeenConnected = false;
  int _callDurationSeconds = 0;
  StreamSubscription<WebRTCConnectionState>? _stateSub;
  StreamSubscription<MediaStream>? _remoteStreamSub;
  Timer? _timer;
  String _localeCode = 'en';

  static const MethodChannel _privacyChannel = MethodChannel('com.visionbridge.app/privacy');

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
    _enablePrivacyProtection();
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

    // When remote stream arrives (BU's video), attach it to renderer
    _remoteStreamSub = webrtcService.onRemoteStream.listen((stream) {
      if (!mounted) return;
      debugPrint('[VInCall] Remote stream: '
          'video=${stream.getVideoTracks().length}, '
          'audio=${stream.getAudioTracks().length}');
      _remoteRenderer.srcObject = stream;
      setState(() {}); // Force rebuild
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
    await _remoteRenderer.initialize();
    if (!mounted) return;

    // Step 2: Rebuild so RTCVideoView is in the tree
    setState(() {});

    // Step 3: Check if remote stream already arrived before we initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final existingStream =
          CallOrchestrationService.instance.webrtcService.remoteStream;
      if (existingStream != null) {
        _remoteRenderer.srcObject = existingStream;
        debugPrint('[VInCall] ✅ Attached existing remote stream');
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
    _remoteStreamSub?.cancel();
    HapticFeedback.heavyImpact();
    await CallOrchestrationService.instance.endCall(
      durationSeconds: _callDurationSeconds,
    );
    if (mounted) {
      context.go(AppRoutes.vHome);
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

  Future<void> _enablePrivacyProtection() async {
    try {
      await _privacyChannel.invokeMethod('enableSecure');
      debugPrint('[VInCall] 🔒 FLAG_SECURE privacy protection enabled');
    } catch (e) {
      debugPrint('[VInCall] FLAG_SECURE error: $e');
    }
  }

  Future<void> _disablePrivacyProtection() async {
    try {
      await _privacyChannel.invokeMethod('disableSecure');
      debugPrint('[VInCall] 🔓 FLAG_SECURE privacy protection cleared');
    } catch (_) {}
  }

  @override
  void dispose() {
    _disablePrivacyProtection();
    _timer?.cancel();
    _stateSub?.cancel();
    _remoteStreamSub?.cancel();
    _remoteRenderer.srcObject = null;
    _remoteRenderer.dispose();
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
          // Remote video — ALWAYS in tree, renders blank until srcObject set
          Positioned.fill(
            child: RTCVideoView(
              _remoteRenderer,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),
          ),

          // Top bar — status + timer
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(VBSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
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
                              color: _isConnected ? successColor : primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: VBSpacing.sm),
                          Text(
                            _isConnected
                                ? (_localeCode == 'hi'
                                    ? 'सहायता में · ${_formatDuration(_callDurationSeconds)}'
                                    : 'Assisting · ${_formatDuration(_callDurationSeconds)}')
                                : (_localeCode == 'hi' ? 'लाइव वीडियो कनेक्ट हो रहा है...' : 'Connecting live video...'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontFeatures: [FontFeature.tabularFigures()],
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

          // Guidance hint
          if (_isConnected)
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              left: VBSpacing.lg,
              right: VBSpacing.lg,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: VBSpacing.md,
                  vertical: VBSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(VBRadius.sm),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: Colors.white, size: 18),
                    SizedBox(width: VBSpacing.sm),
                    Expanded(
                      child: Text(
                        _localeCode == 'hi'
                            ? 'आप जो देख रहे हैं उसे स्पष्ट बताएं — उपयोगकर्ता आपको सुन सकता है।'
                            : 'Describe what you see clearly — the user can hear you.',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ],
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
                    // Mute
                    _ControlButton(
                      icon: _isMuted
                          ? Icons.mic_off_rounded
                          : Icons.mic_rounded,
                      label: _isMuted ? (_localeCode == 'hi' ? 'अनम्यूट' : 'Unmute') : (_localeCode == 'hi' ? 'म्यूट' : 'Mute'),
                      isActive: !_isMuted,
                      onTap: _toggleMute,
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
                    // Speaker
                    _ControlButton(
                      icon: _isSpeakerOn
                          ? Icons.volume_up_rounded
                          : Icons.volume_down_rounded,
                      label: _isSpeakerOn ? (_localeCode == 'hi' ? 'स्पीकर' : 'Speaker') : (_localeCode == 'hi' ? 'ईयरपीस' : 'Earpiece'),
                      isActive: _isSpeakerOn,
                      onTap: _toggleSpeaker,
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

class _ControlButton extends StatelessWidget {
  const _ControlButton({
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
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
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
      ),
    );
  }
}
