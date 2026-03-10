abstract class SettingsStorage {
  Future<Uri?> getServerUri();

  Future<void> setServerUri(Uri uri);
}
