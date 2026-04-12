import 'dart:convert';

import 'package:esketit_music_app/key_value_storage/shared/key_value_storage.dart';
import 'package:esketit_music_app/use_case/catalog/recent_search_queries_storage.dart';

class KeyValueRecentSearchQueriesStorage implements RecentSearchQueriesStorage {
  KeyValueRecentSearchQueriesStorage({required KeyValueStorage keyValueStorage})
    : _keyValueStorage = keyValueStorage;

  static const String _recentSearchQueriesKey = 'catalog.recent_search_queries';
  static const int _maxRecentSearchQueriesCount = 10;

  final KeyValueStorage _keyValueStorage;

  @override
  Future<List<String>> getRecentSearchQueries() async {
    final storedValue = await _keyValueStorage.getString(
      _recentSearchQueriesKey,
    );
    if (storedValue == null || storedValue.isEmpty) {
      return const [];
    }

    final decodedValue = _tryDecodeRecentSearchQueries(storedValue);
    if (decodedValue == null) {
      return const [];
    }

    return decodedValue.whereType<String>().toList(growable: false);
  }

  @override
  Future<List<String>> saveRecentSearchQuery(String query) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      return getRecentSearchQueries();
    }

    final currentQueries = await getRecentSearchQueries();
    final nextQueries = [
      normalizedQuery,
      ...currentQueries.where(
        (currentQuery) => currentQuery != normalizedQuery,
      ),
    ].take(_maxRecentSearchQueriesCount).toList(growable: false);

    await _keyValueStorage.setString(
      _recentSearchQueriesKey,
      jsonEncode(nextQueries),
    );

    return nextQueries;
  }

  List<Object?>? _tryDecodeRecentSearchQueries(String value) {
    try {
      final decodedValue = jsonDecode(value);

      return decodedValue is List ? decodedValue : null;
    } catch (_) {
      return null;
    }
  }
}
