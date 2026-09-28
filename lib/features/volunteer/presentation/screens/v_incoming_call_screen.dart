/// VisionBridge — Volunteer Incoming Call Screen
///
/// Native-like incoming call UI. Accept / Decline (large buttons).
/// Ringtone + vibration pattern.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../services/call_orchestration_service.dart';
import '../../../../services/tts_stt_service.dart';
import '../../../../services/user_settings_service.dart';

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class VIncomingCallScreen extends StatefulWidget {

  const VIncomingCallScreen({
    super.key,
    this.callRequestId,
    this.signalingRoomId,
  });
  final String? callRequestId;
  final String? signalingRoomId;

  @override
  State<VIncomingCallScreen> createState() => _VIncomingCallScreenState();
}

class _VIncomingCallScreenState extends State<VIncomingCallScreen>
    with TickerProviderStateMixin {
  late final AnimationController _ringController;
  late final AnimationController _pulseController;
  final _ttsService = TTSSTTService();
  bool _isConnecting = false;
  bool _isClaimedByOther = false;
  StreamSubscription? _docSub;
  String _localeCode = 'en';

  @override
  void initState() {
    super.initState();
    // Ring animation (icon wiggle)
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    // Pulse animation for accept button
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _ttsService.initialize().then((_) async {
      try {
        _localeCode = await UserSettingsService.getLocaleCode();
        await _ttsService.setLocale(_localeCode);
      } catch (_) {}
      _startVoiceRingLoop();
    });

    // Continuous haptic pulse
    _startHapticPulse();

    // Listen for call claims by other volunteers
    _listenCallStatus();
  }

  void _listenCallStatus() {
    final reqId = widget.callRequestId ?? CallOrchestrationService.instance.currentCallRequestId;
    if (reqId == null) return;

    final myUid = FirebaseAuth.instance.currentUser?.uid;

    _docSub = FirebaseFirestore.instance
        .collection('call_requests')
        .doc(reqId)
        .snapshots()
        .listen((snap) {
      if (!mounted || _isConnecting) return;
      final data = snap.data();
      if (data == null) return;

      final status = data['status'] as String?;
      final volunteerId = data['volunteerId'] as String?;

      if (status == 'cancelled') {
        if (!_isClaimedByOther) {
          setState(() {
            _isClaimedByOther = true;
          });
          HapticFeedback.mediumImpact();
          _ttsService.speak(
            _localeCode == 'hi' ? 'मदद अनुरोध उपयोगकर्ता द्वारा रद्द कर दिया गया।' : 'The help request was cancelled by the user.',
            force: true,
          );
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) {
              context.pop();
            }
          });
        }
      } else if ((status == 'claimed' || status == 'active' || status == 'completed') &&
          volunteerId != null &&
          volunteerId != myUid) {
        if (!_isClaimedByOther) {
          setState(() {
            _isClaimedByOther = true;
          });
          HapticFeedback.mediumImpact();
          _ttsService.speak(
            _localeCode == 'hi' ? 'यह कॉल किसी अन्य स्वयंसेवक ने उठा लिया।' : 'This call was picked up by another volunteer.',
            force: true,
          );
          Future.delayed(const Duration(milliseconds: 2000), () {
            if (mounted) {
              context.pop();
            }
          });
        }
      }
    });
  }

  void _startVoiceRingLoop() {
    Future.doWhile(() async {
      if (!mounted || _isConnecting) return false;
      await _ttsService.speak(
        _localeCode == 'hi'
            ? 'एक दृष्टिबाधित उपयोगकर्ता से मदद का अनुरोध आया है।'
            : 'Incoming help request from a visually impaired user.',
        force: true,
      );
      await Future.delayed(const Duration(milliseconds: 3500));
      return mounted && !_isConnecting;
    });
  }

  void _startHapticPulse() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 1000));
      if (mounted && !_isConnecting) {
        HapticFeedback.mediumImpact();
        return true;
      }
      return false;
    });
  }

  Future<void> _acceptCall() async {
    if (_isConnecting) return;

    HapticFeedback.heavyImpact();
    setState(() => _isConnecting = true);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    final reqId = widget.callRequestId ?? CallOrchestrationService.instance.currentCallRequestId;
    final sigId = widget.signalingRoomId ?? CallOrchestrationService.instance.currentSignalingRoomId;

    if (uid == null || reqId == null || sigId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Call request expired or invalid.')),
        );
        context.pop();
      }
      return;
    }

    try {
      final success = await CallOrchestrationService.instance.acceptCall(
        callRequestId: reqId,
        volunteerId: uid,
        signalingRoomId: sigId,
      );

      if (success) {
        if (mounted) {
          context.go(AppRoutes.vInCall);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Call was already claimed by another volunteer or cancelled.')),
          );
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isConnecting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept call: $e')),
        );
      }
    }
  }

  void _declineCall() {
    HapticFeedback.lightImpact();
    context.pop();
  }

  @override
  void dispose() {
    _docSub?.cancel();
    _ringController.dispose();
    _pulseController.dispose();
    _ttsService.stopSpeaking();
    _ttsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? VBDarkColors.background : const Color(0xFF0D0F14);
    final primaryColor = isDark ? VBDarkColors.primary : VBLightColors.primary;
    final successColor = isDark ? VBDarkColors.success : VBLightColors.success;
    final sosColor = isDark ? VBDarkColors.sos : VBLightColors.sos;
    final bool isHindi = _localeCode == 'hi';

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(VBSpacing.xl),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Caller info
              Semantics(
                liveRegion: true,
                label: _isClaimedByOther
                    ? 'This call was answered by another volunteer.'
                    : 'Incoming help request from a visually impaired user.',
                child: Column(
                  children: [
                    // Animated ring icon
                    AnimatedBuilder(
                      animation: _ringController,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: (_ringController.value - 0.5) * 0.3,
                          child: child,
                        );
                      },
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: _isClaimedByOther
                              ? Colors.orange.withOpacity(0.15)
                              : primaryColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isClaimedByOther
                              ? Icons.check_circle_outline_rounded
                              : Icons.phone_in_talk_rounded,
                          size: 48,
                          color: _isClaimedByOther ? Colors.orange : primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: VBSpacing.xl),
                    Text(
                      _isClaimedByOther
                          ? (isHindi ? 'कॉल उठा ली गई' : 'Call Answered')
                          : (isHindi ? 'किसी को आपकी\nमदद चाहिए' : 'Someone needs\nyour help'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: VBSpacing.md),
                    Text(
                      _isClaimedByOther
                          ? (isHindi ? 'यह अनुरोध किसी अन्य स्वयंसेवक ने उठा लिया।' : 'This request was picked up by another volunteer.')
                          : (_isConnecting
                              ? (isHindi ? 'लाइव कॉल कनेक्ट हो रही है...' : 'Connecting live call...')
                              : (isHindi ? 'एक दृष्टिबाधित उपयोगकर्ता लाइव\nविज़ुअल सहायता का अनुरोध कर रहा है' : 'A visually impaired user is requesting\nlive visual assistance')),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 3),

              if (_isConnecting)
                const CircularProgressIndicator(color: Colors.white)
              else
                // Accept / Decline buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Decline
                    Semantics(
                      button: true,
                      label: 'Decline the help request',
                      child: GestureDetector(
                        onTap: _declineCall,
                        child: Column(
                          children: [
                            Container(
                              width: VBTouchTarget.sosButton,
                              height: VBTouchTarget.sosButton,
                              decoration: BoxDecoration(
                                color: sosColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.call_end_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: VBSpacing.sm),
                            Text(
                              isHindi ? 'अस्वीकार करें' : 'Decline',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Accept
                    Semantics(
                      button: true,
                      label: 'Accept the help request and start video call',
                      child: GestureDetector(
                        onTap: _acceptCall,
                        child: Column(
                          children: [
                            AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                return Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: successColor.withOpacity(
                                            0.2 + _pulseController.value * 0.2),
                                        blurRadius: 24,
                                        spreadRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: child,
                                );
                              },
                              child: Container(
                                width: VBTouchTarget.sosButton,
                                height: VBTouchTarget.sosButton,
                                decoration: BoxDecoration(
                                  color: successColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.call_rounded,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ),
                            const SizedBox(height: VBSpacing.sm),
                            Text(
                              isHindi ? 'स्वीकार करें' : 'Accept',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: VBSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
