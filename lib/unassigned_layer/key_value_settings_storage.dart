import 'package:esketit_music_app/key_value_storage/shared/key_value_storage.dart';
import 'package:esketit_music_app/use_case/settings/app_locale.dart';
import 'package:esketit_music_app/use_case/settings/settings_storage.dart';

class KeyValueSettingsStorage implements SettingsStorage {
  KeyValueSettingsStorage({required KeyValueStorage keyValueStorage})
    : _keyValueStorage = keyValueStorage;

  static const String _serverUriKey = 'settings.server_uri';
  static const String _localeKey = 'settings.locale';
  static const String _autoLocaleStorageValue = 'auto';

  final KeyValueStorage _keyValueStorage;

  @override
  Future<Uri?> getServerUri() async {
    final serverUriString = await _keyValueStorage.getString(_serverUriKey);
    if (serverUriString == null || serverUriString.isEmpty) {
      return null;
    }

    return Uri.tryParse(serverUriString);
  }

  @override
  Future<void> setServerUri(Uri uri) {
    return _keyValueStorage.setString(_serverUriKey, uri.toString());
  }

  @override
  Future<AppLocale?> getLocale() async {
    final localeCode = await _keyValueStorage.getString(_localeKey);
    if (localeCode == null ||
        localeCode.isEmpty ||
        localeCode == _autoLocaleStorageValue) {
      return null;
    }

    return AppLocale.fromLanguageCode(localeCode);
  }

  @override
  Future<void> setLocale(AppLocale? locale) {
    return _keyValueStorage.setString(
      _localeKey,
      locale?.languageCode ?? _autoLocaleStorageValue,
    );
  }
}
