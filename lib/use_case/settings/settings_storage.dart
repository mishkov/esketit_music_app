import 'package:esketit_music_app/use_case/settings/app_locale.dart';

abstract class SettingsStorage {
  Future<Uri?> getServerUri();

  Future<void> setServerUri(Uri uri);

  Future<AppLocale?> getLocale();

  Future<void> setLocale(AppLocale? locale);
}
