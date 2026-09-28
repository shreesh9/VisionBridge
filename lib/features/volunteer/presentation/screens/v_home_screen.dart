/// VisionBridge — Volunteer Home Screen
///
/// Dashboard: online/offline toggle, pending request indicator, call history shortcut.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/constants.dart';
import '../../../../core/locale/locale_provider.dart';
import '../../../../core/locale/supported_voice_languages.dart';
import '../../../../services/firestore_service.dart';
import '../../../../services/fcm_service.dart';


import '../../../../services/user_settings_service.dart';

class VHomeScreen extends ConsumerStatefulWidget {
  const VHomeScreen({super.key});

  @override
  ConsumerState<VHomeScreen> createState() => _VHomeScreenState();
}

class _VHomeScreenState extends ConsumerState<VHomeScreen> {
  bool _isOnline = false;
  bool _isTogglingOnline = false;
  int _totalCallsHelped = 0;
  int _totalMinutesHelped = 0;
  List<Map<String, dynamic>> _recentActivity = [];
  bool _isLoadingStats = true;
  StreamSubscription? _pendingCallSub;
  String? _lastNotifiedCallId;
  String _localeCode = 'en';

  final _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _loadLocale();
    _loadStats();
  }

  Future<void> _loadLocale() async {
    try {
      _localeCode = await UserSettingsService.getLocaleCode();
      if (mounted) setState(() {});
    } catch (_) {}
  }

  @override
  void dispose() {
    _pendingCallSub?.cancel();
    super.dispose();
  }

  void _updateCallListener() {
    _pendingCallSub?.cancel();
    if (_isOnline) {
      _pendingCallSub = _firestoreService.pendingCallRequests().listen((requests) async {
        if (!mounted || !_isOnline) return;

        // Check if volunteer has enabled incoming call notifications
        final notifsEnabled = await UserSettingsService.getNotificationsEnabled();
        if (!notifsEnabled) return;

        final now = DateTime.now();
        final recentPending = requests.where((r) {
          if (r.status != 'pending') return false;
          if (r.createdAt == null) return true; // new call just created
          return now.difference(r.createdAt!).inSeconds < 60;
        }).toList();

        if (recentPending.isNotEmpty) {
          final firstReq = recentPending.first;
          if (_lastNotifiedCallId != firstReq.id) {
            _lastNotifiedCallId = firstReq.id;
            if (mounted) {
              context.push(AppRoutes.vIncomingCall, extra: {
                'callRequestId': firstReq.id,
                'signalingRoomId': firstReq.id,
              });
            }
          }
        }
      });
    }
  }

  Future<void> _loadStats() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Load locally saved online status first for instant UI response
    final savedOnlineStatus = await UserSettingsService.getVolunteerOnlineStatus();
    if (mounted) {
      setState(() {
        _isOnline = savedOnlineStatus;
      });
      _updateCallListener();
    }

    try {
      // Sync with Firestore user document
      final userDoc = await _firestoreService.getUser(uid);
      final isOnlineFromDb = userDoc?.isOnline ?? savedOnlineStatus;

      final history = await _firestoreService.getVolunteerCallHistory(uid, limit: 100);

      int totalSecs = 0;
      for (final item in history) {
        final sec = item['durationSeconds'] as int? ?? 0;
        totalSecs += (sec > 0 ? sec : 60);
      }

      if (mounted) {
        setState(() {
          // Only update online status if user isn't actively toggling
          if (!_isTogglingOnline) {
            _isOnline = isOnlineFromDb;
          }
          _recentActivity = history;
          _totalCallsHelped = history.length;
          _totalMinutesHelped = (totalSecs / 60).ceil();
          _isLoadingStats = false;
        });
        _updateCallListener();
      }

      // Ensure local storage stays in sync with Firestore
      await UserSettingsService.setVolunteerOnlineStatus(isOnlineFromDb);
    } catch (_) {
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  Future<void> _toggleOnline() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    HapticFeedback.mediumImpact();
    _isTogglingOnline = true;
    final newStatus = !_isOnline;
    setState(() => _isOnline = newStatus);
    _updateCallListener();

    // Save locally first — this always succeeds and is the UI source of truth
    await UserSettingsService.setVolunteerOnlineStatus(newStatus);

    // Ensure FCM token is registered when going online (for push call delivery)
    if (newStatus) {
      FCMService.instance.initialize();
    }

    // Try to sync to Firestore (best-effort — may fail due to security rules)
    try {
      await _firestoreService.setOnlineStatus(uid, newStatus);
    } catch (e) {
      debugPrint('[Volunteer] Firestore setOnlineStatus failed (non-fatal): $e');
      // Do NOT revert — local state is the source of truth for toggle UI
    } finally {
      _isTogglingOnline = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Live-update the UI when the language toggle changes in settings.
    final localeCode = ref.watch(localeProvider).languageCode;
    if (localeCode != _localeCode) {
      _localeCode = localeCode;
    }
    final lang = VBLanguages.byCode(_localeCode);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? VBDarkColors.background : VBLightColors.background;
    final textColor = isDark ? VBDarkColors.onSurface : VBLightColors.onSurface;
    final subtextColor =
        isDark ? VBDarkColors.onSurfaceVariant : VBLightColors.onSurfaceVariant;
    final primaryColor = isDark ? VBDarkColors.primary : VBLightColors.primary;
    final secondaryColor =
        isDark ? VBDarkColors.secondary : VBLightColors.secondary;
    final successColor = isDark ? VBDarkColors.success : VBLightColors.success;
    final surfaceColor = isDark ? VBDarkColors.surface : VBLightColors.surface;
    final outlineColor = isDark ? VBDarkColors.outline : VBLightColors.outline;

    return Scaffold(
      backgroundColor: bgColor,
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
                          lang.ui(UIKey.volunteer),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: subtextColor,
                              ),
                        ),
                        const SizedBox(height: VBSpacing.xs),
                        Text(
                          FirebaseAuth.instance.currentUser?.displayName ?? lang.ui(UIKey.dashboard),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.displayMedium?.copyWith(
                                    color: textColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: VBSpacing.md),
                  IconButton(
                    onPressed: () => context.push(AppRoutes.vSettings),
                    icon: Icon(Icons.settings_outlined, color: subtextColor),
                    iconSize: 28,
                  ),
                ],
              ),
              const SizedBox(height: VBSpacing.xl),

              // === Online/Offline Toggle ===
              Semantics(
                toggled: _isOnline,
                label: _isOnline
                    ? lang.ui(UIKey.availabilityToggleOnline)
                    : lang.ui(UIKey.availabilityToggleOffline),
                child: GestureDetector(
                  onTap: _toggleOnline,
                  child: AnimatedContainer(
                    duration: VBDuration.normal,
                    curve: VBCurves.standard,
                    width: double.infinity,
                    padding: const EdgeInsets.all(VBSpacing.lg),
                    decoration: BoxDecoration(
                      gradient: _isOnline
                          ? LinearGradient(
                              colors: [
                                successColor,
                                successColor.withOpacity(0.8),
                              ],
                            )
                          : null,
                      color: _isOnline ? null : surfaceColor,
                      borderRadius: BorderRadius.circular(VBRadius.lg),
                      border: _isOnline
                          ? null
                          : Border.all(color: outlineColor, width: 1),
                      boxShadow: _isOnline && !isDark
                          ? [
                              BoxShadow(
                                color: successColor.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ]
                          : [],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: _isOnline
                                ? Colors.white.withOpacity(0.2)
                                : subtextColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isOnline
                                ? Icons.wifi_rounded
                                : Icons.wifi_off_rounded,
                            size: 28,
                            color: _isOnline ? Colors.white : subtextColor,
                          ),
                        ),
                        const SizedBox(width: VBSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isOnline
                                    ? lang.ui(UIKey.youreOnline)
                                    : lang.ui(UIKey.youreOffline),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      color:
                                          _isOnline ? Colors.white : textColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _isOnline
                                    ? lang.ui(UIKey.readyToReceive)
                                    : lang.ui(UIKey.tapToStartVolunteering),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: _isOnline
                                          ? Colors.white
                                              .withOpacity(0.85)
                                          : subtextColor,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        // Toggle indicator
                        AnimatedContainer(
                          duration: VBDuration.normal,
                          width: 52,
                          height: 30,
                          decoration: BoxDecoration(
                            color: _isOnline
                                ? Colors.white.withOpacity(0.3)
                                : outlineColor,
                            borderRadius:
                                BorderRadius.circular(VBRadius.full),
                          ),
                          child: AnimatedAlign(
                            duration: VBDuration.normal,
                            curve: VBCurves.standard,
                            alignment: _isOnline
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              width: 24,
                              height: 24,
                              margin: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: _isOnline
                                    ? Colors.white
                                    : subtextColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: VBSpacing.lg),

              // === Stats Row ===
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.call_rounded,
                      value: '$_totalCallsHelped',
                      label: lang.ui(UIKey.callsHelped),
                      color: primaryColor,
                      surfaceColor: surfaceColor,
                      outlineColor: outlineColor,
                      textColor: textColor,
                      subtextColor: subtextColor,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: VBSpacing.sm),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.timer_outlined,
                      value: '${_totalMinutesHelped}m',
                      label: lang.ui(UIKey.timeGiven),
                      color: secondaryColor,
                      surfaceColor: surfaceColor,
                      outlineColor: outlineColor,
                      textColor: textColor,
                      subtextColor: subtextColor,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: VBSpacing.lg),

              // === Recent Activity ===
              Text(
                lang.ui(UIKey.recentActivity),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: VBSpacing.sm),
              Expanded(
                child: _isLoadingStats
                    ? const Center(child: CircularProgressIndicator())
                    : _recentActivity.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.volunteer_activism_rounded,
                                    size: 48,
                                    color: subtextColor),
                                const SizedBox(height: VBSpacing.sm),
                                Text(
                                  lang.ui(UIKey.noCallsYet),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(color: subtextColor),
                                ),
                                const SizedBox(height: VBSpacing.xs),
                                Text(
                                  lang.ui(UIKey.goOnlineToStartHelpingExcl),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: subtextColor),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: _recentActivity.length > 5
                                ? 5
                                : _recentActivity.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: VBSpacing.sm),
                            itemBuilder: (context, index) {
                              final call = _recentActivity[index];
                              final blindUserName =
                                  call['blindUserName'] as String? ??
                                      lang.ui(UIKey.visuallyImpairedUser);
                              final title = lang.uiX(UIKey.helpedUser, blindUserName);
                              final createdAt = call['createdAt'] as dynamic;
                              String timeAgo = lang.ui(UIKey.justNow);
                              if (createdAt != null) {
                                final dt = createdAt is DateTime
                                    ? createdAt
                                    : (createdAt).toDate();
                                final diff = DateTime.now().difference(dt);
                                if (diff.inDays > 0) {
                                  timeAgo = lang.uiX(UIKey.daysAgo, '${diff.inDays}');
                                } else if (diff.inHours > 0) {
                                  timeAgo = lang.uiX(UIKey.hoursAgo, '${diff.inHours}');
                                } else if (diff.inMinutes > 0) {
                                  timeAgo = lang.uiX(UIKey.minutesAgo, '${diff.inMinutes}');
                                }
                              }

                              final sec = call['durationSeconds'] as int? ?? 0;
                              String durationStr = '1m';
                              if (sec > 0) {
                                final m = sec ~/ 60;
                                final remS = sec % 60;
                                if (m == 0) {
                                  durationStr = '${remS}s';
                                } else if (remS == 0) {
                                  durationStr = '${m}m';
                                } else {
                                  durationStr = '${m}m ${remS}s';
                                }
                              }

                              return _ActivityTile(
                                title: title,
                                timeAgo: timeAgo,
                                duration: durationStr,
                                textColor: textColor,
                                subtextColor: subtextColor,
                                surfaceColor: surfaceColor,
                                outlineColor: outlineColor,
                                isDark: isDark,
                              );
                            },
                          ),
              ),

              // Bottom nav shortcut & version footer
              Padding(
                padding: const EdgeInsets.only(bottom: VBSpacing.sm),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => context.push(AppRoutes.vCallHistory),
                            icon: const Icon(Icons.history_rounded),
                            label: Text(lang.ui(UIKey.fullHistory)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: VBSpacing.xs),
                    Text(
                      'VisionBridge v${AppConstants.appVersion}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: subtextColor.withOpacity(0.5)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.surfaceColor,
    required this.outlineColor,
    required this.textColor,
    required this.subtextColor,
    required this.isDark,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color surfaceColor;
  final Color outlineColor;
  final Color textColor;
  final Color subtextColor;
  final bool isDark;

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
          Icon(icon, color: color, size: 24),
          const SizedBox(height: VBSpacing.sm),
          Text(
            value,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: subtextColor)),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.title,
    required this.timeAgo,
    required this.duration,
    required this.textColor,
    required this.subtextColor,
    required this.surfaceColor,
    required this.outlineColor,
    required this.isDark,
  });

  final String title;
  final String timeAgo;
  final String duration;
  final Color textColor;
  final Color subtextColor;
  final Color surfaceColor;
  final Color outlineColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(VBSpacing.md),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(VBRadius.md),
        border: Border.all(color: outlineColor, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: textColor)),
                const SizedBox(height: 4),
                Text('$timeAgo · $duration',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: subtextColor)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: subtextColor),
        ],
      ),
    );
  }
}
