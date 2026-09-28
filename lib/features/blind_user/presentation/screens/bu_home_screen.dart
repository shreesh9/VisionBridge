/// VisionBridge — Blind User Home Screen
///
/// Spotify Liquify / Liquid-Lyrics Theme Aesthetics:
/// Dark solid slate cards (#181A22), luminous subtle borders (white 12%),
/// rounded corners (24px), and vibrant gradient accent badges.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/dimensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/constants.dart';
import '../../../../shared/widgets/sos_button.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/locale/locale_provider.dart';

class BUHomeScreen extends ConsumerStatefulWidget {
  const BUHomeScreen({super.key});

  @override
  ConsumerState<BUHomeScreen> createState() => _BUHomeScreenState();
}

class _BUHomeScreenState extends ConsumerState<BUHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(localeProvider);
    final localeCode = currentLocale.languageCode;
    final isHindi = localeCode == 'hi';

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F1016) : const Color(0xFFF4F5FB);
    final cardBgColor = isDark ? const Color(0xFF181A24) : Colors.white;
    final cardBorderColor = isDark
        ? Colors.white.withOpacity(0.12)
        : Colors.black.withOpacity(0.08);

    final textColor = isDark ? Colors.white : const Color(0xFF121419);
    final subtextColor =
        isDark ? const Color(0xFFA0A3B5) : const Color(0xFF6B6D7B);
    final primaryColor = isDark ? const Color(0xFF6C5CE7) : const Color(0xFF5A4AD1);
    final secondaryColor =
        isDark ? const Color(0xFF00CEC9) : const Color(0xFF00B894);

    final currentUser = FirebaseAuth.instance.currentUser;
    final displayName = currentUser?.displayName ?? (isHindi ? 'उपयोगकर्ता' : 'User');

    return Scaffold(
      backgroundColor: bgColor,
      floatingActionButton: const SOSButton(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: VBSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: VBSpacing.lg),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isHindi ? 'नमस्ते,' : 'Hello,',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: subtextColor),
                        ),
                        const SizedBox(height: VBSpacing.xs),
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .displayMedium
                              ?.copyWith(
                                color: textColor,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: VBSpacing.md),
                  Semantics(
                    button: true,
                    label: isHindi ? 'सेटिंग्स खोलें' : 'Open settings',
                    child: Container(
                      decoration: BoxDecoration(
                        color: cardBgColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: cardBorderColor, width: 1.2),
                      ),
                      child: IconButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          context.push(AppRoutes.buSettings);
                        },
                        icon: Icon(Icons.settings_outlined, color: subtextColor),
                        iconSize: 24,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: VBSpacing.xxl),

              // === PRIMARY ACTION: AI Visual Assist (Spotify Liquify Main Card) ===
              Expanded(
                flex: 3,
                child: Semantics(
                  button: true,
                  label: isHindi
                      ? 'AI दृश्य सहायता। अपने आस-पास का दृश्य AI द्वारा जानने के लिए टैप करें।'
                      : 'AI Visual Assist. Tap to open camera and get AI-powered scene description.',
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      context.push(AppRoutes.aiAssist);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(VBSpacing.xl),
                      decoration: BoxDecoration(
                        color: cardBgColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: cardBorderColor, width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.35 : 0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Glowing Vibrant Icon Badge
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  primaryColor,
                                  const Color(0xFFA29BFE),
                                ],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 42,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: VBSpacing.lg),
                          Text(
                            isHindi ? 'AI दृश्य सहायता' : 'AI Visual Assist',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: VBSpacing.xs),
                          Text(
                            isHindi ? 'अपने आस-पास देखने के लिए टैप करें' : 'Tap to see what\'s around you',
                            style: TextStyle(
                              color: subtextColor,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: VBSpacing.md),

              // === Quick Actions Row ===
              Expanded(
                flex: 1,
                child: Row(
                  children: [
                    // Call History
                    Expanded(
                      child: _LiquifyActionCard(
                        icon: Icons.history_rounded,
                        label: isHindi ? 'इतिहास' : 'History',
                        accentColor: secondaryColor,
                        bgColor: cardBgColor,
                        borderColor: cardBorderColor,
                        textColor: textColor,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          context.push(AppRoutes.buCallHistory);
                        },
                      ),
                    ),
                    const SizedBox(width: VBSpacing.sm),
                    // Read Text (OCR)
                    Expanded(
                      child: _LiquifyActionCard(
                        icon: Icons.document_scanner_rounded,
                        label: isHindi ? 'टेक्स्ट पढ़ें' : 'Read Text',
                        accentColor: primaryColor,
                        bgColor: cardBgColor,
                        borderColor: cardBorderColor,
                        textColor: textColor,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          context.push(AppRoutes.readText);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: VBSpacing.sm),
              Center(
                child: Text(
                  'VisionBridge v${AppConstants.appVersion}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: subtextColor.withOpacity(0.5)),
                ),
              ),
              const SizedBox(height: VBSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiquifyActionCard extends StatelessWidget {
  const _LiquifyActionCard({
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color accentColor;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: accentColor),
              ),
              const SizedBox(height: VBSpacing.xs),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
