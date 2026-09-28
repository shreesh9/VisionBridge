/// VisionBridge — BU Settings Screen
///
/// Profile, accessibility prefs (TTS speed/pitch, detection sensitivity, theme), logout.
/// TTS reads each setting; STT for toggle changes.
library;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/locale/locale_provider.dart';
import '../../../../core/locale/supported_voice_languages.dart';
import '../../../../core/constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/firestore_service.dart';
import '../../../../services/user_settings_service.dart';
import '../../../../services/tts_stt_service.dart';
import '../../../../shared/widgets/user_avatar.dart';

class BUSettingsScreen extends ConsumerStatefulWidget {
  const BUSettingsScreen({super.key});

  @override
  ConsumerState<BUSettingsScreen> createState() => _BUSettingsScreenState();
}

class _BUSettingsScreenState extends ConsumerState<BUSettingsScreen> {
  double _ttsSpeed = 0.5;
  double _ttsPitch = 1.0;
  double _detectionSensitivity = AppConstants.detectionConfidenceThreshold;
  bool _hapticFeedback = true;
  bool _autoDescribe = true;
  String _userAgeGroup = 'adult';
  String? _profilePhotoUrl;

  /// Live TTS preview instance for hearing speed/pitch changes in realtime.
  final TTSSTTService _ttsPreview = TTSSTTService();

  @override
  void initState() {
    super.initState();
    _ttsPreview.initialize();
    _loadSettings();
  }

  @override
  void dispose() {
    _ttsPreview.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final threshold = await UserSettingsService.getConfidenceThreshold();
    final speed = await UserSettingsService.getTTSSpeed();
    final pitch = await UserSettingsService.getTTSPitch();
    final haptic = await UserSettingsService.getHapticFeedback();
    final auto = await UserSettingsService.getAutoDescribe();
    final ageGroup = await UserSettingsService.getUserAgeGroup();
    final cachedPhoto = await UserSettingsService.getProfilePhotoUrl();

    final uid = FirebaseAuth.instance.currentUser?.uid;
    String? firestorePhoto;
    if (uid != null) {
      try {
        final uDoc = await FirestoreService().getUser(uid);
        firestorePhoto = uDoc?.photoUrl;
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _detectionSensitivity = threshold;
        _ttsSpeed = speed;
        _ttsPitch = pitch;
        _hapticFeedback = haptic;
        _autoDescribe = auto;
        _userAgeGroup = ageGroup;
        _profilePhotoUrl = firestorePhoto ?? cachedPhoto;
      });
    }
  }

  /// Voice narration strings for the current language — spoken confirmations
  /// come from the registry so they're always in the selected language.
  VBLanguage get _lang =>
      VBLanguages.byCode(ref.read(localeProvider).languageCode);

  /// Voice-language picker. Visual UI stays EN/Hindi; this picks the language
  /// for TTS, AI descriptions, OCR read-aloud and voice commands.
  void _showLanguagePicker(BuildContext context, Color primaryColor) {
    final currentCode = ref.read(localeProvider).languageCode;
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(VBSpacing.md),
              child: Text(
                'Choose Voice Language / आवाज़ की भाषा चुनें',
                style: Theme.of(sheetCtx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final lang in VBLanguages.all)
                    ListTile(
                      title: Text(lang.nativeName,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(lang.englishName),
                      trailing: lang.code == currentCode
                          ? Icon(Icons.check_circle_rounded, color: primaryColor)
                          : null,
                      onTap: () async {
                        Navigator.pop(sheetCtx);
                        HapticFeedback.selectionClick();
                        await ref
                            .read(localeProvider.notifier)
                            .setLocale(Locale(lang.code));
                        if (!sheetCtx.mounted) return;
                        _ttsPreview.setLocale(lang.code);
                        // Confirm in the NEW language with that language's
                        // own string (registry), so voice + language match.
                        _ttsPreview.speak(
                          lang.voice(VoiceKey.languageChanged),
                          force: true,
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(
    BuildContext context,
    Color surfaceColor,
    Color textColor,
    Color subtextColor,
    Color primaryColor,
  ) {
    final user = FirebaseAuth.instance.currentUser;
    final nameController = TextEditingController(text: user?.displayName ?? '');
    String photoData = _profilePhotoUrl ?? user?.photoURL ?? '';
    final isHindi = ref.read(localeProvider).languageCode == 'hi';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            Future<void> pickPhoto() async {
              try {
                final picker = ImagePicker();
                final picked = await picker.pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 200,
                  maxHeight: 200,
                  imageQuality: 50,
                );
                if (picked != null) {
                  final bytes = await picked.readAsBytes();
                  final base64Str = 'data:image/jpeg;base64,${base64Encode(bytes)}';
                  setStateDialog(() {
                    photoData = base64Str;
                  });
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to select photo: $e')),
                );
              }
            }

            return AlertDialog(
              backgroundColor: surfaceColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VBRadius.md)),
              title: Text(isHindi ? 'प्रोफ़ाइल और फोटो संपादित करें' : 'Edit Profile & Photo', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: pickPhoto,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            UserAvatar(
                              photoUrl: photoData,
                              displayName: nameController.text,
                              radius: 44,
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: VBSpacing.xs),
                    Center(
                      child: TextButton.icon(
                        onPressed: pickPhoto,
                        icon: const Icon(Icons.photo_library_rounded, size: 18),
                        label: Text(isHindi ? 'डिवाइस से फोटो अपलोड करें' : 'Upload Photo from Device'),
                      ),
                    ),
                    const SizedBox(height: VBSpacing.md),
                    Text(isHindi ? 'प्रदर्शन नाम' : 'Display Name', style: TextStyle(color: subtextColor, fontSize: 12)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: nameController,
                      style: TextStyle(color: textColor),
                      onChanged: (_) => setStateDialog(() {}),
                      decoration: InputDecoration(
                        hintText: isHindi ? 'प्रदर्शन नाम दर्ज करें' : 'Enter display name',
                        hintStyle: TextStyle(color: subtextColor.withOpacity(0.5)),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(isHindi ? 'रद्द करें' : 'Cancel', style: TextStyle(color: subtextColor)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                  onPressed: () async {
                    final newName = nameController.text.trim();
                    if (user != null) {
                      try {
                        if (newName.isNotEmpty) await user.updateDisplayName(newName);
                        await FirestoreService().updateUserProfile(
                          user.uid,
                          displayName: newName.isNotEmpty ? newName : null,
                          photoUrl: photoData,
                        );
                        await UserSettingsService.setProfilePhotoUrl(photoData);
                        try {
                          await user.updatePhotoURL(photoData);
                        } catch (_) {}
                      } catch (_) {}
                    }
                    if (mounted) {
                      setState(() {
                        _profilePhotoUrl = photoData;
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(isHindi ? 'प्रोफ़ाइल फोटो सफलतापूर्वक अपडेट हो गई!' : 'Profile photo updated successfully!')),
                      );
                    }
                  },
                  child: Text(isHindi ? 'सेव करें' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? VBDarkColors.background : VBLightColors.background;
    final textColor = isDark ? VBDarkColors.onSurface : VBLightColors.onSurface;
    final subtextColor =
        isDark ? VBDarkColors.onSurfaceVariant : VBLightColors.onSurfaceVariant;
    final surfaceColor = isDark ? VBDarkColors.surface : VBLightColors.surface;
    final outlineColor = isDark ? VBDarkColors.outline : VBLightColors.outline;
    final primaryColor = isDark ? VBDarkColors.primary : VBLightColors.primary;
    final themeMode = ref.watch(themeModeProvider);
    final currentLocale = ref.watch(localeProvider);
    final isHindi = currentLocale.languageCode == 'hi';

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(isHindi ? 'सेटिंग्स' : 'Settings'),
        backgroundColor: bgColor,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: VBSpacing.md),
        children: [
          const SizedBox(height: VBSpacing.md),

          // === Profile Section ===
          _SectionHeader(title: isHindi ? 'प्रोफ़ाइल' : 'Profile', textColor: textColor),
          _SettingsTile(
            iconWidget: UserAvatar(
              photoUrl: _profilePhotoUrl ?? FirebaseAuth.instance.currentUser?.photoURL,
              displayName: FirebaseAuth.instance.currentUser?.displayName,
              radius: 18,
            ),
            title: FirebaseAuth.instance.currentUser?.displayName ?? (isHindi ? 'उपयोगकर्ता' : 'User'),
            subtitle: isHindi
                ? 'प्रोफ़ाइल और अवतार संपादित करें • ${FirebaseAuth.instance.currentUser?.email ?? ''}'
                : 'Tap to edit profile & avatar • ${FirebaseAuth.instance.currentUser?.email ?? ''}',
            onTap: () => _showEditProfileDialog(context, surfaceColor, textColor, subtextColor, primaryColor),
            surfaceColor: surfaceColor,
            outlineColor: outlineColor,
            textColor: textColor,
            subtextColor: subtextColor,
            isDark: isDark,
          ),
          const SizedBox(height: VBSpacing.lg),

          // === Appearance ===
          _SectionHeader(title: isHindi ? 'दिखावट' : 'Appearance', textColor: textColor),
          _SettingsTile(
            icon: Icons.palette_outlined,
            title: isHindi ? 'थीम' : 'Theme',
            trailing: Semantics(
              label: 'Theme mode selector. Current: ${themeMode.name}',
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_rounded, size: 18)),
                  ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.settings_suggest_rounded, size: 18)),
                  ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_rounded, size: 18)),
                ],
                selected: {themeMode},
                onSelectionChanged: (selected) {
                  HapticFeedback.selectionClick();
                  ref.read(themeModeProvider.notifier).setThemeMode(selected.first);
                },
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return primaryColor.withOpacity(0.15);
                    }
                    return Colors.transparent;
                  }),
                ),
                showSelectedIcon: false,
              ),
            ),
            surfaceColor: surfaceColor,
            outlineColor: outlineColor,
            textColor: textColor,
            subtextColor: subtextColor,
            isDark: isDark,
          ),
          const SizedBox(height: VBSpacing.sm),

          // Language Picker (voice layer: EN, HI, MR, TA, TE, BN, KN)
          _SettingsTile(
            icon: Icons.language_rounded,
            title: 'Language / भाषा',
            subtitle: isHindi
                ? 'आवाज़, AI विवरण और आवाज़ आदेश की भाषा'
                : 'Voice, AI descriptions & voice commands',
            trailing: Semantics(
              label: 'Language selector. Current: ${VBLanguages.byCode(ref.watch(localeProvider).languageCode).englishName}',
              child: Text(
                VBLanguages.byCode(currentLocale.languageCode).nativeName,
                style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600),
              ),
            ),
            onTap: () => _showLanguagePicker(context, primaryColor),
            surfaceColor: surfaceColor,
            outlineColor: outlineColor,
            textColor: textColor,
            subtextColor: subtextColor,
            isDark: isDark,
          ),
          const SizedBox(height: VBSpacing.lg),

          // === Voice ===
          _SectionHeader(title: isHindi ? 'आवाज़' : 'Voice', textColor: textColor),
          _SliderTile(
            icon: Icons.speed_rounded,
            title: isHindi ? 'बोलने की गति' : 'TTS Speed',
            value: _ttsSpeed,
            min: 0.1,
            max: 1.0,
            label: '${(_ttsSpeed * 100).round()}%',
            onChanged: (v) {
              setState(() => _ttsSpeed = v);
              UserSettingsService.setTTSSpeed(v);
              _ttsPreview.setSpeed(v);
              _ttsPreview.speak(_lang.voice(VoiceKey.speedPreview), force: true);
            },
            surfaceColor: surfaceColor,
            outlineColor: outlineColor,
            textColor: textColor,
            subtextColor: subtextColor,
            primaryColor: primaryColor,
            isDark: isDark,
          ),
          const SizedBox(height: VBSpacing.sm),
          _SliderTile(
            icon: Icons.tune_rounded,
            title: isHindi ? 'आवाज़ की पिच' : 'TTS Pitch',
            value: _ttsPitch,
            min: 0.5,
            max: 2.0,
            label: '${_ttsPitch.toStringAsFixed(1)}x',
            onChanged: (v) {
              setState(() => _ttsPitch = v);
              UserSettingsService.setTTSPitch(v);
              _ttsPreview.setPitch(v);
              _ttsPreview.speak(_lang.voice(VoiceKey.pitchPreview), force: true);
            },
            surfaceColor: surfaceColor,
            outlineColor: outlineColor,
            textColor: textColor,
            subtextColor: subtextColor,
            primaryColor: primaryColor,
            isDark: isDark,
          ),
          const SizedBox(height: VBSpacing.sm),
          _PersonaTile(
            selectedGroup: _userAgeGroup,
            onChanged: (newGroup) async {
              HapticFeedback.selectionClick();
              setState(() => _userAgeGroup = newGroup);
              await UserSettingsService.setUserAgeGroup(newGroup);
              _ttsPreview.speak(
                _lang.personaUpdated(newGroup),
                force: true,
              );
            },
            surfaceColor: surfaceColor,
            outlineColor: outlineColor,
            textColor: textColor,
            subtextColor: subtextColor,
            primaryColor: primaryColor,
            isHindi: isHindi,
          ),
          const SizedBox(height: VBSpacing.lg),

          // === Detection ===
          _SectionHeader(title: isHindi ? 'पहचान' : 'Detection', textColor: textColor),
          _SliderTile(
            icon: Icons.visibility_rounded,
            title: isHindi ? 'AI विश्वास सीमा' : 'AI Confidence Threshold',
            value: _detectionSensitivity,
            min: 0.5,
            max: 0.95,
            label: '${(_detectionSensitivity * 100).round()}%',
            onChanged: (v) {
              setState(() => _detectionSensitivity = v);
              UserSettingsService.setConfidenceThreshold(v);
            },
            surfaceColor: surfaceColor,
            outlineColor: outlineColor,
            textColor: textColor,
            subtextColor: subtextColor,
            primaryColor: primaryColor,
            isDark: isDark,
          ),
          const SizedBox(height: VBSpacing.sm),
          _ToggleTile(
            icon: Icons.auto_awesome_rounded,
            title: isHindi ? 'स्वचालित दृश्य विवरण' : 'Auto Scene Description',
            subtitle: isHindi ? 'AI से स्वचालित दृश्य विवरण' : 'Automatically describe scenes via AI',
            value: _autoDescribe,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              setState(() => _autoDescribe = v);
              UserSettingsService.setAutoDescribe(v);
            },
            surfaceColor: surfaceColor,
            outlineColor: outlineColor,
            textColor: textColor,
            subtextColor: subtextColor,
            isDark: isDark,
          ),
          const SizedBox(height: VBSpacing.lg),

          const SizedBox(height: VBSpacing.lg),

          // === Accessibility ===
          _SectionHeader(title: isHindi ? 'सुगमता' : 'Accessibility', textColor: textColor),
          _ToggleTile(
            icon: Icons.vibration_rounded,
            title: isHindi ? 'हैप्टिक फीडबैक' : 'Haptic Feedback',
            subtitle: isHindi ? 'मुख्य कार्यों पर कंपन' : 'Vibrate on key actions',
            value: _hapticFeedback,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              setState(() => _hapticFeedback = v);
            },
            surfaceColor: surfaceColor,
            outlineColor: outlineColor,
            textColor: textColor,
            subtextColor: subtextColor,
            isDark: isDark,
          ),
          const SizedBox(height: VBSpacing.lg),

          // === Account ===
          _SectionHeader(title: isHindi ? 'खाता' : 'Account', textColor: textColor),
          _SettingsTile(
            icon: Icons.logout_rounded,
            title: isHindi ? 'साइन आउट' : 'Sign Out',
            titleColor: isDark ? VBDarkColors.error : VBLightColors.error,
            onTap: () async {
              HapticFeedback.mediumImpact();
              await AuthService().signOut();
              if (context.mounted) {
                context.go(AppRoutes.login);
              }
            },
            surfaceColor: surfaceColor,
            outlineColor: outlineColor,
            textColor: textColor,
            subtextColor: subtextColor,
            isDark: isDark,
          ),
          const SizedBox(height: VBSpacing.xxl),

          // Version
          Center(
            child: Text(
              'VisionBridge v${AppConstants.appVersion}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: subtextColor),
            ),
          ),
          const SizedBox(height: VBSpacing.xl),
        ],
      ),
    );
  }
}

// === Reusable Setting Widgets ===

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.textColor});
  final String title;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: VBSpacing.xs, bottom: VBSpacing.sm),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    this.icon = Icons.circle_outlined,
    this.iconWidget,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.titleColor,
    required this.surfaceColor,
    required this.outlineColor,
    required this.textColor,
    required this.subtextColor,
    required this.isDark,
  });

  final IconData icon;
  final Widget? iconWidget;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;
  final Color surfaceColor;
  final Color outlineColor;
  final Color textColor;
  final Color subtextColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: '$title${subtitle != null ? '. $subtitle' : ''}',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(VBSpacing.md),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(VBRadius.md),
            border: Border.all(color: outlineColor, width: 1),
          ),
          child: Row(
            children: [
              iconWidget ?? Icon(icon, color: subtextColor, size: 22),
              const SizedBox(width: VBSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: titleColor ?? textColor)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: subtextColor)),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.surfaceColor,
    required this.outlineColor,
    required this.textColor,
    required this.subtextColor,
    required this.isDark,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color surfaceColor;
  final Color outlineColor;
  final Color textColor;
  final Color subtextColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return _SettingsTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
      ),
      surfaceColor: surfaceColor,
      outlineColor: outlineColor,
      textColor: textColor,
      subtextColor: subtextColor,
      isDark: isDark,
    );
  }
}

class _SliderTile extends StatelessWidget {
  const _SliderTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.label,
    required this.onChanged,
    required this.surfaceColor,
    required this.outlineColor,
    required this.textColor,
    required this.subtextColor,
    required this.primaryColor,
    required this.isDark,
  });

  final IconData icon;
  final String title;
  final double value;
  final double min;
  final double max;
  final String label;
  final ValueChanged<double> onChanged;
  final Color surfaceColor;
  final Color outlineColor;
  final Color textColor;
  final Color subtextColor;
  final Color primaryColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title. Current value: $label',
      slider: true,
      child: Container(
        padding: const EdgeInsets.all(VBSpacing.md),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(VBRadius.md),
          border: Border.all(color: outlineColor, width: 1),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: subtextColor, size: 22),
                const SizedBox(width: VBSpacing.md),
                Expanded(
                  child: Text(title, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: textColor)),
                ),
                Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: primaryColor, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: VBSpacing.sm),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: primaryColor,
                thumbColor: primaryColor,
                inactiveTrackColor: outlineColor,
                overlayColor: primaryColor.withOpacity(0.1),
                trackHeight: 4,
              ),
              child: Slider(
                value: value,
                min: min,
                max: max,
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonaTile extends StatelessWidget {
  const _PersonaTile({
    required this.selectedGroup,
    required this.onChanged,
    required this.surfaceColor,
    required this.outlineColor,
    required this.textColor,
    required this.subtextColor,
    required this.primaryColor,
    required this.isHindi,
  });

  final String selectedGroup;
  final ValueChanged<String> onChanged;
  final Color surfaceColor;
  final Color outlineColor;
  final Color textColor;
  final Color subtextColor;
  final Color primaryColor;
  final bool isHindi;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(VBSpacing.md),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(VBRadius.md),
        border: Border.all(color: outlineColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology_outlined, color: subtextColor, size: 22),
              const SizedBox(width: VBSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isHindi ? 'AI पर्सोना टोन' : 'AI Persona Tone',
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(color: textColor, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(isHindi ? 'AI आवाज़ शैली आपकी आयु वर्ग के अनुसार बदलती है' : 'Adapts AI voice tone to your age group',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: subtextColor)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: VBSpacing.md),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'genZ', label: Text('Gen Z', style: TextStyle(fontSize: 12))),
                ButtonSegment(value: 'genAlpha', label: Text('Gen Alpha', style: TextStyle(fontSize: 12))),
                ButtonSegment(value: 'adult', label: Text('Adult', style: TextStyle(fontSize: 12))),
              ],
              selected: {selectedGroup},
              onSelectionChanged: (selected) => onChanged(selected.first),
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return primaryColor.withOpacity(0.2);
                  }
                  return Colors.transparent;
                }),
              ),
              showSelectedIcon: false,
            ),
          ),
        ],
      ),
    );
  }
}
