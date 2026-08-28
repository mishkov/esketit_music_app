import 'package:esketit_music_app/domain/catalog_search_result.dart';

abstract class RecentSearchResultsStorage {
  Future<List<CatalogSearchResultItem>> getRecentSearchResults();

  Future<List<CatalogSearchResultItem>> saveRecentSearchResult(
    CatalogSearchResultItem result,
  );
}
