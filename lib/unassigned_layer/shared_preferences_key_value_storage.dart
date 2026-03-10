import 'package:esketit_music_app/key_value_storage/shared/key_value_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesKeyValueStorage implements KeyValueStorage {
  SharedPreferencesKeyValueStorage({SharedPreferences? preferences})
    : _preferencesFuture = preferences == null
          ? SharedPreferences.getInstance()
          : Future.value(preferences);

  final Future<SharedPreferences> _preferencesFuture;

  @override
  Future<void> setString(String key, String value) async {
    final preferences = await _preferencesFuture;

    await preferences.setString(key, value);
  }

  @override
  Future<String?> getString(String key) async {
    final preferences = await _preferencesFuture;

    return preferences.getString(key);
  }
}
