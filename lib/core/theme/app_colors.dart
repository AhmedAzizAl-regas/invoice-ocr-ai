import 'package:flutter/material.dart';

/// AppColors holds basic color palette definitions.
class AppColors {
  AppColors._();

  // Core Palette Hex values
  static const Color primaryYellow = Color(
    0xFFFFD700,
  ); // Sleek modern gold/yellow
  static const Color secondaryRed = Color(0xFFE53935); // Deep alert red

  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color pureBlack = Color(0xFF0A0A0A); // Premium dark black

  // Secondary shades for borders, text, and dividers
  static const Color lightGrey = Color(0xFFF5F5F5);
  static const Color mediumGrey = Color(0xFF9E9E9E);
  static const Color darkGrey = Color(0xFF1E1E1E);
}

/// LightColors defines standard theme settings for light mode.
class LightColors {
  LightColors._();

  static const Color background = AppColors.pureWhite;
  static const Color surface = Color(0xFFF9F9F9);
  static const Color card = AppColors.pureWhite;
  static const Color textPrimary = AppColors.pureBlack;
  static const Color textSecondary = Color(0xFF555555);
  static const Color border = Color(0xFFE0E0E0);

  static const Color primaryButton = AppColors.primaryYellow;
  static const Color secondaryButton = AppColors.secondaryRed;
  static const Color icon = AppColors.pureBlack;
  static const Color iconAccent = AppColors.secondaryRed;
}

/// DarkColors defines standard theme settings for dark mode.
class DarkColors {
  DarkColors._();

  static const Color background = AppColors.pureBlack;
  static const Color surface = Color(0xFF121212);
  static const Color card = Color(0xFF1A1A1A);
  static const Color textPrimary = AppColors.pureWhite;
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color border = Color(0xFF2C2C2C);

  static const Color primaryButton = AppColors.primaryYellow;
  static const Color secondaryButton = AppColors.secondaryRed;
  static const Color icon = AppColors.pureWhite;
  static const Color iconAccent = AppColors.primaryYellow;
}
