import 'package:flutter/material.dart';

/// Colors from the validated React prototype's dark "night sky" palette.
class AppColors {
  const AppColors._();

  static const night = Color(0xFF0D1220);
  static const nightPanel = Color(0xFF161D30);
  static const nightBorder = Color(0xFF232C44);
  static const gold = Color(0xFFF2B84B);
  static const goldDim = Color(0xFFA67F2E);
  static const text = Color(0xFFF4F1E8);
  static const muted = Color(0xFF7C8699);

  /// Text/icon color used on top of solid gold surfaces (buttons, FAB).
  static const onGold = Color(0xFF241A04);

  /// A deeper, more intimate variant of [night], used for the reflection
  /// screens (crisis intro + star reader). Kept close in hue to [night]
  /// rather than the prototype's purple, so it reads as "the same sky, at
  /// its darkest" instead of an unrelated palette.
  static const crisisGradientCenter = Color(0xFF1C2747);
  static const crisisGradientMid = Color(0xFF10162B);
  static const crisisGradientOuter = Color(0xFF05070D);
  static const crisisMuted = Color(0xFFB7C2E0);

  static const crisisGradient = RadialGradient(
    center: Alignment(0, -0.6),
    radius: 1.2,
    colors: [crisisGradientCenter, crisisGradientMid, crisisGradientOuter],
    stops: [0.0, 0.55, 1.0],
  );
}
