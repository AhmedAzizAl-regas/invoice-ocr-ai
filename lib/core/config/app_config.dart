/// AppConfig defines project-wide configurations, constants, settings keys,
/// and API keys for the Cloud OCR engines and Large Language Models.
class AppConfig {
  AppConfig._();

  // Settings SharedPreferences & SQLite Keys
  static const String keyLanguage = 'settings_language';
  static const String keyThemeMode = 'settings_theme_mode';
  static const String keyPrimaryColor = 'settings_primary_color';
  static const String keyFontFamily = 'settings_font_family';
  static const String keyFontSizeFactor = 'settings_font_size_factor';
  static const String keyDateFormat = 'settings_date_format';
  static const String keyTimeFormat = 'settings_time_format';
  static const String keyDefaultCurrency = 'settings_default_currency';

  // API Configurations (Fallback Cloud Services)
  // These can be populated via environment variables or loaded from the database dynamically.
  static String googleVisionApiKey = const String.fromEnvironment(
    'GOOGLE_VISION_API_KEY',
    defaultValue: '',
  );

  static String openaiApiKey = const String.fromEnvironment(
    'OPENAI_API_KEY',
    defaultValue: '',
  );
  static String openaiModelName = const String.fromEnvironment(
    'OPENAI_MODEL_NAME',
    defaultValue: 'gpt-4o-mini',
  );

  static String geminiApiKey = const String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );
  static String geminiModelName = const String.fromEnvironment(
    'GEMINI_MODEL_NAME',
    defaultValue: 'gemini-3.5-flash',
  );

  // OCR Quality Thresholds
  // If the OCR confidence falls below this threshold, the pipeline cascades to the next stage.
  static const double confidenceThresholdExcellent =
      0.85; // Google ML Kit target
  static const double confidenceThresholdGood = 0.70; // Tesseract target

  // Default values
  static const String defaultLanguage = 'ar'; // Arabic by default
  static const String defaultThemeMode = 'system';
  static const String defaultPrimaryColor = 'yellow';
  static const String defaultFontFamily = 'Cairo';
  static const double defaultFontSizeFactor = 1.0;
  static const String defaultDateFormat =
      'both'; // 'gregorian', 'hijri', or 'both'
  static const String defaultTimeFormat = '12h'; // '12h' or '24h'
  static const String defaultCurrencyCode = 'SAR'; // default SAR Saudi Riyal
}
