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
import '../../../../core/locale/supported_voice_languages.dart';

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

  static const List<_OnboardingSlide> _slidesMr = [
    _OnboardingSlide(
      icon: Icons.visibility_rounded,
      title: 'VisionBridge सोबत\nजग पाहा',
      description:
          'तुमचा AI-चालित दृश्य सहाय्यक जो हातमुक्त, आवाज-प्रथम पद्धतीने दिशा दाखवण्यास, मजकूर वाचण्यास आणि आसपास समजून घेण्यास मदत करतो.',
    ),
    _OnboardingSlide(
      icon: Icons.auto_awesome_rounded,
      title: 'AI ला माहिती आहे\nमदत कधी मागावी',
      description:
          'स्मार्ट ओळख तत्काळ निकाल देण्यासाठी तुमच्या फोनवर चालते. AI ला खात्री नसताना तो तुम्हाला एका खऱ्या स्वयंसेवकाशी जोडतो जो तुम्ही पाहता तसे पाहू शकतो.',
    ),
    _OnboardingSlide(
      icon: Icons.shield_rounded,
      title: 'तुमच्या सुरक्षेसाठी\nबनवलेले',
      description:
          'आपत्कालीन परिस्थितीसाठी वन-टॅप SOS. लाइव्ह स्थान सामायिकरण. दृश्य सहाय्यासाठी कॅमेरा आणि मायक्रोफोन प्रवेश आवश्यक आहे — नियंत्रण नेहमी तुमच्याकडे.',
    ),
  ];

  static const List<_OnboardingSlide> _slidesTa = [
    _OnboardingSlide(
      icon: Icons.visibility_rounded,
      title: 'VisionBridge மூலம்\nஉலகைக் காணுங்கள்',
      description:
          'கைமற்ற, குரல்-முதன்மை முறையில் வழிசெலுத்தவும், உரையைப் படிக்கவும், சுற்றுப்புறத்தைப் புரிந்துகொள்ளவும் உதவும் உங்கள் AI-இயங்கு காட்சி உதவியாளர்.',
    ),
    _OnboardingSlide(
      icon: Icons.auto_awesome_rounded,
      title: 'எப்போது உதவி\nகேட்க வேண்டும் என்று AI அறியும்',
      description:
          'உடனடி முடிவுகளுக்கு ஸ்மார்ட் கண்டறிதல் உங்கள் போனில் இயங்குகிறது. AI உறுதியாக இல்லாதபோது, நீங்கள் பார்ப்பதை பார்க்கக்கூடிய ஒரு உண்மையான தன்னார்வலருடன் இணைக்கிறது.',
    ),
    _OnboardingSlide(
      icon: Icons.shield_rounded,
      title: 'உங்கள் பாதுகாப்புக்காக\nஉருவாக்கப்பட்டது',
      description:
          'அவசரங்களுக்கு ஒரு-தட்டு SOS. நேரடி இருப்பிடப் பங்கீடு. காட்சி உதவிக்கு கேமரா மற்றும் மைக்கு அணுகல் தேவை — கட்டுப்பாடு எப்போதும் உங்களிடமே.',
    ),
  ];

  static const List<_OnboardingSlide> _slidesTe = [
    _OnboardingSlide(
      icon: Icons.visibility_rounded,
      title: 'VisionBridge తో\nప్రపంచాన్ని చూడండి',
      description:
          'చేతులు లేకుండా, వాయిస్-ప్రథమ పద్ధతిలో దారి చూపడం, టెక్స్ట్ చదవడం మరియు పరిసరాలను అర్థం చేసుకోవడంలో సహాయపడే మీ AI-ఆధారిత దృశ్య సహాయకుడు.',
    ),
    _OnboardingSlide(
      icon: Icons.auto_awesome_rounded,
      title: 'ఎప్పుడు సహాయం\nఅడగాలో AI తెలుసుకుంటుంది',
      description:
          'తక్షణ ఫలితాల కోసం స్మార్ట్ గుర్తింపు మీ ఫోన్‌లో నడుస్తుంది. AI ఖచ్చితంగా లేనప్పుడు, మీరు చూసేది చూడగలిగిన నిజమైన స్వచ్ఛంద సేవకుడితో కలుపుతుంది.',
    ),
    _OnboardingSlide(
      icon: Icons.shield_rounded,
      title: 'మీ భద్రత కోసం\nరూపొందించబడింది',
      description:
          'అత్యవసర పరిస్థితులకు వన్-ట్యాప్ SOS. ప్రత్యక్ష స్థాన భాగస్వామ్యం. దృశ్య సహాయానికి కెమెరా మరియు మైక్ యాక్సెస్ అవసరం — నియంత్రణ ఎప్పుడూ మీ దగ్గరే.',
    ),
  ];

  static const List<_OnboardingSlide> _slidesBn = [
    _OnboardingSlide(
      icon: Icons.visibility_rounded,
      title: 'VisionBridge দিয়ে\nপৃথিবী দেখুন',
      description:
          'হাতমুক্ত, ভয়েস-প্রথম উপায়ে পথ দেখানো, টেক্সট পড়া এবং আশেপাশে বোঝায় সাহায্য করে এমন আপনার AI-চালিত দৃশ্য সহায়ক।',
    ),
    _OnboardingSlide(
      icon: Icons.auto_awesome_rounded,
      title: 'কখন সাহায্য চাইতে\nহবে AI জানে',
      description:
          'তাৎক্ষণিক ফলাফলের জন্য স্মার্ট সনাক্তকরণ আপনার ফোনে চলে। AI নিশ্চিত না হলে এমন একজন সত্যিকারের স্বেচ্ছাসেবকের সাথে যুক্ত করে যিনি আপনি যা দেখছেন তা দেখতে পারেন।',
    ),
    _OnboardingSlide(
      icon: Icons.shield_rounded,
      title: 'আপনার নিরাপত্তার\nজন্য তৈরি',
      description:
          'জরুরি অবস্থার জন্য ওয়ান-ট্যাপ SOS। লাইভ লোকেশন শেয়ার। দৃশ্য সহায়তার জন্য ক্যামেরা এবং মাইক্রোফোন অ্যাক্সেস প্রয়োজন — নিয়ন্ত্রণ সবসময় আপনার হাতে।',
    ),
  ];

  static const List<_OnboardingSlide> _slidesKn = [
    _OnboardingSlide(
      icon: Icons.visibility_rounded,
      title: 'VisionBridge ಮೂಲಕ\nಜಗತ್ತನ್ನು ನೋಡಿ',
      description:
          'ಕೈಮುಕ್ತ, ಧ್ವನಿ-ಪ್ರಥಮ ರೀತಿಯಲ್ಲಿ ದಾರಿ ತೋರಿಸಲು, ಪಠ್ಯ ಓದಲು ಮತ್ತು ಸುತ್ತಮುತ್ತ ಅರ್ಥಮಾಡಿಕೊಳ್ಳಲು ಸಹಾಯ ಮಾಡುವ ನಿಮ್ಮ AI-ಚಾಲಿತ ದೃಶ್ಯ ಸಹಾಯಕ.',
    ),
    _OnboardingSlide(
      icon: Icons.auto_awesome_rounded,
      title: 'ಯಾವಾಗ ಸಹಾಯ\nಕೇಳಬೇಕೆಂದು AI ತಿಳಿದಿದೆ',
      description:
          'ತಕ್ಷಣ ಫಲಿತಾಂಶಗಳಿಗಾಗಿ ಸ್ಮಾರ್ಟ್ ಪತ್ತೆ ನಿಮ್ಮ ಫೋನ್‌ನಲ್ಲಿ ಚಲಿಸುತ್ತದೆ. AI ಖಚಿತವಾಗಿಲ್ಲದಿದ್ದಾಗ, ನೀವು ನೋಡುತ್ತಿರುವುದನ್ನು ನೋಡಬಲ್ಲ ನಿಜವಾದ ಸ್ವಯಂಸೇವಕರೊಂದಿಗೆ ಸಂಪರ್ಕಿಸುತ್ತದೆ.',
    ),
    _OnboardingSlide(
      icon: Icons.shield_rounded,
      title: 'ನಿಮ್ಮ ಸುರಕ್ಷತೆಗಾಗಿ\nನಿರ್ಮಿಸಲಾಗಿದೆ',
      description:
          'ತುರ್ತು ಪರಿಸ್ಥಿತಿಗಳಿಗೆ ಒನ್-ಟ್ಯಾಪ್ SOS. ನೇರ ಸ್ಥಳ ಹಂಚಿಕೆ. ದೃಶ್ಯ ಸಹಾಯಕ್ಕೆ ಕ್ಯಾಮೆರಾ ಮತ್ತು ಮೈಕ್ ಪ್ರವೇಶ ಅಗತ್ಯ — ನಿಯಂತ್ರಣ ಯಾವಾಗಲೂ ನಿಮ್ಮದೇ.',
    ),
  ];

  List<_OnboardingSlide> _slides(BuildContext context) {
    // ref.read (not watch): this helper is also called from callbacks like
    // _nextPage; build() already watches localeProvider for rebuilds.
    final code = ref.read(localeProvider).languageCode;
    return _slidesByLocale[code] ?? _slidesEn;
  }

  /// Full onboarding slide sets for every supported UI language.
  static final Map<String, List<_OnboardingSlide>> _slidesByLocale = {
    'hi': _slidesHi,
    'mr': _slidesMr,
    'ta': _slidesTa,
    'te': _slidesTe,
    'bn': _slidesBn,
    'kn': _slidesKn,
  };

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
    final lang = VBLanguages.byCode(ref.watch(localeProvider).languageCode);

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
                  label: lang.ui(UIKey.skipOnboarding),
                  child: TextButton(
                    onPressed: _completeOnboarding,
                    child: Text(
                      lang.ui(UIKey.skip),
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
                        '${lang.uiX(UIKey.onboardingStep, '${index + 1}')} ${lang.uiX(UIKey.onboardingStepOf, '${slides.length}')}. ${slide.title}. ${slide.description}',
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
                            ? lang.ui(UIKey.getStarted)
                            : lang.ui(UIKey.next),
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
