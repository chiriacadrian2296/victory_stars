import 'package:flutter/material.dart';

import 'app_colors.dart';

ThemeData buildAppTheme(Brightness brightness) {
  final palette = brightness == Brightness.dark ? AppColors.dark : AppColors.light;

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: palette.night,
    colorScheme: brightness == Brightness.dark
        ? ColorScheme.dark(
            primary: palette.gold,
            onPrimary: palette.onGold,
            surface: palette.nightPanel,
            onSurface: palette.text,
          )
        : ColorScheme.light(
            primary: palette.gold,
            onPrimary: palette.onGold,
            surface: palette.nightPanel,
            onSurface: palette.text,
          ),
    textTheme: ThemeData(brightness: brightness).textTheme.apply(
          bodyColor: palette.text,
          displayColor: palette.text,
        ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.nightPanel,
      hintStyle: TextStyle(color: palette.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: palette.nightBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: palette.nightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: palette.gold),
      ),
    ),
    // Material 3's default (teal, from an unset colorScheme.secondary) shows
    // through on the time picker's AM/PM and hour/minute toggles otherwise —
    // themed explicitly here so any time/date picker anywhere in the app
    // stays on-brand, not just the one screen that first surfaced it.
    timePickerTheme: TimePickerThemeData(
      backgroundColor: palette.nightPanel,
      hourMinuteColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? palette.gold.withValues(alpha: 0.2)
            : palette.night,
      ),
      hourMinuteTextColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.selected) ? palette.gold : palette.text,
      ),
      dayPeriodColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.selected) ? palette.gold : palette.nightPanel,
      ),
      dayPeriodTextColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.selected) ? palette.onGold : palette.muted,
      ),
      dayPeriodBorderSide: BorderSide(color: palette.nightBorder),
      dialHandColor: palette.gold,
      dialBackgroundColor: palette.night,
      dialTextColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.selected) ? palette.onGold : palette.text,
      ),
      entryModeIconColor: palette.muted,
    ),
    // Same reasoning as timePickerTheme above: keep the date picker (used
    // when backdating a star) on-brand instead of Material 3's default teal.
    datePickerTheme: DatePickerThemeData(
      backgroundColor: palette.nightPanel,
      headerBackgroundColor: palette.gold,
      headerForegroundColor: palette.onGold,
      // Selected wins over "is today" — otherwise the day number renders
      // gold-on-gold (invisible) when today happens to be the selected day,
      // since the circle fill already switches to gold once selected.
      todayForegroundColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.selected) ? palette.onGold : palette.gold,
      ),
      todayBorder: BorderSide(color: palette.gold),
      dayForegroundColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.selected) ? palette.onGold : palette.text,
      ),
      dayBackgroundColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.selected) ? palette.gold : Colors.transparent,
      ),
      yearForegroundColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.selected) ? palette.onGold : palette.text,
      ),
      yearBackgroundColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.selected) ? palette.gold : Colors.transparent,
      ),
    ),
    extensions: [palette],
  );
}
