import 'package:esketit_music_app/unassigned_layer/key_value_recent_search_queries_storage.dart';
import 'package:esketit_music_app/unassigned_layer/shared_preferences_key_value_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'stores deduplicated recent search queries capped to 10 items',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final storage = KeyValueRecentSearchQueriesStorage(
        keyValueStorage: SharedPreferencesKeyValueStorage(
          preferences: preferences,
        ),
      );

      for (var index = 0; index < 11; index++) {
        await storage.saveRecentSearchQuery('query $index');
      }
      final storedQueries = await storage.saveRecentSearchQuery('query 5');

      expect(storedQueries, const [
        'query 5',
        'query 10',
        'query 9',
        'query 8',
        'query 7',
        'query 6',
        'query 4',
        'query 3',
        'query 2',
        'query 1',
      ]);
    },
  );
}
