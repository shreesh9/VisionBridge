/// VisionBridge Theme Builder
///
/// Constructs Material 3 ThemeData for light and dark modes,
/// wired to the color tokens from the reference palette images.
/// Dark mode: no shadows, outline-based card edges.
/// Light mode: subtle elevation, soft shadows.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'colors.dart';
import 'dimensions.dart';
import 'typography.dart';

abstract final class VBTheme {
  // ========================================================================
  // LIGHT THEME
  // ========================================================================
  static ThemeData get light {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: VBLightColors.primary,
      onPrimary: VBLightColors.onPrimary,
      primaryContainer: VBLightColors.primaryContainer,
      onPrimaryContainer: VBLightColors.onSurface,
      secondary: VBLightColors.secondary,
      onSecondary: VBLightColors.onSurface,
      secondaryContainer: VBLightColors.secondaryContainer,
      onSecondaryContainer: VBLightColors.onSurface,
      surface: VBLightColors.surface,
      onSurface: VBLightColors.onSurface,
      onSurfaceVariant: VBLightColors.onSurfaceVariant,
      error: VBLightColors.error,
      onError: VBLightColors.onError,
      outline: VBLightColors.outline,
      outlineVariant: VBLightColors.outlineVariant,
      shadow: Color(0x1A000000),
      scrim: VBLightColors.scrim,
      surfaceContainerHighest: VBLightColors.surfaceVariant,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      textTheme: VBTypography.textTheme.apply(
        bodyColor: VBLightColors.onSurface,
        displayColor: VBLightColors.onSurface,
      ),
      scaffoldBackgroundColor: VBLightColors.background,
      // --- App Bar ---
      appBarTheme: AppBarTheme(
        backgroundColor: VBLightColors.background,
        foregroundColor: VBLightColors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: VBTypography.textTheme.titleLarge?.copyWith(
          color: VBLightColors.onSurface,
        ),
      ),
      // --- Cards ---
      cardTheme: CardThemeData(
        color: VBLightColors.surface,
        elevation: VBElevation.low,
        shadowColor: const Color(0x1A000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VBRadius.md),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: VBSpacing.md,
          vertical: VBSpacing.sm,
        ),
      ),
      // --- Elevated Button (Primary actions) ---
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: VBLightColors.primary,
          foregroundColor: VBLightColors.onPrimary,
          elevation: VBElevation.low,
          minimumSize: const Size(double.infinity, VBTouchTarget.primaryAction),
          padding: const EdgeInsets.symmetric(
            horizontal: VBSpacing.lg,
            vertical: VBSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(VBRadius.sm),
          ),
          textStyle: VBTypography.textTheme.labelLarge,
        ),
      ),
      // --- Outlined Button ---
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: VBLightColors.primary,
          minimumSize: const Size(double.infinity, VBTouchTarget.minimum),
          padding: const EdgeInsets.symmetric(
            horizontal: VBSpacing.lg,
            vertical: VBSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(VBRadius.sm),
          ),
          side: const BorderSide(color: VBLightColors.outline),
          textStyle: VBTypography.textTheme.labelLarge,
        ),
      ),
      // --- Text Button ---
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: VBLightColors.primary,
          minimumSize: const Size(VBTouchTarget.minimum, VBTouchTarget.minimum),
          textStyle: VBTypography.textTheme.labelLarge,
        ),
      ),
      // --- Input Decoration ---
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: VBLightColors.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: VBSpacing.md,
          vertical: VBSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(VBRadius.sm),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(VBRadius.sm),
          borderSide: const BorderSide(color: VBLightColors.outline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(VBRadius.sm),
          borderSide: const BorderSide(color: VBLightColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(VBRadius.sm),
          borderSide: const BorderSide(color: VBLightColors.error, width: 1),
        ),
        hintStyle: VBTypography.textTheme.bodyLarge?.copyWith(
          color: VBLightColors.onSurfaceVariant,
        ),
        labelStyle: VBTypography.textTheme.bodyMedium?.copyWith(
          color: VBLightColors.onSurfaceVariant,
        ),
      ),
      // --- Bottom Navigation ---
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: VBLightColors.surface,
        selectedItemColor: VBLightColors.primary,
        unselectedItemColor: VBLightColors.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: VBTypography.textTheme.labelSmall,
        unselectedLabelStyle: VBTypography.textTheme.labelSmall,
      ),
      // --- Navigation Bar (Material 3) ---
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: VBLightColors.surface,
        indicatorColor: VBLightColors.primaryContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 72,
        labelTextStyle: WidgetStatePropertyAll(
          VBTypography.textTheme.labelSmall,
        ),
      ),
      // --- Bottom Sheet ---
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: VBLightColors.surface,
        modalBackgroundColor: VBLightColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(VBRadius.lg),
          ),
        ),
        elevation: VBElevation.medium,
      ),
      // --- Dialog ---
      dialogTheme: DialogThemeData(
        backgroundColor: VBLightColors.surface,
        elevation: VBElevation.high,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VBRadius.lg),
        ),
      ),
      // --- Divider ---
      dividerTheme: const DividerThemeData(
        color: VBLightColors.outlineVariant,
        thickness: 1,
        space: 0,
      ),
      // --- Icon ---
      iconTheme: const IconThemeData(
        color: VBLightColors.onSurfaceVariant,
        size: 24,
      ),
      // --- Switch ---
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return VBLightColors.primary;
          }
          return VBLightColors.onSurfaceVariant;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return VBLightColors.primaryMuted;
          }
          return VBLightColors.outline;
        }),
      ),
      // --- Snackbar ---
      snackBarTheme: SnackBarThemeData(
        backgroundColor: VBLightColors.surfaceDark,
        contentTextStyle: VBTypography.textTheme.bodyMedium?.copyWith(
          color: VBLightColors.onSurfaceDark,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VBRadius.sm),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      // --- Page Transitions ---
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  // ========================================================================
  // DARK THEME
  // ========================================================================
  static ThemeData get dark {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: VBDarkColors.primary,
      onPrimary: VBDarkColors.onPrimary,
      primaryContainer: VBDarkColors.primaryContainer,
      onPrimaryContainer: VBDarkColors.onSurface,
      secondary: VBDarkColors.secondary,
      onSecondary: VBDarkColors.onSurface,
      secondaryContainer: VBDarkColors.secondaryContainer,
      onSecondaryContainer: VBDarkColors.onSurface,
      surface: VBDarkColors.surface,
      onSurface: VBDarkColors.onSurface,
      onSurfaceVariant: VBDarkColors.onSurfaceVariant,
      error: VBDarkColors.error,
      onError: VBDarkColors.onError,
      outline: VBDarkColors.outline,
      outlineVariant: VBDarkColors.outlineVariant,
      shadow: Colors.transparent, // NO shadows in dark mode
      scrim: VBDarkColors.scrim,
      surfaceContainerHighest: VBDarkColors.surfaceVariant,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      textTheme: VBTypography.textTheme.apply(
        bodyColor: VBDarkColors.onSurface,
        displayColor: VBDarkColors.onSurface,
      ),
      scaffoldBackgroundColor: VBDarkColors.background,
      // --- App Bar ---
      appBarTheme: AppBarTheme(
        backgroundColor: VBDarkColors.background,
        foregroundColor: VBDarkColors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: VBTypography.textTheme.titleLarge?.copyWith(
          color: VBDarkColors.onSurface,
        ),
      ),
      // --- Cards (outline-based, NO shadows) ---
      cardTheme: CardThemeData(
        color: VBDarkColors.surface,
        elevation: VBElevation.none,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VBRadius.md),
          side: const BorderSide(color: VBDarkColors.outline, width: 1),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: VBSpacing.md,
          vertical: VBSpacing.sm,
        ),
      ),
      // --- Elevated Button ---
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: VBDarkColors.primary,
          foregroundColor: VBDarkColors.onPrimary,
          elevation: VBElevation.none,
          minimumSize: const Size(double.infinity, VBTouchTarget.primaryAction),
          padding: const EdgeInsets.symmetric(
            horizontal: VBSpacing.lg,
            vertical: VBSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(VBRadius.sm),
          ),
          textStyle: VBTypography.textTheme.labelLarge,
        ),
      ),
      // --- Outlined Button ---
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: VBDarkColors.primary,
          minimumSize: const Size(double.infinity, VBTouchTarget.minimum),
          padding: const EdgeInsets.symmetric(
            horizontal: VBSpacing.lg,
            vertical: VBSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(VBRadius.sm),
          ),
          side: const BorderSide(color: VBDarkColors.outline),
          textStyle: VBTypography.textTheme.labelLarge,
        ),
      ),
      // --- Text Button ---
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: VBDarkColors.primary,
          minimumSize: const Size(VBTouchTarget.minimum, VBTouchTarget.minimum),
          textStyle: VBTypography.textTheme.labelLarge,
        ),
      ),
      // --- Input Decoration ---
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: VBDarkColors.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: VBSpacing.md,
          vertical: VBSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(VBRadius.sm),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(VBRadius.sm),
          borderSide: const BorderSide(color: VBDarkColors.outline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(VBRadius.sm),
          borderSide: const BorderSide(color: VBDarkColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(VBRadius.sm),
          borderSide: const BorderSide(color: VBDarkColors.error, width: 1),
        ),
        hintStyle: VBTypography.textTheme.bodyLarge?.copyWith(
          color: VBDarkColors.onSurfaceVariant,
        ),
        labelStyle: VBTypography.textTheme.bodyMedium?.copyWith(
          color: VBDarkColors.onSurfaceVariant,
        ),
      ),
      // --- Bottom Navigation ---
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: VBDarkColors.surface,
        selectedItemColor: VBDarkColors.primary,
        unselectedItemColor: VBDarkColors.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: VBTypography.textTheme.labelSmall,
        unselectedLabelStyle: VBTypography.textTheme.labelSmall,
      ),
      // --- Navigation Bar ---
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: VBDarkColors.surface,
        indicatorColor: VBDarkColors.primaryContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 72,
        labelTextStyle: WidgetStatePropertyAll(
          VBTypography.textTheme.labelSmall,
        ),
      ),
      // --- Bottom Sheet ---
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: VBDarkColors.surfaceElevated,
        modalBackgroundColor: VBDarkColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(VBRadius.lg),
          ),
        ),
        elevation: VBElevation.none,
      ),
      // --- Dialog ---
      dialogTheme: DialogThemeData(
        backgroundColor: VBDarkColors.surfaceElevated,
        elevation: VBElevation.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VBRadius.lg),
          side: const BorderSide(color: VBDarkColors.outline, width: 1),
        ),
      ),
      // --- Divider ---
      dividerTheme: const DividerThemeData(
        color: VBDarkColors.outlineVariant,
        thickness: 1,
        space: 0,
      ),
      // --- Icon ---
      iconTheme: const IconThemeData(
        color: VBDarkColors.onSurfaceVariant,
        size: 24,
      ),
      // --- Switch ---
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return VBDarkColors.primary;
          }
          return VBDarkColors.onSurfaceVariant;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return VBDarkColors.primaryMuted;
          }
          return VBDarkColors.outline;
        }),
      ),
      // --- Snackbar ---
      snackBarTheme: SnackBarThemeData(
        backgroundColor: VBDarkColors.surfaceElevated,
        contentTextStyle: VBTypography.textTheme.bodyMedium?.copyWith(
          color: VBDarkColors.onSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VBRadius.sm),
          side: const BorderSide(color: VBDarkColors.outline, width: 1),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      // --- Page Transitions ---
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
