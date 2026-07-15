import 'package:esketit_music_app/key_value_storage/shared/key_value_storage.dart';
import 'package:esketit_music_app/use_case/settings/app_locale.dart';
import 'package:esketit_music_app/use_case/settings/app_theme_mode.dart';
import 'package:esketit_music_app/use_case/settings/author_albums_display_mode.dart';
import 'package:esketit_music_app/use_case/settings/settings_storage.dart';

class KeyValueSettingsStorage implements SettingsStorage {
  KeyValueSettingsStorage({required KeyValueStorage keyValueStorage})
    : _keyValueStorage = keyValueStorage;

  static const String _serverUriKey = 'settings.server_uri';
  static const String _localeKey = 'settings.locale';
  static const String _themeModeKey = 'settings.theme_mode';
  static const String _useTrackAlbumCoverColorSchemeSeedKey =
      'settings.use_track_album_cover_color_scheme_seed';
  static const String _authorAlbumsDisplayModeKey =
      'settings.author_albums_display_mode';
  static const String _autoLocaleStorageValue = 'auto';
  static const String _lightThemeModeStorageValue = 'light';
  static const String _darkThemeModeStorageValue = 'dark';
  static const String _autoThemeModeStorageValue = 'auto';
  static const String _trueStorageValue = 'true';
  static const String _falseStorageValue = 'false';
  static const String _expandedAuthorAlbumsDisplayModeStorageValue = 'expanded';
  static const String _compactAuthorAlbumsDisplayModeStorageValue = 'compact';

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

  @override
  Future<AppThemeMode?> getThemeMode() async {
    final themeModeStorageValue = await _keyValueStorage.getString(
      _themeModeKey,
    );
    if (themeModeStorageValue == null || themeModeStorageValue.isEmpty) {
      return null;
    }

    return switch (themeModeStorageValue) {
      _lightThemeModeStorageValue => AppThemeMode.light,
      _darkThemeModeStorageValue => AppThemeMode.dark,
      _ => AppThemeMode.auto,
    };
  }

  @override
  Future<void> setThemeMode(AppThemeMode themeMode) {
    return _keyValueStorage.setString(_themeModeKey, switch (themeMode) {
      AppThemeMode.light => _lightThemeModeStorageValue,
      AppThemeMode.dark => _darkThemeModeStorageValue,
      AppThemeMode.auto => _autoThemeModeStorageValue,
    });
  }

  @override
  Future<bool?> getUseTrackAlbumCoverColorSchemeSeed() async {
    final storageValue = await _keyValueStorage.getString(
      _useTrackAlbumCoverColorSchemeSeedKey,
    );
    if (storageValue == null || storageValue.isEmpty) {
      return null;
    }

    return switch (storageValue) {
      _trueStorageValue => true,
      _falseStorageValue => false,
      _ => null,
    };
  }

  @override
  Future<void> setUseTrackAlbumCoverColorSchemeSeed(
    bool useTrackAlbumCoverColorSchemeSeed,
  ) {
    return _keyValueStorage.setString(
      _useTrackAlbumCoverColorSchemeSeedKey,
      useTrackAlbumCoverColorSchemeSeed
          ? _trueStorageValue
          : _falseStorageValue,
    );
  }

  @override
  Future<AuthorAlbumsDisplayMode?> getAuthorAlbumsDisplayMode() async {
    final displayModeStorageValue = await _keyValueStorage.getString(
      _authorAlbumsDisplayModeKey,
    );
    if (displayModeStorageValue == null || displayModeStorageValue.isEmpty) {
      return null;
    }

    return switch (displayModeStorageValue) {
      _expandedAuthorAlbumsDisplayModeStorageValue =>
        AuthorAlbumsDisplayMode.expanded,
      _compactAuthorAlbumsDisplayModeStorageValue =>
        AuthorAlbumsDisplayMode.compact,
      _ => null,
    };
  }

  @override
  Future<void> setAuthorAlbumsDisplayMode(AuthorAlbumsDisplayMode displayMode) {
    return _keyValueStorage.setString(
      _authorAlbumsDisplayModeKey,
      switch (displayMode) {
        AuthorAlbumsDisplayMode.expanded =>
          _expandedAuthorAlbumsDisplayModeStorageValue,
        AuthorAlbumsDisplayMode.compact =>
          _compactAuthorAlbumsDisplayModeStorageValue,
      },
    );
  }
}
