/// VisionBridge Typography Scale
///
/// Uses Montserrat (Google Fonts) — high-impact geometric sans-serif (Gotham aesthetic)
/// featuring crisp geometry, bold weights (w700/w800), and max legibility for blind & low-vision UX.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class VBTypography {
  static TextTheme get textTheme => TextTheme(
        // Display styles (Gotham extra-bold geometric display)
        displayLarge: _montserrat(32, FontWeight.w800, 1.20, letterSpacing: -0.8),
        displayMedium: _montserrat(28, FontWeight.w800, 1.22, letterSpacing: -0.6),
        displaySmall: _montserrat(24, FontWeight.w700, 1.25, letterSpacing: -0.4),

        // Headline & Title styles (Bold, clean geometric hierarchy like "BROOKLYN")
        headlineLarge: _montserrat(22, FontWeight.w700, 1.28, letterSpacing: -0.3),
        headlineMedium: _montserrat(20, FontWeight.w700, 1.30, letterSpacing: -0.2),
        headlineSmall: _montserrat(18, FontWeight.w700, 1.32, letterSpacing: 0.0),

        titleLarge: _montserrat(18, FontWeight.w700, 1.30, letterSpacing: 0.0),
        titleMedium: _montserrat(16, FontWeight.w600, 1.28, letterSpacing: 0.1),
        titleSmall: _montserrat(14, FontWeight.w600, 1.30, letterSpacing: 0.1),

        // Body styles (Montserrat medium/regular for high legibility reading)
        bodyLarge: _montserrat(16, FontWeight.w500, 1.45, letterSpacing: 0.1),
        bodyMedium: _montserrat(14, FontWeight.w500, 1.40, letterSpacing: 0.1),
        bodySmall: _montserrat(12, FontWeight.w500, 1.35, letterSpacing: 0.2),

        // Label & Button styles (Bold, geometric UI actions)
        labelLarge: _montserrat(16, FontWeight.w700, 1.25, letterSpacing: 0.3),
        labelMedium: _montserrat(14, FontWeight.w600, 1.28, letterSpacing: 0.2),
        labelSmall: _montserrat(12, FontWeight.w600, 1.30, letterSpacing: 0.2),
      );

  static TextStyle _montserrat(
    double size,
    FontWeight weight,
    double heightMultiplier, {
    double letterSpacing = 0.0,
  }) {
    return GoogleFonts.montserrat(
      fontSize: size,
      fontWeight: weight,
      height: heightMultiplier,
      letterSpacing: letterSpacing,
    );
  }
}

