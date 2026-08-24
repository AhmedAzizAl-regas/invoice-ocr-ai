import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// AppTheme aggregates all visual parameters of the system into a single file.
/// All buttons, inputs, dialogs, chips, cards, tables, and spacing variables are accessed from here.
class AppTheme {
  AppTheme._();

  // Spacing System
  static const double spaceXS = 4.0;
  static const double spaceS = 8.0;
  static const double spaceM = 16.0;
  static const double spaceL = 24.0;
  static const double spaceXL = 32.0;
  static const double spaceXXL = 48.0;

  // Border Radius constants
  static const double radiusS = 4.0;
  static const double radiusM = 8.0;
  static const double radiusL = 12.0;
  static const double radiusXL = 16.0;
  static const double radiusXXL = 24.0;

  // Shadows
  static List<BoxShadow> getLightShadow() => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> getDarkShadow() => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.3),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  // Theme Generator
  static ThemeData buildTheme({
    required bool isDark,
    required String locale,
    double fontSizeFactor = 1.0,
    String? customFont,
  }) {
    final Color background = isDark
        ? DarkColors.background
        : LightColors.background;
    final Color surface = isDark ? DarkColors.surface : LightColors.surface;
    final Color card = isDark ? DarkColors.card : LightColors.card;
    final Color textPrimary = isDark
        ? DarkColors.textPrimary
        : LightColors.textPrimary;
    final Color textSecondary = isDark
        ? DarkColors.textSecondary
        : LightColors.textSecondary;
    final Color border = isDark ? DarkColors.border : LightColors.border;

    final baseTextTheme = AppTextStyles.getTextTheme(
      locale: locale,
      scaleFactor: fontSizeFactor,
      customFont: customFont,
      color: textPrimary,
    );

    final colorScheme = ColorScheme(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: AppColors.primaryYellow,
      onPrimary: AppColors.pureBlack,
      secondary: AppColors.secondaryRed,
      onSecondary: AppColors.pureWhite,
      error: AppColors.secondaryRed,
      onError: AppColors.pureWhite,
      surface: surface,
      onSurface: textPrimary,
      surfaceContainerHighest: card,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      primaryColor: AppColors.primaryYellow,
      dividerColor: border,
      textTheme: baseTextTheme,
      cardColor: card,

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: baseTextTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: card,
        elevation: isDark ? 2 : 4,
        shadowColor: isDark
            ? Colors.transparent
            : Colors.black.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusL),
          side: BorderSide(color: border, width: isDark ? 1.0 : 0.0),
        ),
      ),

      // Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryYellow,
          foregroundColor: AppColors.pureBlack,
          elevation: 2,
          padding: const EdgeInsets.symmetric(
            horizontal: spaceL,
            vertical: spaceM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusM),
          ),
          textStyle: baseTextTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: BorderSide(color: border, width: 1.5),
          padding: const EdgeInsets.symmetric(
            horizontal: spaceL,
            vertical: spaceM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusM),
          ),
          textStyle: baseTextTheme.labelLarge,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.secondaryRed,
          padding: const EdgeInsets.symmetric(
            horizontal: spaceM,
            vertical: spaceS,
          ),
          textStyle: baseTextTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryYellow,
        foregroundColor: AppColors.pureBlack,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXL),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF141414) : const Color(0xFFF9F9F9),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spaceM,
          vertical: spaceM,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(
            color: AppColors.primaryYellow,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(color: AppColors.secondaryRed),
        ),
        labelStyle: baseTextTheme.bodyMedium?.copyWith(color: textSecondary),
        hintStyle: baseTextTheme.bodyMedium?.copyWith(
          color: textSecondary.withValues(alpha: 0.7),
        ),
      ),

      // Navigation Bar Theme
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: AppColors.primaryYellow.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return baseTextTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.primaryYellow : AppColors.pureBlack,
            );
          }
          return baseTextTheme.labelMedium?.copyWith(color: textSecondary);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color: isDark ? AppColors.primaryYellow : AppColors.pureBlack,
            );
          }
          return IconThemeData(color: textSecondary);
        }),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXL),
        ),
        titleTextStyle: baseTextTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: baseTextTheme.bodyMedium,
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: card,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXXL)),
        ),
        elevation: 8,
      ),

      // SnackBar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? Colors.white : Colors.black,
        contentTextStyle: baseTextTheme.bodyMedium?.copyWith(
          color: isDark ? Colors.black : Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
        ),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: isDark
            ? const Color(0xFF1E1E1E)
            : const Color(0xFFF0F0F0),
        disabledColor: Colors.transparent,
        selectedColor: AppColors.primaryYellow.withValues(alpha: 0.3),
        secondarySelectedColor: AppColors.secondaryRed.withValues(alpha: 0.3),
        padding: const EdgeInsets.symmetric(
          horizontal: spaceS,
          vertical: spaceXS,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusS),
        ),
        labelStyle: baseTextTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),

      // Data Table Theme
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(
          isDark ? const Color(0xFF1F1F1F) : const Color(0xFFEEEEEE),
        ),
        dataRowColor: WidgetStateProperty.all(
          isDark ? Colors.transparent : Colors.transparent,
        ),
        headingTextStyle: baseTextTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        dataTextStyle: baseTextTheme.bodyMedium,
        dividerThickness: 1.0,
        horizontalMargin: spaceM,
      ),
    );
  }
}
