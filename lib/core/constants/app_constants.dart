/// AppConstants encapsulates immutable application parameters, database configurations,
/// asset references, and layout boundaries.
class AppConstants {
  AppConstants._();

  // Database Specifications
  static const String databaseName = 'invoice_ocr_ai.db';
  static const int databaseVersion = 1;

  // Localizations Cache Key
  static const String defaultLocale = 'ar';
  static const List<String> supportedLanguages = ['ar', 'en'];

  // App Fonts Options
  static const List<String> availableFonts = ['Cairo', 'Tajawal', 'Inter', 'Outfit'];

  // Color Accent Schemes
  static const List<String> availableColors = ['yellow', 'red', 'black', 'white'];

  // Layout Constraints & Breakpoints
  static const double mobileMaxBreakpoint = 599.0;
  static const double tabletMaxBreakpoint = 1023.0;

  // Assets Brand Path Resources
  static const String logoFullPath = 'assets/brand/logo.png';
  static const String logoIconPath = 'assets/brand/logo_icon.png';
  static const String splashScreenPath = 'assets/brand/splash_screen.png';
}
