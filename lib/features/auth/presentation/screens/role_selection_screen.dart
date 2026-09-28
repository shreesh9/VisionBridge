/// VisionBridge — Role Selection Screen
///
/// Shown to new Google/Phone users on first sign-in.
/// Users choose: Visually Impaired vs Sighted Volunteer,
/// and provide their display name.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/locale/locale_provider.dart';
import '../../../../core/locale/supported_voice_languages.dart';
import '../../../../services/firestore_service.dart';
import '../../../../services/tts_stt_service.dart';
import '../../../../services/user_settings_service.dart';

class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() =>
      _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  UserRole? _selectedRole;
  bool _isLoading = false;

  final _firestoreService = FirestoreService();
  final _ttsService = TTSSTTService();

  @override
  void initState() {
    super.initState();
    // Fill in Google display name if available
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser?.displayName != null && currentUser!.displayName!.isNotEmpty) {
      _nameController.text = currentUser.displayName!;
    }
    _ttsService.initialize().then((_) async {
      String code = 'en';
      try {
        code = await UserSettingsService.getLocaleCode();
      } catch (_) {}
      await _ttsService.setLocale(code);
      // Narration strings come from the language registry so the prompt is
      // spoken in the selected language (never English with an Indic voice).
      _ttsService.speak(VBLanguages.byCode(code).voice(VoiceKey.profileSetupPrompt));
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ttsService.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_selectedRole == null) {
      final lang = VBLanguages.byCode(ref.read(localeProvider).languageCode);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang == VBLanguages.hi ? 'कृपया अपनी भूमिका चुनें' : 'Please select your role')),
      );
      _ttsService.speak(lang.voice(VoiceKey.pleaseSelectRole));
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication session expired. Please log in again.')),
      );
      context.go(AppRoutes.login);
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final name = _nameController.text.trim();

      // 1. Update display name in Firebase Auth
      await user.updateDisplayName(name);
      await user.reload();

      // 2. Create user doc in Firestore (with 3-second timeout so it never hangs)
      try {
        final vbUser = VBUser(
          uid: user.uid,
          displayName: name,
          email: user.email ?? '',
          role: _selectedRole!,
          createdAt: DateTime.now(),
        );
        await _firestoreService.createUser(vbUser).timeout(
          const Duration(seconds: 3),
          onTimeout: () {},
        );
      } catch (_) {
        // Ignore Firestore creation failure so user is never blocked from entering app
      }

      if (!mounted) return;
      setState(() => _isLoading = false);

      // 3. Route to home screen
      if (_selectedRole == UserRole.blindUser) {
        context.go(AppRoutes.buHome);
      } else {
        context.go(AppRoutes.vHome);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Fallback navigation even if unexpected exception occurs
        if (_selectedRole == UserRole.blindUser) {
          context.go(AppRoutes.buHome);
        } else if (_selectedRole == UserRole.volunteer) {
          context.go(AppRoutes.vHome);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save profile: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isHindi = ref.watch(localeProvider).languageCode == 'hi';
    final bgColor = isDark ? VBDarkColors.background : VBLightColors.background;
    final textColor = isDark ? VBDarkColors.onSurface : VBLightColors.onSurface;
    final subtextColor =
        isDark ? VBDarkColors.onSurfaceVariant : VBLightColors.onSurfaceVariant;
    final primaryColor = isDark ? VBDarkColors.primary : VBLightColors.primary;
    final surfaceColor = isDark ? VBDarkColors.surface : VBLightColors.surface;
    final outlineColor = isDark ? VBDarkColors.outline : VBLightColors.outline;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: VBSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: VBSpacing.xxl),

              // Header
              Semantics(
                header: true,
                child: Text(
                  isHindi ? 'प्रोफ़ाइल सेटअप' : 'Set up profile',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const SizedBox(height: VBSpacing.sm),
              Text(
                isHindi
                    ? 'बताएँ कि आप VisionBridge का उपयोग कैसे करेंगे।'
                    : 'Let us know how you will use VisionBridge.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: subtextColor,
                    ),
              ),
              const SizedBox(height: VBSpacing.xl),

              // Role cards
              Text(
                isHindi ? 'मैं हूँ...' : 'I am...',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: textColor,
                    ),
              ),
              const SizedBox(height: VBSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _RoleCard(
                      icon: Icons.accessibility_new_rounded,
                      label: isHindi ? 'दृष्टिबाधित' : 'Visually\nImpaired',
                      subtitle: isHindi ? 'मुझे सहायता चाहिए' : 'I need assistance',
                      isSelected: _selectedRole == UserRole.blindUser,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedRole = UserRole.blindUser);
                        _ttsService.speak(
                            VBLanguages.byCode(ref.read(localeProvider).languageCode)
                                .voice(VoiceKey.roleSelectedBlind));
                      },
                      primaryColor: primaryColor,
                      surfaceColor: surfaceColor,
                      outlineColor: outlineColor,
                      textColor: textColor,
                      subtextColor: subtextColor,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: VBSpacing.sm),
                  Expanded(
                    child: _RoleCard(
                      icon: Icons.volunteer_activism_rounded,
                      label: isHindi ? 'स्वयंसेवक' : 'Sighted\nVolunteer',
                      subtitle: isHindi ? 'मैं मदद करना चाहता हूँ' : 'I want to help',
                      isSelected: _selectedRole == UserRole.volunteer,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedRole = UserRole.volunteer);
                        _ttsService.speak(
                            VBLanguages.byCode(ref.read(localeProvider).languageCode)
                                .voice(VoiceKey.roleSelectedVolunteer));
                      },
                      primaryColor: primaryColor,
                      surfaceColor: surfaceColor,
                      outlineColor: outlineColor,
                      textColor: textColor,
                      subtextColor: subtextColor,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: VBSpacing.xl),

              // Name form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    Semantics(
                      label: 'Full name input field',
                      child: TextFormField(
                        controller: _nameController,
                        textInputAction: TextInputAction.done,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: isHindi ? 'प्रदर्शित नाम' : 'Display Name',
                          hintText: isHindi ? 'अपना नाम दर्ज करें' : 'Enter your name',
                          prefixIcon: const Icon(Icons.person_outline_rounded),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: outlineColor),
                            borderRadius: BorderRadius.circular(VBRadius.md),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: primaryColor, width: 2),
                            borderRadius: BorderRadius.circular(VBRadius.md),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return isHindi ? 'नाम आवश्यक है' : 'Name is required';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: VBSpacing.xl),
                    SizedBox(
                      width: double.infinity,
                      height: VBTouchTarget.primaryAction,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSubmit,
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(isHindi ? 'VisionBridge शुरू करें' : 'Start Using VisionBridge'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: VBSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
    required this.primaryColor,
    required this.surfaceColor,
    required this.outlineColor,
    required this.textColor,
    required this.subtextColor,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  final Color primaryColor;
  final Color surfaceColor;
  final Color outlineColor;
  final Color textColor;
  final Color subtextColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: '$label. $subtitle',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(VBSpacing.md),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor.withOpacity(isDark ? 0.15 : 0.08)
                : surfaceColor,
            borderRadius: BorderRadius.circular(VBRadius.md),
            border: Border.all(
              color: isSelected ? primaryColor : outlineColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 40,
                color: isSelected ? primaryColor : subtextColor,
              ),
              const SizedBox(height: VBSpacing.sm),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: isSelected ? primaryColor : textColor,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
              ),
              const SizedBox(height: VBSpacing.xs),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: subtextColor,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
