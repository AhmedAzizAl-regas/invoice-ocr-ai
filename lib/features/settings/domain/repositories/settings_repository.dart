import '../models/settings_model.dart';

/// SettingsRepository manages application configurations loading and updates.
abstract class SettingsRepository {
  /// Loads all settings.
  SettingsModel getSettings();

  /// Updates a single key-value configuration.
  void saveSetting(String key, String value);

  /// Clears configurations.
  void clearSettings();
}
