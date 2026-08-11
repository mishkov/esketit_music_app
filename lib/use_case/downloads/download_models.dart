import 'package:equatable/equatable.dart';
import 'package:esketit_music_app/domain/album.dart';
import 'package:esketit_music_app/domain/author.dart';
import 'package:esketit_music_app/domain/playlist.dart';
import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/domain/track_lyrics.dart';

enum DownloadReasonType { track, album, playlist }

class DownloadReason extends Equatable {
  const DownloadReason({required this.type, required this.entityId});

  const DownloadReason.track(int trackId)
    : type = DownloadReasonType.track,
      entityId = trackId;

  const DownloadReason.album(int albumId)
    : type = DownloadReasonType.album,
      entityId = albumId;

  const DownloadReason.playlist(int playlistId)
    : type = DownloadReasonType.playlist,
      entityId = playlistId;

  final DownloadReasonType type;
  final int entityId;

  @override
  List<Object?> get props => [type, entityId];
}

enum DownloadLyricsAvailability { notFetched, available, notAvailable }

class DownloadLyricsSnapshot extends Equatable {
  const DownloadLyricsSnapshot({
    required this.trackId,
    required this.availability,
    required this.lyrics,
  }) : assert(
         availability == DownloadLyricsAvailability.available
             ? lyrics != null
             : lyrics == null,
       );

  const DownloadLyricsSnapshot.notFetched(int value)
    : trackId = value,
      availability = DownloadLyricsAvailability.notFetched,
      lyrics = null;

  DownloadLyricsSnapshot.available(TrackLyrics value)
    : trackId = value.trackId,
      availability = DownloadLyricsAvailability.available,
      lyrics = value;

  const DownloadLyricsSnapshot.notAvailable(int value)
    : trackId = value,
      availability = DownloadLyricsAvailability.notAvailable,
      lyrics = null;

  final int trackId;
  final DownloadLyricsAvailability availability;
  final TrackLyrics? lyrics;

  @override
  List<Object?> get props => [trackId, availability, lyrics];
}

class DownloadTrackSnapshot extends Equatable {
  const DownloadTrackSnapshot({
    required this.track,
    required this.lyrics,
    this.album,
  });

  final Track track;
  final Album? album;
  final DownloadLyricsSnapshot lyrics;

  @override
  List<Object?> get props => [track, album, lyrics];
}

class DownloadAlbumSnapshot extends Equatable {
  const DownloadAlbumSnapshot({required this.album, required this.tracks});

  final Album album;
  final List<DownloadTrackSnapshot> tracks;

  @override
  List<Object?> get props => [album, tracks];
}

class DownloadPlaylistSnapshot extends Equatable {
  const DownloadPlaylistSnapshot({
    required this.playlist,
    required this.tracks,
  });

  final Playlist playlist;
  final List<DownloadTrackSnapshot> tracks;

  @override
  List<Object?> get props => [playlist, tracks];
}

enum DownloadJobState { queued, downloading, waitingToRetry, failed }

enum DownloadFailureKind {
  network,
  server,
  storage,
  insufficientStorage,
  invalidResponse,
  unknown,
}

class DownloadJobSnapshot extends Equatable {
  const DownloadJobSnapshot({
    required this.id,
    required this.batchId,
    required this.trackId,
    required this.trackName,
    required this.state,
    required this.enqueuedAt,
    required this.attemptCount,
    required this.receivedBytes,
    required this.totalBytes,
    required this.nextAttemptAt,
    required this.temporaryRelativePath,
    required this.entityTag,
    required this.lastModified,
    required this.failureKind,
    required this.failureMessage,
  });

  final int id;
  final int batchId;
  final int trackId;
  final String trackName;
  final DownloadJobState state;
  final DateTime enqueuedAt;
  final int attemptCount;
  final int receivedBytes;
  final int? totalBytes;
  final DateTime? nextAttemptAt;
  final String? temporaryRelativePath;
  final String? entityTag;
  final String? lastModified;
  final DownloadFailureKind? failureKind;
  final String? failureMessage;

  double? get progress {
    final safeTotalBytes = totalBytes;
    if (safeTotalBytes == null || safeTotalBytes <= 0) {
      return null;
    }

    return (receivedBytes / safeTotalBytes).clamp(0, 1);
  }

  @override
  List<Object?> get props => [
    id,
    batchId,
    trackId,
    trackName,
    state,
    enqueuedAt,
    attemptCount,
    receivedBytes,
    totalBytes,
    nextAttemptAt,
    temporaryRelativePath,
    entityTag,
    lastModified,
    failureKind,
    failureMessage,
  ];
}

class DownloadQueueSnapshot extends Equatable {
  const DownloadQueueSnapshot({
    required this.current,
    required this.queued,
    required this.failures,
  });

  const DownloadQueueSnapshot.empty()
    : current = null,
      queued = const [],
      failures = const [];

  final DownloadJobSnapshot? current;
  final List<DownloadJobSnapshot> queued;
  final List<DownloadJobSnapshot> failures;

  bool get hasWork => current != null || queued.isNotEmpty;
  bool get shouldShowIndicator => hasWork || failures.isNotEmpty;

  @override
  List<Object?> get props => [current, queued, failures];
}

class DownloadRemovalResult extends Equatable {
  const DownloadRemovalResult({
    required this.removedTrackIds,
    required this.relativePathsToDelete,
    List<int>? removedDownloadedTrackIds,
  }) : removedDownloadedTrackIds = removedDownloadedTrackIds ?? removedTrackIds;

  const DownloadRemovalResult.empty()
    : removedTrackIds = const [],
      removedDownloadedTrackIds = const [],
      relativePathsToDelete = const [];

  /// Every metadata record removed, including queued tracks without a file.
  final List<int> removedTrackIds;

  /// The subset that had a completed audio file and may be in playback.
  final List<int> removedDownloadedTrackIds;
  final List<String> relativePathsToDelete;

  bool get isEmpty => removedTrackIds.isEmpty && relativePathsToDelete.isEmpty;

  @override
  List<Object?> get props => [
    removedTrackIds,
    removedDownloadedTrackIds,
    relativePathsToDelete,
  ];
}

class DownloadedTrackLocation extends Equatable {
  const DownloadedTrackLocation({
    required this.trackId,
    required this.audioRelativePath,
    required this.artworkRelativePath,
  });

  final int trackId;
  final String audioRelativePath;
  final String? artworkRelativePath;

  @override
  List<Object?> get props => [trackId, audioRelativePath, artworkRelativePath];
}

class DownloadedLibrarySnapshot extends Equatable {
  const DownloadedLibrarySnapshot({
    required this.tracks,
    required this.authors,
    required this.albums,
    required this.playlists,
    this.albumDownloadIds = const {},
    this.playlistDownloadIds = const {},
  });

  const DownloadedLibrarySnapshot.empty()
    : tracks = const [],
      authors = const [],
      albums = const [],
      playlists = const [],
      albumDownloadIds = const {},
      playlistDownloadIds = const {};

  final List<Track> tracks;
  final List<Author> authors;
  final List<Album> albums;
  final List<Playlist> playlists;
  final Set<int> albumDownloadIds;
  final Set<int> playlistDownloadIds;

  @override
  List<Object?> get props => [
    tracks,
    authors,
    albums,
    playlists,
    albumDownloadIds,
    playlistDownloadIds,
  ];
}
