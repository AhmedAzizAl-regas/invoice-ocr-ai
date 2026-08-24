import '../../domain/repositories/settings_repository.dart';
import '../../domain/models/settings_model.dart';
import '../datasources/settings_local_source.dart';

/// SettingsRepositoryImpl delegates updates and queries to SettingsLocalSource.
class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalSource _localSource;

  SettingsRepositoryImpl(this._localSource);

  @override
  SettingsModel getSettings() {
    return _localSource.loadSettings();
  }

  @override
  void saveSetting(String key, String value) {
    _localSource.saveSetting(key, value);
  }

  @override
  @override
  void clearSettings() {
    _localSource.clearSettings();
  }
}
