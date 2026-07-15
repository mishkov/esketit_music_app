import 'package:esketit_music_app/use_case/settings/app_locale.dart';
import 'package:esketit_music_app/use_case/settings/app_theme_mode.dart';
import 'package:esketit_music_app/use_case/settings/author_albums_display_mode.dart';

abstract class SettingsStorage {
  Future<Uri?> getServerUri();

  Future<void> setServerUri(Uri uri);

  Future<AppLocale?> getLocale();

  Future<void> setLocale(AppLocale? locale);

  Future<AppThemeMode?> getThemeMode();

  Future<void> setThemeMode(AppThemeMode themeMode);

  Future<bool?> getUseTrackAlbumCoverColorSchemeSeed();

  Future<void> setUseTrackAlbumCoverColorSchemeSeed(
    bool useTrackAlbumCoverColorSchemeSeed,
  );

  Future<AuthorAlbumsDisplayMode?> getAuthorAlbumsDisplayMode();

  Future<void> setAuthorAlbumsDisplayMode(AuthorAlbumsDisplayMode displayMode);
}
