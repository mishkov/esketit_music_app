import 'package:esketit_music_app/domain/author.dart';
import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/domain/track_lyrics.dart';
import 'package:esketit_music_app/unassigned_layer/http_file.dart';
import 'package:esketit_music_app/use_case/downloads/download_models.dart';
import 'package:esketit_music_app/use_case/lyrics/cache_first_lyrics_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../downloads/downloads_test_fakes.dart';

void main() {
  group('CacheFirstLyricsStorage', () {
    test('returns available cached lyrics without a remote request', () async {
      final downloadsStorage = FakeDownloadsStorage();
      addTearDown(downloadsStorage.dispose);
      final remoteStorage = FakeLyricsStorage();
      final cachedLyrics = _lyrics(1, 'Cached lyrics');
      _storeSnapshot(
        downloadsStorage,
        DownloadLyricsSnapshot.available(cachedLyrics),
      );
      final storage = CacheFirstLyricsStorage(
        downloadsStorage: downloadsStorage,
        remoteStorage: remoteStorage,
      );

      final result = await storage.getTrackLyrics(trackId: 1);

      expect(result, cachedLyrics);
      expect(remoteStorage.requestedTrackIds, isEmpty);
    });

    test(
      'returns cached not-available result without a remote request',
      () async {
        final downloadsStorage = FakeDownloadsStorage();
        addTearDown(downloadsStorage.dispose);
        final remoteStorage = FakeLyricsStorage()
          ..result = _lyrics(1, 'Remote');
        _storeSnapshot(
          downloadsStorage,
          const DownloadLyricsSnapshot.notAvailable(1),
        );
        final storage = CacheFirstLyricsStorage(
          downloadsStorage: downloadsStorage,
          remoteStorage: remoteStorage,
        );

        final result = await storage.getTrackLyrics(trackId: 1);

        expect(result, isNull);
        expect(remoteStorage.requestedTrackIds, isEmpty);
      },
    );

    test('fetches and caches lyrics for a not-fetched snapshot', () async {
      final downloadsStorage = FakeDownloadsStorage();
      addTearDown(downloadsStorage.dispose);
      final remoteLyrics = _lyrics(1, 'Remote lyrics');
      final remoteStorage = FakeLyricsStorage()..result = remoteLyrics;
      _storeSnapshot(
        downloadsStorage,
        const DownloadLyricsSnapshot.notFetched(1),
      );
      final storage = CacheFirstLyricsStorage(
        downloadsStorage: downloadsStorage,
        remoteStorage: remoteStorage,
      );

      final result = await storage.getTrackLyrics(trackId: 1);

      expect(result, remoteLyrics);
      expect(remoteStorage.requestedTrackIds, [1]);
      expect(downloadsStorage.cachedLyrics, [
        DownloadLyricsSnapshot.available(remoteLyrics),
      ]);
    });

    test('does not create a cache entry for a non-downloaded track', () async {
      final downloadsStorage = FakeDownloadsStorage();
      addTearDown(downloadsStorage.dispose);
      final remoteLyrics = _lyrics(1, 'Remote lyrics');
      final remoteStorage = FakeLyricsStorage()..result = remoteLyrics;
      final storage = CacheFirstLyricsStorage(
        downloadsStorage: downloadsStorage,
        remoteStorage: remoteStorage,
      );

      final result = await storage.getTrackLyrics(trackId: 1);

      expect(result, remoteLyrics);
      expect(remoteStorage.requestedTrackIds, [1]);
      expect(downloadsStorage.cachedLyrics, isEmpty);
    });
  });
}

void _storeSnapshot(
  FakeDownloadsStorage storage,
  DownloadLyricsSnapshot lyrics,
) {
  storage.trackSnapshots[lyrics.trackId] = DownloadTrackSnapshot(
    track: _track(lyrics.trackId),
    lyrics: lyrics,
  );
}

Track _track(int id) {
  return Track(
    id: id,
    name: 'Track $id',
    authors: const [Author(id: 10, currentName: 'Author', photos: [])],
    addionalInfo: const [],
    file: HttpFile(uri: Uri.parse('https://example.test/audio/$id.mp3')),
    image: HttpFile(uri: Uri.parse('https://example.test/images/$id.jpg')),
    isFavorite: false,
    isDisliked: false,
    isAvailable: true,
  );
}

TrackLyrics _lyrics(int trackId, String text) {
  return TrackLyrics(
    trackId: trackId,
    type: TrackLyricsType.plain,
    languageCode: 'en',
    isVerified: true,
    source: 'test',
    plainText: text,
    lines: const [],
  );
}
