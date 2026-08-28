import 'package:esketit_music_app/domain/album.dart';
import 'package:esketit_music_app/domain/author.dart';
import 'package:esketit_music_app/domain/catalog_search_result.dart';
import 'package:esketit_music_app/domain/playlist.dart';
import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/domain/track_info/text_track_info.dart';
import 'package:esketit_music_app/unassigned_layer/http_file.dart';
import 'package:esketit_music_app/unassigned_layer/key_value_recent_search_results_storage.dart';
import 'package:esketit_music_app/unassigned_layer/shared_preferences_key_value_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('stores deduplicated recent results capped to 20 items', () async {
    final storage = await _createStorage();

    for (var index = 1; index <= 21; index++) {
      await storage.saveRecentSearchResult(
        CatalogSearchResultItem.author(
          Author(id: index, currentName: 'Author $index', photos: const []),
        ),
      );
    }
    final storedResults = await storage.saveRecentSearchResult(
      const CatalogSearchResultItem.author(
        Author(id: 6, currentName: 'Updated Author 6', photos: []),
      ),
    );

    expect(storedResults, hasLength(20));
    expect(storedResults.map((result) => result.author!.id), [
      6,
      21,
      20,
      19,
      18,
      17,
      16,
      15,
      14,
      13,
      12,
      11,
      10,
      9,
      8,
      7,
      5,
      4,
      3,
      2,
    ]);
    expect(storedResults.first.author!.currentName, 'Updated Author 6');
  });

  test('restores every catalog search result type', () async {
    final storage = await _createStorage();
    final results = _allResultTypes();

    for (final result in results.reversed) {
      await storage.saveRecentSearchResult(result);
    }

    expect(await storage.getRecentSearchResults(), results);
  });
}

Future<KeyValueRecentSearchResultsStorage> _createStorage() async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();

  return KeyValueRecentSearchResultsStorage(
    keyValueStorage: SharedPreferencesKeyValueStorage(preferences: preferences),
  );
}

List<CatalogSearchResultItem> _allResultTypes() {
  final author = Author(
    id: 52,
    currentName: 'FRIENDLY THUG 52 NGG',
    photos: const ['https://example.com/author.jpg'],
  );
  final album = Album(
    id: 10,
    title: 'Album',
    coverImage: HttpFile(uri: Uri.parse('https://example.com/album.jpg')),
    authorIds: [author.id],
    releaseDate: DateTime.utc(2025, 1, 2),
    isPublished: true,
    trackIds: const [100],
    additionalInfo: [TextTrackInfo(title: 'About', text: 'Album info')],
  );
  final track = Track(
    id: 100,
    albumId: album.id,
    name: 'Track',
    authors: [author],
    addionalInfo: [TextTrackInfo(title: 'About', text: 'Track info')],
    file: HttpFile(uri: Uri.parse('https://example.com/track.mp3')),
    image: HttpFile(uri: Uri.parse('https://example.com/track.jpg')),
    isFavorite: true,
    isDisliked: false,
    isAvailable: true,
    createdAt: DateTime.utc(2025, 2, 3),
  );
  const playlist = Playlist(
    id: 200,
    userId: 2,
    name: 'Playlist',
    description: 'Description',
    coverImagePath: 'https://example.com/playlist.jpg',
    visibility: PlaylistVisibility.public,
    trackCount: 4,
    system: false,
    kind: PlaylistKind.custom,
    shareToken: 'share-token',
  );

  return [
    CatalogSearchResultItem.author(author),
    CatalogSearchResultItem.album(album),
    CatalogSearchResultItem.track(track),
    const CatalogSearchResultItem.playlist(playlist),
  ];
}
