abstract class KeyValueStorage {
  Future<void> setString(String key, String value);

  Future<String?> getString(String key);
}
