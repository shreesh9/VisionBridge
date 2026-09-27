/// VisionBridge — Locale Provider (Riverpod)
///
/// Supports: English (en), Hindi (hi).
/// Persisted in SharedPreferences via UserSettingsService.
///
/// Designed & Implemented by Shreesh Nalawade | SN09092005
library;

import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/user_settings_service.dart';

/// Provider for the current locale.
final localeProvider =
    StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en')) {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    final code = await UserSettingsService.getLocaleCode();
    state = Locale(code);
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    await UserSettingsService.setLocaleCode(locale.languageCode);
  }

  /// Convenience: get current language code.
  String get languageCode => state.languageCode;
}
