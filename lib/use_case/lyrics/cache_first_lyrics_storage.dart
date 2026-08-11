import 'package:esketit_music_app/domain/track_lyrics.dart';
import 'package:esketit_music_app/use_case/downloads/download_models.dart';
import 'package:esketit_music_app/use_case/downloads/downloads_storage.dart';
import 'package:esketit_music_app/use_case/lyrics/lyrics_storage.dart';

/// Serves a downloaded lyrics snapshot without touching the network.
///
/// A `notFetched` snapshot deliberately falls through to the remote storage;
/// failures leave it in that state so a temporary network error never becomes
/// a permanently cached "no lyrics" result.
class CacheFirstLyricsStorage implements LyricsStorage {
  const CacheFirstLyricsStorage({
    required DownloadsStorage downloadsStorage,
    required LyricsStorage remoteStorage,
  }) : _downloadsStorage = downloadsStorage,
       _remoteStorage = remoteStorage;

  final DownloadsStorage _downloadsStorage;
  final LyricsStorage _remoteStorage;

  @override
  Future<TrackLyrics?> getTrackLyrics({required int trackId}) async {
    final snapshot = await _downloadsStorage.getLyricsSnapshot(
      trackId: trackId,
    );
    if (snapshot?.availability == DownloadLyricsAvailability.available) {
      return snapshot!.lyrics;
    }
    if (snapshot?.availability == DownloadLyricsAvailability.notAvailable) {
      return null;
    }

    final lyrics = await _remoteStorage.getTrackLyrics(trackId: trackId);
    if (snapshot != null) {
      await _downloadsStorage.cacheLyrics(
        lyrics == null
            ? DownloadLyricsSnapshot.notAvailable(trackId)
            : DownloadLyricsSnapshot.available(lyrics),
      );
    }

    return lyrics;
  }
}
