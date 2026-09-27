/// VisionBridge — Liquid Ambient Background (Spotify Liquid-Lyrics Aesthetic)
///
/// Multi-layer mesh blurred liquid gradient ambient background with ambient glow spheres.
/// Delivers zero-lag 60fps glassmorphic visual aesthetics.
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

class LiquidBackground extends StatefulWidget {
  const LiquidBackground({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<LiquidBackground> createState() => _LiquidBackgroundState();
}

class _LiquidBackgroundState extends State<LiquidBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? VBDarkColors.background : VBLightColors.background;

    return Stack(
      children: [
        // Base dark background
        Container(color: bgColor),

        // Animated Ambient Liquid Blob 1 (Top Left)
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final offset = Offset(
              -50 + (_controller.value * 40),
              -50 + (_controller.value * 60),
            );
            return Positioned(
              left: offset.dx,
              top: offset.dy,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF6C5CE7).withOpacity(isDark ? 0.35 : 0.15),
                      const Color(0xFF6C5CE7).withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        // Animated Ambient Liquid Blob 2 (Bottom Right)
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final offset = Offset(
              -40 + ((1.0 - _controller.value) * 50),
              -40 + ((1.0 - _controller.value) * 70),
            );
            return Positioned(
              right: offset.dx,
              bottom: offset.dy,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF00CEC9).withOpacity(isDark ? 0.25 : 0.12),
                      const Color(0xFF00CEC9).withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        // Glass Backdrop Blur Pass
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),

        // Main App Content
        widget.child,
      ],
    );
  }
}
