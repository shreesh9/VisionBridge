/// VisionBridge Design Palette & Aesthetics created by Shreesh Nalawade
///
/// VisionBridge — Color Tokens
///
/// Extracted from the reference palette images.
/// Dark mode: navy-indigo (#121419, #4B447A, #5F7C9A, #A0A0B0)
/// Light mode: purple-lavender (#21222D, #958CE8, #ACD1FD, #DBDBE5)
///
/// SOS red is RESERVED — never used outside the emergency button.
library;

import 'package:flutter/material.dart';

// ============================================================================
// LIGHT MODE COLORS
// ============================================================================

abstract final class VBLightColors {
  // --- Backgrounds ---
  static const Color background = Color(0xFFF5F5FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFEDEDF3);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF21222D);

  // --- Primary (lavender/purple) ---
  static const Color primary = Color(0xFF958CE8);
  static const Color primaryVariant = Color(0xFF7B72D0);
  static const Color primaryMuted = Color(0xFFC5C0F0);
  static const Color primaryContainer = Color(0xFFEEECFB);

  // --- Secondary (sky blue) ---
  static const Color secondary = Color(0xFFACD1FD);
  static const Color secondaryVariant = Color(0xFF5F7C9A);
  static const Color secondaryContainer = Color(0xFFE3F0FF);

  // --- Text ---
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF21222D);
  static const Color onSurfaceVariant = Color(0xFF6B6D7B);
  static const Color onSurfaceDark = Color(0xFFFFFFFF);

  // --- Borders ---
  static const Color outline = Color(0xFFDBDBE5);
  static const Color outlineVariant = Color(0xFFEDEDF3);

  // --- Status ---
  static const Color success = Color(0xFF16A34A);
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color warning = Color(0xFFD97706);
  static const Color onWarning = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFDC2626);
  static const Color onError = Color(0xFFFFFFFF);

  // --- SOS (RESERVED — emergency only) ---
  static const Color sos = Color(0xFFDC2626);
  static const Color onSOS = Color(0xFFFFFFFF);
  static const Color sosGlow = Color(0x55DC2626); // 33% opacity

  // --- Scrim ---
  static const Color scrim = Color(0x66000000); // 40% black

  // --- Misc ---
  static const Color shimmerBase = Color(0xFFEDEDF3);
  static const Color shimmerHighlight = Color(0xFFF5F5FA);
}

// ============================================================================
// DARK MODE COLORS
// ============================================================================

abstract final class VBDarkColors {
  // --- Backgrounds ---
  static const Color background = Color(0xFF0D0F14);
  static const Color surface = Color(0xFF121419);
  static const Color surfaceVariant = Color(0xFF1A1D26);
  static const Color surfaceElevated = Color(0xFF222636);

  // --- Primary (lavender — brighter on dark) ---
  static const Color primary = Color(0xFF958CE8);
  static const Color primaryVariant = Color(0xFF7B72D0);
  static const Color primaryMuted = Color(0xFF4B447A);
  static const Color primaryContainer = Color(0xFF2A2640);

  // --- Secondary (steel blue) ---
  static const Color secondary = Color(0xFF5F7C9A);
  static const Color secondaryVariant = Color(0xFFACD1FD);
  static const Color secondaryContainer = Color(0xFF1E2A38);

  // --- Text ---
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFFE8E8F0);
  static const Color onSurfaceVariant = Color(0xFFA0A0B0);

  // --- Borders (outline-based, NO shadows in dark mode) ---
  static const Color outline = Color(0xFF2E3142);
  static const Color outlineVariant = Color(0xFF1F2233);

  // --- Status ---
  static const Color success = Color(0xFF4ADE80);
  static const Color onSuccess = Color(0xFF052E16);
  static const Color warning = Color(0xFFFBBF24);
  static const Color onWarning = Color(0xFF451A03);
  static const Color error = Color(0xFFEF4444);
  static const Color onError = Color(0xFFFFFFFF);

  // --- SOS (RESERVED — emergency only) ---
  static const Color sos = Color(0xFFEF4444);
  static const Color onSOS = Color(0xFFFFFFFF);
  static const Color sosGlow = Color(0x40EF4444); // 25% opacity

  // --- Scrim ---
  static const Color scrim = Color(0xB3000000); // 70% black

  // --- Misc ---
  static const Color shimmerBase = Color(0xFF1A1D26);
  static const Color shimmerHighlight = Color(0xFF222636);
}
