/// User Preferences & State Storage | Authored by Shreesh Nalawade (SN09092005)
///
/// VisionBridge — User Settings Service
///
/// Manages persistent user preferences using SharedPreferences.
library;

import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

class UserSettingsService {
  static const String _keyConfidenceThreshold = 'ai_confidence_threshold';
  static const String _keyTTSSpeed = 'tts_speed';
  static const String _keyTTSPitch = 'tts_pitch';
  static const String _keyHapticFeedback = 'haptic_feedback';
  static const String _keyAutoDescribe = 'auto_describe';

  /// Get stored confidence threshold (default: 0.70 / 70%)
  static Future<double> getConfidenceThreshold() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyConfidenceThreshold) ??
        AppConstants.detectionConfidenceThreshold;
  }

  /// Save confidence threshold (0.50 to 0.90)
  static Future<void> setConfidenceThreshold(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyConfidenceThreshold, value);
  }

  /// Get stored TTS speed
  static Future<double> getTTSSpeed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyTTSSpeed) ?? 0.5;
  }

  static Future<void> setTTSSpeed(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyTTSSpeed, value);
  }

  /// Get stored TTS pitch
  static Future<double> getTTSPitch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyTTSPitch) ?? 1.0;
  }

  static Future<void> setTTSPitch(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyTTSPitch, value);
  }

  /// Get haptic feedback setting
  static Future<bool> getHapticFeedback() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHapticFeedback) ?? true;
  }

  static Future<void> setHapticFeedback(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHapticFeedback, value);
  }

  static const String _keyGroqApiKey = 'groq_api_key';
  static const String _keyGeminiApiKey = 'gemini_api_key';

  /// Get custom Gemini API key or default
  static Future<String> getGeminiApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString(_keyGeminiApiKey) ?? '';
    if (key.trim().isNotEmpty) return key.trim();
    return const String.fromEnvironment('GEMINI_KEY');
  }

  static Future<void> setGeminiApiKey(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyGeminiApiKey, value.trim());
  }

  /// Get custom Groq API key or default
  static Future<String> getGroqApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString(_keyGroqApiKey) ?? '';
    if (key.trim().isNotEmpty) return key.trim();
    return const String.fromEnvironment('GROQ_KEY_1');
  }

  static Future<void> setGroqApiKey(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyGroqApiKey, value.trim());
  }

  static const String _keyVolunteerOnline = 'volunteer_online_status';
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keyUserAgeGroup = 'user_age_group';

  /// Get stored volunteer online status
  static Future<bool> getVolunteerOnlineStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyVolunteerOnline) ?? false;
  }

  static Future<void> setVolunteerOnlineStatus(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyVolunteerOnline, value);
  }

  /// Get volunteer notification toggle preference (default: true)
  static Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNotificationsEnabled) ?? true;
  }

  static Future<void> setNotificationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotificationsEnabled, value);
  }

  /// Get user age group preference ('genZ', 'genAlpha', 'adult', 'senior')
  static Future<String> getUserAgeGroup() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserAgeGroup) ?? 'adult';
  }

  static Future<void> setUserAgeGroup(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserAgeGroup, value);
  }

  /// Get auto describe setting
  static Future<bool> getAutoDescribe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAutoDescribe) ?? true;
  }

  static Future<void> setAutoDescribe(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoDescribe, value);
  }

  static const String _keyProfilePhotoUrl = 'profile_photo_url';

  static Future<String?> getProfilePhotoUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyProfilePhotoUrl);
  }

  static Future<void> setProfilePhotoUrl(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProfilePhotoUrl, value);
  }

  // --- Locale / Language ---
  static const String _keyLocale = 'app_locale';

  /// Get stored locale code (default: 'en')
  static Future<String> getLocaleCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLocale) ?? 'en';
  }

  /// Save locale code ('en' or 'hi')
  static Future<void> setLocaleCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLocale, code);
  }
}
