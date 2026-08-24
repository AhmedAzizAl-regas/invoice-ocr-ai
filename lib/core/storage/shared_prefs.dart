import 'package:shared_preferences/shared_preferences.dart';

/// SharedPrefs manages key-value configurations for the application settings.
class SharedPrefs {
  final SharedPreferences _prefs;

  SharedPrefs(this._prefs);

  static Future<SharedPrefs> init() async {
    final prefs = await SharedPreferences.getInstance();
    return SharedPrefs(prefs);
  }

  String getString(String key, String defaultValue) {
    return _prefs.getString(key) ?? defaultValue;
  }

  Future<bool> setString(String key, String value) async {
    return await _prefs.setString(key, value);
  }

  double getDouble(String key, double defaultValue) {
    return _prefs.getDouble(key) ?? defaultValue;
  }

  Future<bool> setDouble(String key, double value) async {
    return await _prefs.setDouble(key, value);
  }

  bool getBool(String key, bool defaultValue) {
    return _prefs.getBool(key) ?? defaultValue;
  }

  Future<bool> setBool(String key, bool value) async {
    return await _prefs.setBool(key, value);
  }

  Future<bool> remove(String key) async {
    return await _prefs.remove(key);
  }

  Future<bool> clear() async {
    return await _prefs.clear();
  }
}
