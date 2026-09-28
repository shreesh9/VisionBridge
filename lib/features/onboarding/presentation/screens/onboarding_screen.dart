/// VisionBridge — Onboarding Screen
///
/// 3 slides explaining: (1) what VisionBridge does, (2) AI + volunteer model,
/// (3) permissions needed. First-launch only.
/// TTS reads each slide aloud, STT accepts "next"/"skip".
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/locale/locale_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<_OnboardingSlide> _slidesEn = [
    _OnboardingSlide(
      icon: Icons.visibility_rounded,
      title: 'See the world\nthrough VisionBridge',
      description:
          'Your AI-powered visual assistant that helps you navigate, read text, and understand your surroundings — hands-free, voice-first.',
    ),
    _OnboardingSlide(
      icon: Icons.auto_awesome_rounded,
      title: 'AI that knows\nwhen to ask for help',
      description:
          'Smart detection runs on your phone for instant results. When AI isn\'t sure, it connects you with a real volunteer who can see what you see.',
    ),
    _OnboardingSlide(
      icon: Icons.shield_rounded,
      title: 'Built for\nyour safety',
      description:
          'One-tap SOS for emergencies. Live location sharing. Camera and microphone access are needed for visual assistance — you\'re always in control.',
    ),
  ];

  static const List<_OnboardingSlide> _slidesHi = [
    _OnboardingSlide(
      icon: Icons.visibility_rounded,
      title: 'VisionBridge के साथ\nदुनिया देखें',
      description:
          'आपका AI-संचालित दृश्य सहायक जो आपको हाथ-मुक्त, आवाज़-प्रथम तरीके से रास्ता दिखाने, टेक्स्ट पढ़ने और अपने आस-पास को समझने में मदद करता है।',
    ),
    _OnboardingSlide(
      icon: Icons.auto_awesome_rounded,
      title: 'AI जानता है\nमदद कब मांगनी है',
      description:
          'स्मार्ट पहचान तुरंत नतीजे देने के लिए आपके फ़ोन पर चलती है। जब AI को यकीन नहीं होता, तो यह आपको एक असली स्वयंसेवक से जोड़ता है जो आपकी तरह देख सकता है।',
    ),
    _OnboardingSlide(
      icon: Icons.shield_rounded,
      title: 'आपकी सुरक्षा के\nलिए बनाया गया',
      description:
          'आपातकाल के लिए वन-टैप SOS। लाइव लोकेशन साझा करना। दृश्य सहायता के लिए कैमरा और माइक्रोफ़ोन एक्सेस आवश्यक है — नियंत्रण हमेशा आपके पास रहता है।',
    ),
  ];

  List<_OnboardingSlide> _slides(BuildContext context) {
    // ref.read (not watch): this helper is also called from callbacks like
    // _nextPage; build() already watches localeProvider for rebuilds.
    final isHindi = ref.read(localeProvider).languageCode == 'hi';
    return isHindi ? _slidesHi : _slidesEn;
  }

  void _nextPage() {
    if (_currentPage < _slides(context).length - 1) {
      HapticFeedback.selectionClick();
      _pageController.nextPage(
        duration: VBDuration.pageTransition,
        curve: VBCurves.standard,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() {
    HapticFeedback.mediumImpact();
    // TODO: Persist onboarding completion in SharedPreferences
    context.go(AppRoutes.login);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? VBDarkColors.primary : VBLightColors.primary;
    final bgColor = isDark ? VBDarkColors.background : VBLightColors.background;
    final textColor = isDark ? VBDarkColors.onSurface : VBLightColors.onSurface;
    final subtextColor =
        isDark ? VBDarkColors.onSurfaceVariant : VBLightColors.onSurfaceVariant;
    final dotInactive = isDark ? VBDarkColors.outline : VBLightColors.outline;
    final slides = _slides(context);
    final isHindi = ref.watch(localeProvider).languageCode == 'hi';

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(VBSpacing.md),
                child: Semantics(
                  button: true,
                  label: isHindi ? 'ऑनबोर्डिंग छोड़ें' : 'Skip onboarding',
                  child: TextButton(
                    onPressed: _completeOnboarding,
                    child: Text(
                      isHindi ? 'छोड़ें' : 'Skip',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: subtextColor,
                          ),
                    ),
                  ),
                ),
              ),
            ),

            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: slides.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final slide = slides[index];
                  return Semantics(
                    label:
                        '${isHindi ? "ऑनबोर्डिंग चरण ${index + 1} / ${slides.length}" : "Onboarding step ${index + 1} of ${slides.length}"}. ${slide.title}. ${slide.description}',
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: VBSpacing.xl),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Icon or Logo
                          if (index == 0)
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
                            )
                          else
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                slide.icon,
                                size: 56,
                                color: primaryColor,
                              ),
                            ),
                          const SizedBox(height: VBSpacing.xxl),
                          // Title
                          Text(
                            slide.title,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .displayMedium
                                ?.copyWith(
                                  color: textColor,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: VBSpacing.md),
                          // Description
                          Text(
                            slide.description,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                  color: subtextColor,
                                  height: 1.6,
                                ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Bottom section: dots + button
            Padding(
              padding: const EdgeInsets.fromLTRB(
                VBSpacing.xl,
                VBSpacing.md,
                VBSpacing.xl,
                VBSpacing.xl,
              ),
              child: Column(
                children: [
                  // Page dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(slides.length, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: VBDuration.normal,
                        curve: VBCurves.standard,
                        margin: const EdgeInsets.symmetric(
                          horizontal: VBSpacing.xs,
                        ),
                        width: isActive ? 32 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive ? primaryColor : dotInactive,
                          borderRadius:
                              BorderRadius.circular(VBRadius.full),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: VBSpacing.xl),
                  // Action button
                  SizedBox(
                    width: double.infinity,
                    height: VBTouchTarget.primaryAction,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      child: Text(
                        _currentPage == slides.length - 1
                            ? (isHindi ? 'शुरू करें' : 'Get Started')
                            : (isHindi ? 'अगला' : 'Next'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}
