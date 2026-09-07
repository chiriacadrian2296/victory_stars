import 'package:flutter/material.dart';

/// The app's one color palette ([dark], the "night sky" look) — no light
/// mode; a daytime sky doesn't fit an app about lighting stars against a
/// dark backdrop. Still a [ThemeExtension] (access via `context.colors`
/// rather than the static constant directly) so every screen reads it the
/// same way regardless of whether that ever changes again.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.night,
    required this.nightPanel,
    required this.nightBorder,
    required this.gold,
    required this.goldDim,
    required this.text,
    required this.muted,
    required this.onGold,
    required this.danger,
    required this.crisisGradientCenter,
    required this.crisisGradientMid,
    required this.crisisGradientOuter,
    required this.crisisMuted,
  });

  final Color night;
  final Color nightPanel;
  final Color nightBorder;
  final Color gold;
  final Color goldDim;
  final Color text;
  final Color muted;

  /// Text/icon color used on top of solid gold surfaces (buttons, FAB).
  final Color onGold;

  /// Color for destructive actions (e.g. the reset-all-data button).
  final Color danger;

  /// A deeper/lighter variant of [night] used for the reflection screens
  /// (crisis intro + star reader) — "the same sky, at its most intimate".
  final Color crisisGradientCenter;
  final Color crisisGradientMid;
  final Color crisisGradientOuter;
  final Color crisisMuted;

  RadialGradient get crisisGradient => RadialGradient(
        center: const Alignment(0, -0.6),
        radius: 1.2,
        colors: [crisisGradientCenter, crisisGradientMid, crisisGradientOuter],
        stops: const [0.0, 0.55, 1.0],
      );

  static const dark = AppColors(
    night: Color(0xFF0D1220),
    nightPanel: Color(0xFF161D30),
    nightBorder: Color(0xFF232C44),
    gold: Color(0xFFF2B84B),
    goldDim: Color(0xFFA67F2E),
    text: Color(0xFFF4F1E8),
    muted: Color(0xFF7C8699),
    onGold: Color(0xFF241A04),
    danger: Color(0xFFE0574F),
    crisisGradientCenter: Color(0xFF1C2747),
    crisisGradientMid: Color(0xFF10162B),
    crisisGradientOuter: Color(0xFF05070D),
    crisisMuted: Color(0xFFB7C2E0),
  );

  @override
  AppColors copyWith({
    Color? night,
    Color? nightPanel,
    Color? nightBorder,
    Color? gold,
    Color? goldDim,
    Color? text,
    Color? muted,
    Color? onGold,
    Color? danger,
    Color? crisisGradientCenter,
    Color? crisisGradientMid,
    Color? crisisGradientOuter,
    Color? crisisMuted,
  }) {
    return AppColors(
      night: night ?? this.night,
      nightPanel: nightPanel ?? this.nightPanel,
      nightBorder: nightBorder ?? this.nightBorder,
      gold: gold ?? this.gold,
      goldDim: goldDim ?? this.goldDim,
      text: text ?? this.text,
      muted: muted ?? this.muted,
      onGold: onGold ?? this.onGold,
      danger: danger ?? this.danger,
      crisisGradientCenter: crisisGradientCenter ?? this.crisisGradientCenter,
      crisisGradientMid: crisisGradientMid ?? this.crisisGradientMid,
      crisisGradientOuter: crisisGradientOuter ?? this.crisisGradientOuter,
      crisisMuted: crisisMuted ?? this.crisisMuted,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      night: Color.lerp(night, other.night, t)!,
      nightPanel: Color.lerp(nightPanel, other.nightPanel, t)!,
      nightBorder: Color.lerp(nightBorder, other.nightBorder, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      goldDim: Color.lerp(goldDim, other.goldDim, t)!,
      text: Color.lerp(text, other.text, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      onGold: Color.lerp(onGold, other.onGold, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      crisisGradientCenter: Color.lerp(crisisGradientCenter, other.crisisGradientCenter, t)!,
      crisisGradientMid: Color.lerp(crisisGradientMid, other.crisisGradientMid, t)!,
      crisisGradientOuter: Color.lerp(crisisGradientOuter, other.crisisGradientOuter, t)!,
      crisisMuted: Color.lerp(crisisMuted, other.crisisMuted, t)!,
    );
  }
}

extension AppColorsX on BuildContext {
  // Falls back to `dark` rather than asserting non-null: on some devices the
  // very first post-launch frame can resolve Theme before the extension is
  // attached, and this is purely cosmetic for one frame — not worth a crash.
  AppColors get colors => Theme.of(this).extension<AppColors>() ?? AppColors.dark;
}
