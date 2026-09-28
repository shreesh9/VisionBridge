/// VisionBridge — Volunteer Settings Screen
///
/// Profile, notification prefs, availability schedule, logout.
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
import '../../../../shared/widgets/user_avatar.dart';

class VSettingsScreen extends ConsumerStatefulWidget {
  const VSettingsScreen({super.key});

  @override
  ConsumerState<VSettingsScreen> createState() => _VSettingsScreenState();
}

class _VSettingsScreenState extends ConsumerState<VSettingsScreen> {
  bool _notificationsEnabled = true;
  String? _profilePhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final notifs = await UserSettingsService.getNotificationsEnabled();
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
        _notificationsEnabled = notifs;
        _profilePhotoUrl = firestorePhoto ?? cachedPhoto;
      });
    }
  }

  /// Voice-language picker. Visual UI stays EN/Hindi; this picks the language
  /// for TTS and voice commands.
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

          // Profile
          _SectionLabel(title: isHindi ? 'प्रोफ़ाइल' : 'Profile', textColor: textColor),
          _Tile(
            iconWidget: UserAvatar(
              photoUrl: _profilePhotoUrl ?? FirebaseAuth.instance.currentUser?.photoURL,
              displayName: FirebaseAuth.instance.currentUser?.displayName,
              radius: 18,
            ),
            title: FirebaseAuth.instance.currentUser?.displayName ?? (isHindi ? 'स्वयंसेवक' : 'Volunteer'),
            subtitle: isHindi
                ? 'प्रोफ़ाइल और अवतार संपादित करें • ${FirebaseAuth.instance.currentUser?.email ?? ''}'
                : 'Tap to edit profile & avatar • ${FirebaseAuth.instance.currentUser?.email ?? ''}',
            onTap: () => _showEditProfileDialog(context, surfaceColor, textColor, subtextColor, primaryColor),
            surfaceColor: surfaceColor,
            outlineColor: outlineColor,
            textColor: textColor,
            subtextColor: subtextColor,
          ),
          const SizedBox(height: VBSpacing.lg),

          // Appearance
          _SectionLabel(title: isHindi ? 'दिखावट' : 'Appearance', textColor: textColor),
          _Tile(
            icon: Icons.palette_outlined,
            title: isHindi ? 'थीम' : 'Theme',
            trailing: SegmentedButton<ThemeMode>(
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
            surfaceColor: surfaceColor,
            outlineColor: outlineColor,
            textColor: textColor,
            subtextColor: subtextColor,
          ),
          const SizedBox(height: VBSpacing.sm),

          // Language Picker (voice layer: EN, HI, MR, TA, TE, BN, KN)
          _Tile(
            icon: Icons.language_rounded,
            title: 'Language / भाषा',
            subtitle: isHindi
                ? 'आवाज़ और आवाज़ आदेश की भाषा'
                : 'Voice & voice commands',
            trailing: Text(
              VBLanguages.byCode(currentLocale.languageCode).nativeName,
              style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600),
            ),
            onTap: () => _showLanguagePicker(context, primaryColor),
            surfaceColor: surfaceColor,
            outlineColor: outlineColor,
            textColor: textColor,
            subtextColor: subtextColor,
          ),
          const SizedBox(height: VBSpacing.lg),

          // Notifications
          _SectionLabel(title: isHindi ? 'सूचनाएं' : 'Notifications', textColor: textColor),
          _Tile(
            icon: Icons.notifications_outlined,
            title: isHindi ? 'पुश नोटिफिकेशन' : 'Push Notifications',
            subtitle: _notificationsEnabled
                ? (isHindi ? 'ऑनलाइन होने पर मदद अनुरोध प्राप्त हो रहे हैं' : 'Receiving help requests when online')
                : (isHindi ? 'सूचनाएं अक्षम' : 'Notifications disabled'),
            trailing: Switch.adaptive(
              value: _notificationsEnabled,
              onChanged: (val) async {
                HapticFeedback.selectionClick();
                setState(() => _notificationsEnabled = val);
                await UserSettingsService.setNotificationsEnabled(val);
              },
            ),
            surfaceColor: surfaceColor,
            outlineColor: outlineColor,
            textColor: textColor,
            subtextColor: subtextColor,
          ),
          const SizedBox(height: VBSpacing.sm),
          _Tile(
            icon: Icons.vibration_rounded,
            title: isHindi ? 'ध्वनि और कंपन' : 'Sound & Vibration',
            subtitle: isHindi ? 'आने वाली कॉल अलर्ट के लिए' : 'For incoming call alerts',
            trailing: Switch.adaptive(
              value: true,
              onChanged: (v) => HapticFeedback.selectionClick(),
            ),
            surfaceColor: surfaceColor,
            outlineColor: outlineColor,
            textColor: textColor,
            subtextColor: subtextColor,
          ),
          const SizedBox(height: VBSpacing.lg),

          // Account
          _SectionLabel(title: isHindi ? 'खाता' : 'Account', textColor: textColor),
          _Tile(
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
          ),
          const SizedBox(height: VBSpacing.xxl),

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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, required this.textColor});
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

class _Tile extends StatelessWidget {
  const _Tile({
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
