/// VisionBridge Spacing, Radius, and Elevation Tokens
///
/// 8dp base grid. Consistent, predictable, portable.
library;

import 'package:flutter/animation.dart';

abstract final class VBSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;
}

abstract final class VBRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double full = 9999.0;
}

abstract final class VBElevation {
  static const double none = 0.0;
  static const double low = 2.0;
  static const double medium = 4.0;
  static const double high = 8.0;
}

/// Minimum touch target sizes per platform guidelines.
/// Android: 48x48dp, iOS: 44x44pt. We use 48 as the universal minimum.
abstract final class VBTouchTarget {
  static const double minimum = 48.0;
  static const double sosButton = 72.0;
  static const double primaryAction = 56.0;
}

/// Animation durations for micro-interactions.
abstract final class VBDuration {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 350);
  static const Duration pageTransition = Duration(milliseconds: 300);
}

/// Standard animation curves.
abstract final class VBCurves {
  static const Curve standard = Curves.easeInOutCubic;
  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve bounce = Curves.elasticOut;
}
