/// VisionBridge — BU Call History Screen
library;

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../../../shared/widgets/sos_button.dart';
import '../../../../services/firestore_service.dart';
import '../../../../services/user_settings_service.dart';
import '../../../../core/locale/supported_voice_languages.dart';
import '../../../../shared/widgets/user_avatar.dart';

class BUCallHistoryScreen extends StatefulWidget {
  const BUCallHistoryScreen({super.key});

  @override
  State<BUCallHistoryScreen> createState() => _BUCallHistoryScreenState();
}

class _BUCallHistoryScreenState extends State<BUCallHistoryScreen> {
  final _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;
  String _localeCode = 'en';

  /// UI/narration strings for the current language (from the registry).
  VBLanguage get _lang => VBLanguages.byCode(_localeCode);

  @override
  void initState() {
    super.initState();
    _loadLocaleAndHistory();
  }

  Future<void> _loadLocaleAndHistory() async {
    try {
      _localeCode = await UserSettingsService.getLocaleCode();
    } catch (_) {}
    await _loadHistory();
  }

  Future<void> _loadHistory() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }    try {
      final history = await _firestoreService.getBlindUserCallHistory(uid);
      if (mounted) {
        setState(() {
          _history = history;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatTimeAgo(dynamic createdAt) {
    if (createdAt == null) return _lang.ui(UIKey.justNow);
    final dt = createdAt is DateTime ? createdAt : createdAt.toDate();
    final diff = DateTime.now().difference(dt as DateTime);
    if (diff.inDays > 0) return _lang.uiX(UIKey.daysAgo, '${diff.inDays}');
    if (diff.inHours > 0) return _lang.uiX(UIKey.hoursAgo, '${diff.inHours}');
    if (diff.inMinutes > 0) return _lang.uiX(UIKey.minutesAgo, '${diff.inMinutes}');
    return _lang.ui(UIKey.justNow);
  }

  String _formatDuration(dynamic secs) {
    final s = (secs is int) ? secs : 0;
    if (s <= 0) return '1m';
    final m = s ~/ 60;
    final remS = s % 60;
    if (m == 0) return '${remS}s';
    if (remS == 0) return '${m}m';
    return '${m}m ${remS}s';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? VBDarkColors.background : VBLightColors.background;
    final textColor = isDark ? VBDarkColors.onSurface : VBLightColors.onSurface;
    final subtextColor =
        isDark ? VBDarkColors.onSurfaceVariant : VBLightColors.onSurfaceVariant;
    final surfaceColor = isDark ? VBDarkColors.surface : VBLightColors.surface;
    final outlineColor = isDark ? VBDarkColors.outline : VBLightColors.outline;    final primaryColor = isDark ? VBDarkColors.primary : VBLightColors.primary;

    return Scaffold(
      backgroundColor: bgColor,
      floatingActionButton: const SOSButton(),
      appBar: AppBar(
        title: Text(_lang.ui(UIKey.callHistory)),
        backgroundColor: bgColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history_rounded, size: 64, color: subtextColor),
                      const SizedBox(height: VBSpacing.md),
                      Text(_lang.ui(UIKey.noCallsYet),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: subtextColor)),
                      const SizedBox(height: VBSpacing.sm),
                      Text(_lang.ui(UIKey.historyWillAppearHere),
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: subtextColor)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(VBSpacing.md),
                  itemCount: _history.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: VBSpacing.sm),
                  itemBuilder: (context, index) {
                    final record = _history[index];
                    final volunteerName = record['volunteerName'] as String? ?? _lang.ui(UIKey.communityVolunteer);
                    final title = _lang.uiX(UIKey.assistedBy, volunteerName);
                    final timeAgo = _formatTimeAgo(record['createdAt']);
                    final durationStr = _formatDuration(record['durationSeconds']);

                    return Semantics(
                      label: '$title. $timeAgo. Duration: $durationStr.',
                      child: Container(
                        padding: const EdgeInsets.all(VBSpacing.md),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(VBRadius.md),
                          border: Border.all(color: outlineColor, width: 1),
                          boxShadow: isDark
                              ? []
                              : [
                                  BoxShadow(
                                      color: Colors.black
                                          .withOpacity(0.04),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2))
                                ],
                        ),
                        child: Row(
                          children: [
                            UserAvatar(
                              photoUrl: record['volunteerPhotoUrl'] as String?,
                              displayName: volunteerName,
                              radius: 22,
                            ),
                            const SizedBox(width: VBSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          color: textColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _lang.uiX(UIKey.durationLabel, durationStr),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: subtextColor),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              durationStr,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                color: primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
