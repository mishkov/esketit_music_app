import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/use_case/downloads/downloaded_library_storage.dart';
import 'package:esketit_music_app/use_case/player/audio_player.dart';
import 'package:esketit_music_app/use_case/player/playback_repeat_mode.dart';

/// Resolves every queue item to its completed local copy before it reaches the
/// platform player. Remote media remains the fallback when no cache exists.
class DownloadAwareAudioPlayer implements AudioPlayer {
  DownloadAwareAudioPlayer({
    required AudioPlayer delegate,
    required DownloadedLibraryStorage downloadedLibraryStorage,
  }) : _delegate = delegate,
       _downloadedLibraryStorage = downloadedLibraryStorage;

  final AudioPlayer _delegate;
  final DownloadedLibraryStorage _downloadedLibraryStorage;

  @override
  int? get currentIndex => _delegate.currentIndex;

  @override
  Duration get currentPosition => _delegate.currentPosition;

  @override
  Stream<Track?> get currentTrackStream => _delegate.currentTrackStream;

  @override
  Stream<Duration?> get durationStream => _delegate.durationStream;

  @override
  Stream<bool> get hasNextTrackStream => _delegate.hasNextTrackStream;

  @override
  Stream<bool> get hasPreviousTrackStream => _delegate.hasPreviousTrackStream;

  @override
  Stream<bool> get isPlayingStream => _delegate.isPlayingStream;

  @override
  Stream<Duration> get positionStream => _delegate.positionStream;

  @override
  Future<void> appendToQueue(List<Track> tracks) async {
    await _delegate.appendToQueue(await _resolveTracks(tracks));
  }

  @override
  Future<void> beginPlayingQueue(
    List<Track> tracks, {
    required int initialIndex,
  }) async {
    await _delegate.beginPlayingQueue(
      await _resolveTracks(tracks),
      initialIndex: initialIndex,
    );
  }

  @override
  Future<void> dispose() => _delegate.dispose();

  @override
  Future<void> removeUpcomingTracks(Set<int> trackIds) =>
      _delegate.removeUpcomingTracks(trackIds);

  @override
  Future<void> removeTracks(Set<int> trackIds) =>
      _delegate.removeTracks(trackIds);

  @override
  Future<void> seekTo(Duration position) => _delegate.seekTo(position);

  @override
  Future<void> setRepeatMode(PlaybackRepeatMode repeatMode) =>
      _delegate.setRepeatMode(repeatMode);

  @override
  Future<void> skipToNextTrack() => _delegate.skipToNextTrack();

  @override
  Future<void> skipToPreviousTrack() => _delegate.skipToPreviousTrack();

  @override
  Future<void> stop() => _delegate.stop();

  @override
  Future<void> togglePlay() => _delegate.togglePlay();

  Future<List<Track>> _resolveTracks(List<Track> tracks) async {
    return Future.wait(
      tracks.map((track) async {
        return await _downloadedLibraryStorage.getDownloadedTrack(
              trackId: track.id,
            ) ??
            track;
      }),
    );
  }
}
