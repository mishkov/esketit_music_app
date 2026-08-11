import 'package:esketit_music_app/use_case/downloads/download_models.dart';

abstract class DownloadRequestStorage {
  Future<void> enqueueTrack({
    required DownloadTrackSnapshot snapshot,
    DownloadReason? reason,
  });

  Future<void> enqueueAlbum(DownloadAlbumSnapshot snapshot);

  Future<void> enqueuePlaylist(DownloadPlaylistSnapshot snapshot);

  Future<void> cacheLyrics(DownloadLyricsSnapshot snapshot);

  /// Removes every reference for this track and its physical download.
  Future<DownloadRemovalResult> removeTrack({required int trackId});

  Future<DownloadRemovalResult> removeAlbum({required int albumId});

  Future<DownloadRemovalResult> removePlaylist({required int playlistId});

  Future<DownloadRemovalResult> removeAll();

  Future<List<String>> getPendingDeletionPaths();

  Future<void> acknowledgeDeletedPaths(Iterable<String> relativePaths);
}
