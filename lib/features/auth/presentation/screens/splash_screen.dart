import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../services/firestore_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();

    // Navigate after splash animation — check auth state
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) _navigateBasedOnAuth();
    });
  }

  Future<void> _navigateBasedOnAuth() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      // Not logged in → go to onboarding/login
      if (mounted) context.go(AppRoutes.onboarding);
      return;
    }

    // Logged in → check Firestore for role
    try {
      final firestoreService = FirestoreService();
      final vbUser = await firestoreService.getUser(currentUser.uid);

      if (!mounted) return;

      if (vbUser == null) {
        // Auth but no Firestore doc -> send to role selection
        context.go(AppRoutes.selectRole);
        return;
      }

      // Route based on role
      if (vbUser.role == UserRole.volunteer) {
        context.go(AppRoutes.vHome);
      } else {
        context.go(AppRoutes.buHome);
      }
    } catch (_) {
      // On Firestore error/offline, fallback to role selection screen for logged-in user
      if (mounted) context.go(AppRoutes.selectRole);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? VBDarkColors.background : VBLightColors.background,
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // App logo — switches variant based on theme
                  ClipRRect(
                    borderRadius: BorderRadius.circular(VBRadius.xl),
                    child: Image.asset(
                      isDark
                          ? 'assets/images/logo_dark.png'
                          : 'assets/images/logo_light.png',
                      width: 120,
                      height: 120,
                      semanticLabel: 'VisionBridge logo',
                    ),
                  ),
                  const SizedBox(height: VBSpacing.lg),
                  Text(
                    'VisionBridge',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? VBDarkColors.onSurface
                              : VBLightColors.onSurface,
                        ),
                  ),
                  const SizedBox(height: VBSpacing.sm),
                  Text(
                    'Your AI-powered visual assistant',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: isDark
                              ? VBDarkColors.onSurfaceVariant
                              : VBLightColors.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
