/// VisionBridge — Reusable Card Widget
///
/// Styled per the reference palette: outline-based in dark mode, subtle shadow in light.
library;

import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/dimensions.dart';

class VBCard extends StatelessWidget {
  const VBCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.semanticLabel,
    this.isDarkVariant = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final String? semanticLabel;

  /// If true, uses the dark surface (surfaceDark in light mode, surfaceElevated in dark mode).
  /// Useful for featured/hero cards like in the reference images.
  final bool isDarkVariant;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bgColor;
    Color borderColor;
    Color textColor;

    if (isDarkVariant) {
      bgColor = isDark ? VBDarkColors.surfaceElevated : VBLightColors.surfaceDark;
      borderColor = isDark ? VBDarkColors.outline : Colors.transparent;
      textColor = isDark ? VBDarkColors.onSurface : VBLightColors.onSurfaceDark;
    } else {
      bgColor = isDark ? VBDarkColors.surface : VBLightColors.surface;
      borderColor = isDark ? VBDarkColors.outline : VBLightColors.outline;
      textColor = isDark ? VBDarkColors.onSurface : VBLightColors.onSurface;
    }

    final card = Semantics(
      label: semanticLabel,
      child: AnimatedContainer(
        duration: VBDuration.normal,
        curve: VBCurves.standard,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(VBRadius.md),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: isDark
              ? [] // No shadows in dark mode
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        padding: padding ??
            const EdgeInsets.all(VBSpacing.md),
        child: DefaultTextStyle(
          style: TextStyle(color: textColor),
          child: IconTheme(
            data: IconThemeData(color: textColor),
            child: child,
          ),
        ),
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(VBRadius.md),
          child: card,
        ),
      );
    }

    return card;
  }
}
