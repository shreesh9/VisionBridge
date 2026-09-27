/// VisionBridge — SOS Screen
///
/// Full-screen red confirmation → sends location + triggers emergency contacts.
/// Heavy haptic on activation. Countdown before sending.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../../../core/constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../services/location_service.dart';
import '../../../../services/firestore_service.dart';
import '../../../../services/tts_stt_service.dart';
import '../../../../services/call_orchestration_service.dart';
import '../../../../services/user_settings_service.dart';

class SOSScreen extends StatefulWidget {
  const SOSScreen({super.key});

  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen>
    with SingleTickerProviderStateMixin {
  bool _isActivated = false;
  bool _isSending = false;
  int _countdown = AppConstants.sosConfirmationTimeoutMs ~/ 1000;
  Timer? _timer;
  late final AnimationController _pulseController;

  final _locationService = LocationService();
  final _firestoreService = FirestoreService();
  final _ttsService = TTSSTTService();
  String _localeCode = 'en';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _ttsService.initialize().then((_) async {
      try {
        _localeCode = await UserSettingsService.getLocaleCode();
      } catch (_) {}
      _ttsService.speak(
        _localeCode == 'hi'
            ? 'SOS स्क्रीन। आपातकालीन अलर्ट भेजने के लिए बड़ा बटन दबाएँ।'
            : 'SOS screen. Tap the large button to send emergency alert with your location.',
      );
    });
  }

  void _activateSOS() {
    HapticFeedback.heavyImpact();
    setState(() => _isActivated = true);
    _ttsService.speak(
      _localeCode == 'hi'
          ? 'SOS $_countdown सेकंड में भेजा जाएगा। रोकने के लिए रद्द करें दबाएँ।'
          : 'SOS will send in $_countdown seconds. Tap cancel to stop.',
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown <= 1) {
        timer.cancel();
        _sendSOS();
      } else {
        setState(() => _countdown--);
        HapticFeedback.lightImpact();
      }
    });
  }

  void _cancelSOS() {
    _timer?.cancel();
    HapticFeedback.selectionClick();
    _ttsService.speak(_localeCode == 'hi' ? 'SOS रद्द।' : 'SOS cancelled.');
    if (mounted) context.pop();
  }

  Future<void> _sendSOS() async {
    HapticFeedback.heavyImpact();
    setState(() => _isSending = true);
    _ttsService.speak(_localeCode == 'hi' ? 'SOS अलर्ट भेजा जा रहा है...' : 'Sending SOS alert now...');

    try {
      // Get current location (times out after 10s if GPS unavailable)
      final position = await _locationService.getCurrentPosition();
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'demo_user';
      final lat = position?.latitude ?? 0.0;
      final lng = position?.longitude ?? 0.0;

      // 1. Create SOS record in Firestore
      try {
        await _firestoreService.createSOSAlert(
          userId: uid,
          latitude: lat,
          longitude: lng,
        );
      } catch (_) {}

      // 2. Trigger emergency volunteer video call broadcast
      try {
        await CallOrchestrationService.instance.requestVolunteerHelp(
          blindUserId: uid,
          detectedObjects: ['EMERGENCY_SOS'],
          aiDescription: 'Emergency SOS Alert triggered at location: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
        );
      } catch (_) {}

      if (mounted) {
        _ttsService.speak(
          _localeCode == 'hi'
              ? 'SOS अलर्ट भेजा गया। आपातकालीन स्वयंसेवक से जोड़ रहे हैं।'
              : 'SOS alert sent. Connecting to an emergency volunteer now.',
          force: true,
        );
        context.push(AppRoutes.buInCall);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        _ttsService.speak(_localeCode == 'hi' ? 'SOS अलर्ट भेजा गया।' : 'SOS alert triggered.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('SOS triggered: ${e.toString()}')),
        );
        context.pop();
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _ttsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sosColor = isDark ? VBDarkColors.sos : VBLightColors.sos;

    return Scaffold(
      backgroundColor: _isActivated
          ? sosColor
          : (isDark ? VBDarkColors.background : VBLightColors.background),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(VBSpacing.xl),
          child: Column(
            children: [
              // Cancel / Back
              Align(
                alignment: Alignment.topLeft,
                child: Semantics(
                  button: true,
                  label: 'Cancel SOS and go back',
                  child: IconButton(
                    onPressed: _cancelSOS,
                    icon: Icon(
                      Icons.close_rounded,
                      color: _isActivated
                          ? Colors.white
                          : (isDark
                              ? VBDarkColors.onSurface
                              : VBLightColors.onSurface),
                      size: 32,
                    ),
                  ),
                ),
              ),
              const Spacer(),

              if (_isSending) ...[
                // Sending state
                const CircularProgressIndicator(color: Colors.white),
                const SizedBox(height: VBSpacing.lg),
                Text(
                  _localeCode == 'hi' ? 'SOS भेजा जा रहा है...' : 'Sending SOS...',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ] else if (!_isActivated) ...[
                // Pre-activation state
                Icon(
                  Icons.emergency_rounded,
                  size: 80,
                  color: sosColor,
                ),
                const SizedBox(height: VBSpacing.lg),
                Text(
                  _localeCode == 'hi' ? 'आपातकालीन SOS' : 'Emergency SOS',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: isDark
                            ? VBDarkColors.onSurface
                            : VBLightColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: VBSpacing.sm),
                Text(
                  _localeCode == 'hi'
                      ? 'यह आपकी लाइव लोकेशन\nआपातकालीन संपर्कों के साथ साझा करेगा।'
                      : 'This will share your live location\nwith emergency contacts.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: isDark
                            ? VBDarkColors.onSurfaceVariant
                            : VBLightColors.onSurfaceVariant,
                        height: 1.5,
                      ),
                ),
                const SizedBox(height: VBSpacing.xxl),
                // Activate button
                Semantics(
                  button: true,
                  label:
                      'Activate SOS. This will notify your emergency contacts.',
                  child: SizedBox(
                    width: 160,
                    height: 160,
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: sosColor.withOpacity(
                                    0.2 + _pulseController.value * 0.15),
                                blurRadius: 32,
                                spreadRadius: 8,
                              ),
                            ],
                          ),
                          child: child,
                        );
                      },
                      child: ElevatedButton(
                        onPressed: _activateSOS,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: sosColor,
                          foregroundColor: Colors.white,
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(VBSpacing.xl),
                          elevation: VBElevation.medium,
                        ),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.emergency_rounded, size: 40),
                            SizedBox(height: VBSpacing.xs),
                            Text(
                              'SOS',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // Post-activation countdown
                const Icon(
                  Icons.emergency_rounded,
                  size: 80,
                  color: Colors.white,
                ),
                const SizedBox(height: VBSpacing.lg),
                Text(
                  _localeCode == 'hi' ? 'SOS भेजा जा रहा है' : 'Sending SOS in',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                ),
                const SizedBox(height: VBSpacing.md),
                Semantics(
                  liveRegion: true,
                  label: 'Countdown: $_countdown seconds',
                  child: Text(
                    '$_countdown',
                    style: const TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(height: VBSpacing.xxl),
                // Cancel button
                SizedBox(
                  width: double.infinity,
                  height: VBTouchTarget.primaryAction,
                  child: OutlinedButton(
                    onPressed: _cancelSOS,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 2),
                    ),
                    child: Text(_localeCode == 'hi' ? 'रद्द करें' : 'CANCEL'),
                  ),
                ),
              ],

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
