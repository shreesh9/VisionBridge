/// VisionBridge — SOS Floating Action Button
///
/// Always visible on every BU screen. Fixed position, bottom-right.
/// 72dp minimum touch target. Unmistakable red, paired with icon + label.
/// Heavy haptic on tap. Never color-alone — always icon + text.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/dimensions.dart';
import '../../core/router/app_router.dart';

class SOSButton extends StatefulWidget {
  const SOSButton({super.key});

  @override
  State<SOSButton> createState() => _SOSButtonState();
}

class _SOSButtonState extends State<SOSButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sosColor = isDark ? VBDarkColors.sos : VBLightColors.sos;
    final sosGlowColor = isDark ? VBDarkColors.sosGlow : VBLightColors.sosGlow;
    final onSosColor = isDark ? VBDarkColors.onSOS : VBLightColors.onSOS;

    return Semantics(
      button: true,
      label: 'SOS Emergency Button. Double tap to activate emergency mode.',
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: sosGlowColor,
                  blurRadius: 16 + (_pulseAnimation.value * 8),
                  spreadRadius: 2 + (_pulseAnimation.value * 4),
                ),
              ],
            ),
            child: child,
          );
        },
        child: SizedBox(
          width: VBTouchTarget.sosButton,
          height: VBTouchTarget.sosButton,
          child: FloatingActionButton(
            heroTag: 'sos_button',
            backgroundColor: sosColor,
            foregroundColor: onSosColor,
            elevation: VBElevation.medium,
            shape: const CircleBorder(),
            onPressed: () {
              HapticFeedback.heavyImpact();
              context.push(AppRoutes.sos);
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.emergency_rounded,
                  size: 28,
                  color: onSosColor,
                ),
                const SizedBox(height: 2),
                Text(
                  'SOS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: onSosColor,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
