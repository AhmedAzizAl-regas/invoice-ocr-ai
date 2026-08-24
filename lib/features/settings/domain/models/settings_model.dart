import '../../../../core/config/app_config.dart';

/// SettingsModel holds the personalized configurations for the app instance.
class SettingsModel {
  final String language;
  final String themeMode;
  final String primaryColor;
  final String fontFamily;
  final double fontSizeFactor;
  final String dateFormat;
  final String timeFormat;
  final String defaultCurrency;

  SettingsModel({
    required this.language,
    required this.themeMode,
    required this.primaryColor,
    required this.fontFamily,
    required this.fontSizeFactor,
    required this.dateFormat,
    required this.timeFormat,
    required this.defaultCurrency,
  });

  /// Factory constructors for default values.
  factory SettingsModel.defaults() {
    return SettingsModel(
      language: AppConfig.defaultLanguage,
      themeMode: AppConfig.defaultThemeMode,
      primaryColor: AppConfig.defaultPrimaryColor,
      fontFamily: AppConfig.defaultFontFamily,
      fontSizeFactor: AppConfig.defaultFontSizeFactor,
      dateFormat: AppConfig.defaultDateFormat,
      timeFormat: AppConfig.defaultTimeFormat,
      defaultCurrency: AppConfig.defaultCurrencyCode,
    );
  }

  /// Factory constructor to parse settings values from a Key-Value Map.
  factory SettingsModel.fromMap(Map<String, String> map) {
    return SettingsModel(
      language: map[AppConfig.keyLanguage] ?? AppConfig.defaultLanguage,
      themeMode: map[AppConfig.keyThemeMode] ?? AppConfig.defaultThemeMode,
      primaryColor: map[AppConfig.keyPrimaryColor] ?? AppConfig.defaultPrimaryColor,
      fontFamily: map[AppConfig.keyFontFamily] ?? AppConfig.defaultFontFamily,
      fontSizeFactor: double.tryParse(map[AppConfig.keyFontSizeFactor] ?? '') ?? AppConfig.defaultFontSizeFactor,
      dateFormat: map[AppConfig.keyDateFormat] ?? AppConfig.defaultDateFormat,
      timeFormat: map[AppConfig.keyTimeFormat] ?? AppConfig.defaultTimeFormat,
      defaultCurrency: map[AppConfig.keyDefaultCurrency] ?? AppConfig.defaultCurrencyCode,
    );
  }

  /// Converts the configuration model to a Key-Value Map.
  Map<String, String> toMap() {
    return {
      AppConfig.keyLanguage: language,
      AppConfig.keyThemeMode: themeMode,
      AppConfig.keyPrimaryColor: primaryColor,
      AppConfig.keyFontFamily: fontFamily,
      AppConfig.keyFontSizeFactor: fontSizeFactor.toString(),
      AppConfig.keyDateFormat: dateFormat,
      AppConfig.keyTimeFormat: timeFormat,
      AppConfig.keyDefaultCurrency: defaultCurrency,
    };
  }

  /// Copy helper
  SettingsModel copyWith({
    String? language,
    String? themeMode,
    String? primaryColor,
    String? fontFamily,
    double? fontSizeFactor,
    String? dateFormat,
    String? timeFormat,
    String? defaultCurrency,
  }) {
    return SettingsModel(
      language: language ?? this.language,
      themeMode: themeMode ?? this.themeMode,
      primaryColor: primaryColor ?? this.primaryColor,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSizeFactor: fontSizeFactor ?? this.fontSizeFactor,
      dateFormat: dateFormat ?? this.dateFormat,
      timeFormat: timeFormat ?? this.timeFormat,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
    );
  }
}
