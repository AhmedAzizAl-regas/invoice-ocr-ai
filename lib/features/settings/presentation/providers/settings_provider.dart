import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import '../../domain/models/settings_model.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../../../core/config/app_config.dart';

/// SettingsNotifier manages the state of localized and layout configuration properties.
class SettingsNotifier extends StateNotifier<SettingsModel> {
  final SettingsRepository _repository;

  SettingsNotifier(this._repository) : super(SettingsModel.defaults()) {
    loadSettings();
  }

  /// Reloads settings from database/preferences.
  void loadSettings() {
    state = _repository.getSettings();
  }

  /// Updates settings properties.
  void _updateSetting(String key, String value, SettingsModel updatedModel) {
    _repository.saveSetting(key, value);
    state = updatedModel;
  }

  void changeLanguage(String lang) {
    _updateSetting(
      AppConfig.keyLanguage,
      lang,
      state.copyWith(language: lang),
    );
  }

  void changeThemeMode(String mode) {
    _updateSetting(
      AppConfig.keyThemeMode,
      mode,
      state.copyWith(themeMode: mode),
    );
  }

  void changePrimaryColor(String color) {
    _updateSetting(
      AppConfig.keyPrimaryColor,
      color,
      state.copyWith(primaryColor: color),
    );
  }

  void changeFontFamily(String font) {
    _updateSetting(
      AppConfig.keyFontFamily,
      font,
      state.copyWith(fontFamily: font),
    );
  }

  void changeFontSizeFactor(double factor) {
    _updateSetting(
      AppConfig.keyFontSizeFactor,
      factor.toString(),
      state.copyWith(fontSizeFactor: factor),
    );
  }

  void changeDateFormat(String format) {
    _updateSetting(
      AppConfig.keyDateFormat,
      format,
      state.copyWith(dateFormat: format),
    );
  }

  void changeTimeFormat(String format) {
    _updateSetting(
      AppConfig.keyTimeFormat,
      format,
      state.copyWith(timeFormat: format),
    );
  }

  void changeDefaultCurrency(String currency) {
    _updateSetting(
      AppConfig.keyDefaultCurrency,
      currency,
      state.copyWith(defaultCurrency: currency),
    );
  }

  void clearAllData() {
    _repository.clearSettings();
    state = SettingsModel.defaults();
  }
}

/// Riverpod provider to watch and read settings state.
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsModel>((ref) {
  final repo = GetIt.I<SettingsRepository>();
  return SettingsNotifier(repo);
});
