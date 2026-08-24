import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AppTextStyles provides text styling helpers mapping both Arabic and English fonts.
class AppTextStyles {
  AppTextStyles._();

  /// Gets the primary font family based on locale.
  static String getFontFamily(String locale, {String? customFont}) {
    if (customFont != null && customFont.isNotEmpty) {
      return customFont;
    }
    return locale == 'ar' ? 'Cairo' : 'Outfit';
  }

  /// Builds a complete TextTheme based on locale, font family, and scale factor.
  static TextTheme getTextTheme({
    required String locale,
    double scaleFactor = 1.0,
    String? customFont,
    required Color color,
  }) {
    final family = getFontFamily(locale, customFont: customFont);
    
    // Choose base generator based on font family
    TextStyle buildStyle(double size, FontWeight weight, double height, Color textCol) {
      final baseStyle = (family == 'Cairo')
          ? GoogleFonts.cairo(fontSize: size * scaleFactor, fontWeight: weight, height: height, color: textCol)
          : (family == 'Tajawal')
              ? GoogleFonts.tajawal(fontSize: size * scaleFactor, fontWeight: weight, height: height, color: textCol)
              : (family == 'Inter')
                  ? GoogleFonts.inter(fontSize: size * scaleFactor, fontWeight: weight, height: height, color: textCol)
                  : GoogleFonts.outfit(fontSize: size * scaleFactor, fontWeight: weight, height: height, color: textCol);
      return baseStyle;
    }

    return TextTheme(
      displayLarge: buildStyle(57, FontWeight.bold, 1.1, color),
      displayMedium: buildStyle(45, FontWeight.bold, 1.15, color),
      displaySmall: buildStyle(36, FontWeight.bold, 1.2, color),
      
      headlineLarge: buildStyle(32, FontWeight.w600, 1.25, color),
      headlineMedium: buildStyle(28, FontWeight.w600, 1.3, color),
      headlineSmall: buildStyle(24, FontWeight.w600, 1.35, color),
      
      titleLarge: buildStyle(22, FontWeight.w500, 1.25, color),
      titleMedium: buildStyle(16, FontWeight.w500, 1.35, color),
      titleSmall: buildStyle(14, FontWeight.w500, 1.4, color),
      
      bodyLarge: buildStyle(16, FontWeight.normal, 1.5, color),
      bodyMedium: buildStyle(14, FontWeight.normal, 1.45, color),
      bodySmall: buildStyle(12, FontWeight.normal, 1.4, color),
      
      labelLarge: buildStyle(14, FontWeight.w600, 1.3, color),
      labelMedium: buildStyle(12, FontWeight.w600, 1.3, color),
      labelSmall: buildStyle(11, FontWeight.w500, 1.3, color),
    );
  }

  // Quick single styles for ad-hoc custom fonts
  static TextStyle getDisplay({required String locale, double scale = 1.0, required Color color}) =>
      getTextTheme(locale: locale, scaleFactor: scale, color: color).displayMedium!;
  
  static TextStyle getHeadline({required String locale, double scale = 1.0, required Color color}) =>
      getTextTheme(locale: locale, scaleFactor: scale, color: color).headlineSmall!;

  static TextStyle getTitle({required String locale, double scale = 1.0, required Color color}) =>
      getTextTheme(locale: locale, scaleFactor: scale, color: color).titleMedium!;

  static TextStyle getBody({required String locale, double scale = 1.0, required Color color}) =>
      getTextTheme(locale: locale, scaleFactor: scale, color: color).bodyMedium!;

  static TextStyle getLabel({required String locale, double scale = 1.0, required Color color}) =>
      getTextTheme(locale: locale, scaleFactor: scale, color: color).labelMedium!;
}
