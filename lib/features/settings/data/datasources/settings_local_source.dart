import '../../../../core/database/database_helper.dart';
import '../../../../core/storage/shared_prefs.dart';
import '../../domain/models/settings_model.dart';

/// SettingsLocalSource handles settings persistence in SQLite and syncs with SharedPreferences.
class SettingsLocalSource {
  final DatabaseHelper _dbHelper;
  final SharedPrefs _sharedPrefs;

  SettingsLocalSource(this._dbHelper, this._sharedPrefs);

  /// Loads settings by checking SQLite first, falling back to SharedPreferences.
  SettingsModel loadSettings() {
    final Map<String, String> map = {};
    
    try {
      final results = _dbHelper.select('SELECT * FROM settings;');
      for (final row in results) {
        final key = row['key'] as String;
        final value = row['value'] as String;
        map[key] = value;
      }
    } catch (_) {
      // Fallback if DB is not initialized yet
    }

    // Sync missing keys from SharedPreferences cache
    final defaultSettings = SettingsModel.defaults().toMap();
    for (final key in defaultSettings.keys) {
      if (!map.containsKey(key)) {
        final cached = _sharedPrefs.getString(key, '');
        if (cached.isNotEmpty) {
          map[key] = cached;
        } else {
          map[key] = defaultSettings[key]!;
        }
      }
    }

    return SettingsModel.fromMap(map);
  }

  /// Saves a single setting option.
  void saveSetting(String key, String value) {
    // 1. Save to SQLite
    try {
      _dbHelper.execute(
        'INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?);',
        [key, value],
      );
    } catch (_) {}

    // 2. Save to SharedPreferences cache
    _sharedPrefs.setString(key, value);
  }

  /// Clears settings database.
  void clearSettings() {
    try {
      _dbHelper.execute('DELETE FROM settings;');
    } catch (_) {}
    _sharedPrefs.clear();
  }
}
