import 'package:flutter/material.dart';

import 'app_colors.dart';

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.night,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.gold,
      onPrimary: AppColors.onGold,
      surface: AppColors.nightPanel,
      onSurface: AppColors.text,
    ),
    textTheme: ThemeData.dark().textTheme.apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.nightPanel,
      hintStyle: const TextStyle(color: AppColors.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.nightBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.nightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.gold),
      ),
    ),
  );
}
