abstract class RecentSearchQueriesStorage {
  Future<List<String>> getRecentSearchQueries();

  Future<List<String>> saveRecentSearchQuery(String query);
}
