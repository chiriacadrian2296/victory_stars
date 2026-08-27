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
    extensions: [palette],
  );
}
