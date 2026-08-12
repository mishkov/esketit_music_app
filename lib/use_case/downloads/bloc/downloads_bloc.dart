import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:esketit_music_app/domain/album.dart';
import 'package:esketit_music_app/domain/playlist.dart';
import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/errors/error_reporter/app_error.dart';
import 'package:esketit_music_app/errors/error_reporter/breadcrumb.dart';
import 'package:esketit_music_app/errors/error_reporter/category.dart';
import 'package:esketit_music_app/errors/error_reporter/error_reporter.dart';
import 'package:esketit_music_app/use_case/downloads/download_models.dart';
import 'package:esketit_music_app/use_case/downloads/download_source_resolver.dart';
import 'package:esketit_music_app/use_case/downloads/download_transfer.dart';
import 'package:esketit_music_app/use_case/downloads/downloads_storage.dart';
import 'package:esketit_music_app/use_case/lyrics/lyrics_storage.dart';
import 'package:esketit_music_app/use_case/catalog/catalog_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as path;

sealed class DownloadsEvent extends Equatable {
  const DownloadsEvent();

  @override
  List<Object?> get props => [];
}

final class DownloadsStarted extends DownloadsEvent {
  const DownloadsStarted();
}

final class DownloadTrackRequested extends DownloadsEvent {
  const DownloadTrackRequested({required this.track, this.album});

  final Track track;
  final Album? album;

  @override
  List<Object?> get props => [track, album];
}

final class DownloadAlbumRequested extends DownloadsEvent {
  const DownloadAlbumRequested({required this.album, required this.tracks});

  final Album album;
  final List<Track> tracks;

  @override
  List<Object?> get props => [album, tracks];
}

final class DownloadPlaylistRequested extends DownloadsEvent {
  const DownloadPlaylistRequested({
    required this.playlist,
    required this.tracks,
  });

  final Playlist playlist;
  final List<Track> tracks;

  @override
  List<Object?> get props => [playlist, tracks];
}

final class CancelTrackDownloadRequested extends DownloadsEvent {
  const CancelTrackDownloadRequested(this.trackId);

  final int trackId;

  @override
  List<Object?> get props => [trackId];
}

final class RemoveTrackDownloadRequested extends DownloadsEvent {
  const RemoveTrackDownloadRequested(this.trackId);

  final int trackId;

  @override
  List<Object?> get props => [trackId];
}

final class RemoveAlbumDownloadRequested extends DownloadsEvent {
  const RemoveAlbumDownloadRequested(this.albumId);

  final int albumId;

  @override
  List<Object?> get props => [albumId];
}

final class RemovePlaylistDownloadRequested extends DownloadsEvent {
  const RemovePlaylistDownloadRequested(this.playlistId);

  final int playlistId;

  @override
  List<Object?> get props => [playlistId];
}

final class DeleteAllDownloadsRequested extends DownloadsEvent {
  const DeleteAllDownloadsRequested();
}

final class ClearDownloadFailuresRequested extends DownloadsEvent {
  const ClearDownloadFailuresRequested();
}

final class LoadDownloadedPlaylistRequested extends DownloadsEvent {
  const LoadDownloadedPlaylistRequested(this.playlistId);

  final int playlistId;

  @override
  List<Object?> get props => [playlistId];
}

final class _DownloadQueueChanged extends DownloadsEvent {
  const _DownloadQueueChanged(this.queue);

  final DownloadQueueSnapshot queue;

  @override
  List<Object?> get props => [queue];
}

final class _DownloadedLibraryChanged extends DownloadsEvent {
  const _DownloadedLibraryChanged(this.library);

  final DownloadedLibrarySnapshot library;

  @override
  List<Object?> get props => [library];
}

final class _DownloadedTracksRemoved extends DownloadsEvent {
  const _DownloadedTracksRemoved(this.trackIds);

  final List<int> trackIds;

  @override
  List<Object?> get props => [trackIds];
}

enum DownloadsAvailability { unsupported, starting, ready }

enum TrackDownloadState {
  notDownloaded,
  queued,
  downloading,
  downloaded,
  failed,
}

enum _DownloadFailureOrigin { native, application, dedicatedAlert }

class DownloadsState extends Equatable {
  const DownloadsState({
    required this.availability,
    required this.queue,
    required this.library,
    required this.removalSerial,
    required this.lastRemovedTrackIds,
    required this.operationErrorSerial,
    required this.downloadedPlaylistTracks,
    required this.loadingDownloadedPlaylistIds,
  });

  const DownloadsState.unsupported()
    : availability = DownloadsAvailability.unsupported,
      queue = const DownloadQueueSnapshot.empty(),
      library = const DownloadedLibrarySnapshot.empty(),
      removalSerial = 0,
      lastRemovedTrackIds = const [],
      operationErrorSerial = 0,
      downloadedPlaylistTracks = const {},
      loadingDownloadedPlaylistIds = const {};

  const DownloadsState.starting()
    : availability = DownloadsAvailability.starting,
      queue = const DownloadQueueSnapshot.empty(),
      library = const DownloadedLibrarySnapshot.empty(),
      removalSerial = 0,
      lastRemovedTrackIds = const [],
      operationErrorSerial = 0,
      downloadedPlaylistTracks = const {},
      loadingDownloadedPlaylistIds = const {};

  final DownloadsAvailability availability;
  final DownloadQueueSnapshot queue;
  final DownloadedLibrarySnapshot library;

  /// Monotonic signal consumed by the player synchronizer before files are
  /// removed from disk.
  final int removalSerial;
  final List<int> lastRemovedTrackIds;
  final int operationErrorSerial;
  final Map<int, List<Track>> downloadedPlaylistTracks;
  final Set<int> loadingDownloadedPlaylistIds;

  bool get isSupported => availability != DownloadsAvailability.unsupported;
  bool get isReady => availability == DownloadsAvailability.ready;

  Set<int> get downloadedTrackIds =>
      library.tracks.map((track) => track.id).toSet();

  TrackDownloadState statusForTrack(int trackId) {
    final current = queue.current;
    if (current?.trackId == trackId) {
      return current!.state == DownloadJobState.downloading
          ? TrackDownloadState.downloading
          : TrackDownloadState.queued;
    }
    if (queue.queued.any((job) => job.trackId == trackId)) {
      return TrackDownloadState.queued;
    }
    if (downloadedTrackIds.contains(trackId)) {
      return TrackDownloadState.downloaded;
    }
    if (queue.failures.any((job) => job.trackId == trackId)) {
      return TrackDownloadState.failed;
    }

    return TrackDownloadState.notDownloaded;
  }

  DownloadsState copyWith({
    DownloadsAvailability? availability,
    DownloadQueueSnapshot? queue,
    DownloadedLibrarySnapshot? library,
    int? removalSerial,
    List<int>? lastRemovedTrackIds,
    int? operationErrorSerial,
    Map<int, List<Track>>? downloadedPlaylistTracks,
    Set<int>? loadingDownloadedPlaylistIds,
  }) {
    return DownloadsState(
      availability: availability ?? this.availability,
      queue: queue ?? this.queue,
      library: library ?? this.library,
      removalSerial: removalSerial ?? this.removalSerial,
      lastRemovedTrackIds: lastRemovedTrackIds ?? this.lastRemovedTrackIds,
      operationErrorSerial: operationErrorSerial ?? this.operationErrorSerial,
      downloadedPlaylistTracks:
          downloadedPlaylistTracks ?? this.downloadedPlaylistTracks,
      loadingDownloadedPlaylistIds:
          loadingDownloadedPlaylistIds ?? this.loadingDownloadedPlaylistIds,
    );
  }

  @override
  List<Object?> get props => [
    availability,
    queue,
    library,
    removalSerial,
    lastRemovedTrackIds,
    operationErrorSerial,
    downloadedPlaylistTracks,
    loadingDownloadedPlaylistIds,
  ];
}

class DownloadsBloc extends Bloc<DownloadsEvent, DownloadsState> {
  static final _fnv1aOffsetBasis = BigInt.parse('cbf29ce484222325', radix: 16);
  static final _fnv1aPrime = BigInt.parse('100000001b3', radix: 16);
  static final _positiveInt64Mask = BigInt.parse('7fffffffffffffff', radix: 16);

  DownloadsBloc({
    required DownloadsStorage storage,
    required DownloadTransfer transfer,
    required DownloadAlertNotifications alertNotifications,
    required DownloadSourceResolver sourceResolver,
    required LyricsStorage lyricsStorage,
    required CatalogStorage catalogStorage,
    required ErrorReporter errorReporter,
    required DownloadTransferNotificationMessages transferMessages,
    required DownloadAlertNotificationMessages alertMessages,
    Future<void> Function(Iterable<int> trackIds)?
    preparePlaybackForTrackRemoval,
    Future<void> Function()? storageDisposer,
  }) : _storage = storage,
       _transfer = transfer,
       _alertNotifications = alertNotifications,
       _sourceResolver = sourceResolver,
       _lyricsStorage = lyricsStorage,
       _catalogStorage = catalogStorage,
       _errorReporter = errorReporter,
       _transferMessages = transferMessages,
       _alertMessages = alertMessages,
       _preparePlaybackForTrackRemoval = preparePlaybackForTrackRemoval,
       _storageDisposer = storageDisposer,
       super(const DownloadsState.starting()) {
    _registerEventHandlers();
  }

  DownloadsBloc.unsupported()
    : _storage = null,
      _transfer = null,
      _alertNotifications = null,
      _sourceResolver = null,
      _lyricsStorage = null,
      _catalogStorage = null,
      _errorReporter = null,
      _transferMessages = null,
      _alertMessages = null,
      _preparePlaybackForTrackRemoval = null,
      _storageDisposer = null,
      super(const DownloadsState.unsupported()) {
    _registerEventHandlers();
  }

  final DownloadsStorage? _storage;
  final DownloadTransfer? _transfer;
  final DownloadAlertNotifications? _alertNotifications;
  final DownloadSourceResolver? _sourceResolver;
  final LyricsStorage? _lyricsStorage;
  final CatalogStorage? _catalogStorage;
  final ErrorReporter? _errorReporter;
  final DownloadTransferNotificationMessages? _transferMessages;
  final DownloadAlertNotificationMessages? _alertMessages;
  final Future<void> Function(Iterable<int> trackIds)?
  _preparePlaybackForTrackRemoval;
  final Future<void> Function()? _storageDisposer;

  StreamSubscription<DownloadQueueSnapshot>? _queueSubscription;
  StreamSubscription<DownloadedLibrarySnapshot>? _librarySubscription;
  StreamSubscription<DownloadTransferUpdate>? _transferSubscription;
  Future<void> _synchronization = Future<void>.value();
  bool _hasStarted = false;
  bool _hasRequestedNotificationPermission = false;
  bool _isStoppingForStorage = false;
  bool _hasNativeFailureInCurrentQueue = false;
  bool _hasApplicationFailureInCurrentQueue = false;

  void _registerEventHandlers() {
    on<DownloadsStarted>(_onStarted);
    on<DownloadTrackRequested>(_onDownloadTrackRequested);
    on<DownloadAlbumRequested>(_onDownloadAlbumRequested);
    on<DownloadPlaylistRequested>(_onDownloadPlaylistRequested);
    on<CancelTrackDownloadRequested>(_onCancelTrackRequested);
    on<RemoveTrackDownloadRequested>(_onRemoveTrackRequested);
    on<RemoveAlbumDownloadRequested>(_onRemoveAlbumRequested);
    on<RemovePlaylistDownloadRequested>(_onRemovePlaylistRequested);
    on<DeleteAllDownloadsRequested>(_onDeleteAllRequested);
    on<ClearDownloadFailuresRequested>(_onClearFailuresRequested);
    on<LoadDownloadedPlaylistRequested>(_onLoadDownloadedPlaylistRequested);
    on<_DownloadQueueChanged>((event, emit) {
      emit(state.copyWith(queue: event.queue));
      _scheduleSynchronization();
    });
    on<_DownloadedLibraryChanged>((event, emit) {
      final playlistIds = event.library.playlists
          .map((playlist) => playlist.id)
          .toSet();
      emit(
        state.copyWith(
          library: event.library,
          downloadedPlaylistTracks: {
            for (final entry in state.downloadedPlaylistTracks.entries)
              if (playlistIds.contains(entry.key)) entry.key: entry.value,
          },
        ),
      );
    });
    on<_DownloadedTracksRemoved>((event, emit) {
      if (event.trackIds.isEmpty) {
        return;
      }
      emit(
        state.copyWith(
          removalSerial: state.removalSerial + 1,
          lastRemovedTrackIds: List<int>.unmodifiable(event.trackIds),
        ),
      );
    });
  }

  Future<void> _onStarted(
    DownloadsStarted event,
    Emitter<DownloadsState> emit,
  ) async {
    if (_hasStarted || !state.isSupported) {
      return;
    }
    _hasStarted = true;

    final storage = _storage!;
    final transfer = _transfer!;
    _queueSubscription = storage.watchQueue().listen((queue) {
      if (!isClosed) {
        add(_DownloadQueueChanged(queue));
      }
    });
    _librarySubscription = storage.watchLibrary().listen((library) {
      if (!isClosed) {
        add(_DownloadedLibraryChanged(library));
      }
    });
    _transferSubscription = transfer.updates.listen(_onTransferUpdate);

    try {
      await _alertNotifications!.initialize(_alertMessages!);
      await transfer.start(_transferMessages!);
      final initialQueue = await storage.getQueue();
      final DownloadTransferRecoveryResult recovery;
      if (initialQueue.hasWork) {
        recovery = await transfer.rescheduleMissingTasks();
      } else {
        recovery = const DownloadTransferRecoveryResult(
          rescheduledTasks: [],
          failedToRescheduleTasks: [],
        );
        await _addBreadcrumb(
          'Skipped native download recovery because the queue is empty',
          const {},
        );
      }
      await _reconcileStartupTransferFailures(recovery);
      await _reconcileOrphanedAudioTransfers();
      await _retryPendingFileDeletions();
      final results = await Future.wait([
        storage.getQueue(),
        storage.getLibrary(),
      ]);
      emit(
        state.copyWith(
          availability: DownloadsAvailability.ready,
          queue: results.first as DownloadQueueSnapshot,
          library: results.last as DownloadedLibrarySnapshot,
        ),
      );
      _scheduleSynchronization();
    } catch (error, stackTrace) {
      _hasStarted = false;
      emit(
        state.copyWith(operationErrorSerial: state.operationErrorSerial + 1),
      );
      await _reportError('Failed to initialize downloads', error, stackTrace);
    }
  }

  Future<void> _onDownloadTrackRequested(
    DownloadTrackRequested event,
    Emitter<DownloadsState> emit,
  ) async {
    if (!state.isReady) {
      return;
    }
    await _runRequest(
      breadcrumb: 'Queue track download',
      breadcrumbData: {'trackId': event.track.id},
      action: () async {
        final album = event.album ?? await _loadAlbumForTrack(event.track);
        await _storage!.enqueueTrack(
          snapshot: DownloadTrackSnapshot(
            track: event.track,
            album: album,
            lyrics: DownloadLyricsSnapshot.notFetched(event.track.id),
          ),
        );
      },
    );
    await _requestNotificationPermissionOnce();
    _scheduleSynchronization();
  }

  Future<void> _onDownloadAlbumRequested(
    DownloadAlbumRequested event,
    Emitter<DownloadsState> emit,
  ) async {
    if (!state.isReady) {
      return;
    }
    await _runRequest(
      breadcrumb: 'Queue album download',
      breadcrumbData: {'albumId': event.album.id},
      action: () => _storage!.enqueueAlbum(
        DownloadAlbumSnapshot(
          album: event.album,
          tracks: event.tracks
              .map(
                (track) => DownloadTrackSnapshot(
                  track: track,
                  album: event.album,
                  lyrics: DownloadLyricsSnapshot.notFetched(track.id),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
    await _requestNotificationPermissionOnce();
    _scheduleSynchronization();
  }

  Future<void> _onDownloadPlaylistRequested(
    DownloadPlaylistRequested event,
    Emitter<DownloadsState> emit,
  ) async {
    if (!state.isReady) {
      return;
    }
    await _runRequest(
      breadcrumb: 'Queue playlist download',
      breadcrumbData: {'playlistId': event.playlist.id},
      action: () async {
        final albumsById = await _loadAlbumsForTracks(event.tracks);
        await _storage!.enqueuePlaylist(
          DownloadPlaylistSnapshot(
            playlist: event.playlist,
            tracks: event.tracks
                .map(
                  (track) => DownloadTrackSnapshot(
                    track: track,
                    album: track.albumId == null
                        ? null
                        : albumsById[track.albumId],
                    lyrics: DownloadLyricsSnapshot.notFetched(track.id),
                  ),
                )
                .toList(growable: false),
          ),
        );
      },
    );
    await _requestNotificationPermissionOnce();
    _scheduleSynchronization();
  }

  Future<void> _onCancelTrackRequested(
    CancelTrackDownloadRequested event,
    Emitter<DownloadsState> emit,
  ) => _removeTrack(event.trackId, breadcrumb: 'Cancel track download');

  Future<void> _onRemoveTrackRequested(
    RemoveTrackDownloadRequested event,
    Emitter<DownloadsState> emit,
  ) => _removeTrack(event.trackId, breadcrumb: 'Remove downloaded track');

  Future<void> _removeTrack(int trackId, {required String breadcrumb}) async {
    if (!state.isReady) {
      return;
    }
    await _addBreadcrumb(breadcrumb, {'trackId': trackId});
    final artworkUris = await _storage!.getPendingArtworkUris(trackId: trackId);
    final result = await _storage.removeTrack(trackId: trackId);
    await _notifyDownloadedTracksRemoved(result);
    await _cancelTasksForTrack(trackId, artworkUris: artworkUris);
    await _deleteRemovalPaths(result);
    await _showApplicationFailureAlertIfQueueEnded();
    _scheduleSynchronization();
  }

  Future<void> _onRemoveAlbumRequested(
    RemoveAlbumDownloadRequested event,
    Emitter<DownloadsState> emit,
  ) async {
    if (!state.isReady) {
      return;
    }
    await _addBreadcrumb('Remove downloaded album', {'albumId': event.albumId});
    final result = await _storage!.removeAlbum(albumId: event.albumId);
    await _notifyDownloadedTracksRemoved(result);
    await _cancelTasksForTrackIds(result.removedTrackIds);
    await _deleteRemovalPaths(result);
    await _showApplicationFailureAlertIfQueueEnded();
    _scheduleSynchronization();
  }

  Future<void> _onRemovePlaylistRequested(
    RemovePlaylistDownloadRequested event,
    Emitter<DownloadsState> emit,
  ) async {
    if (!state.isReady) {
      return;
    }
    await _addBreadcrumb('Remove downloaded playlist', {
      'playlistId': event.playlistId,
    });
    final result = await _storage!.removePlaylist(playlistId: event.playlistId);
    await _notifyDownloadedTracksRemoved(result);
    await _cancelTasksForTrackIds(result.removedTrackIds);
    await _deleteRemovalPaths(result);
    await _showApplicationFailureAlertIfQueueEnded();
    _scheduleSynchronization();
  }

  Future<void> _onDeleteAllRequested(
    DeleteAllDownloadsRequested event,
    Emitter<DownloadsState> emit,
  ) async {
    if (!state.isReady) {
      return;
    }
    await _addBreadcrumb('Delete all downloads', const {});
    final result = await _storage!.removeAll();
    await _notifyDownloadedTracksRemoved(result);
    await _transfer!.cancelAll();
    await _deleteRemovalPaths(result);
    _hasApplicationFailureInCurrentQueue = false;
    _hasNativeFailureInCurrentQueue = false;
    _scheduleSynchronization();
  }

  Future<void> _onClearFailuresRequested(
    ClearDownloadFailuresRequested event,
    Emitter<DownloadsState> emit,
  ) async {
    if (!state.isReady) {
      return;
    }
    await _addBreadcrumb('Clear download failures', const {});
    await _storage!.acknowledgeFailures();
  }

  Future<void> _onLoadDownloadedPlaylistRequested(
    LoadDownloadedPlaylistRequested event,
    Emitter<DownloadsState> emit,
  ) async {
    if (!state.isReady ||
        state.loadingDownloadedPlaylistIds.contains(event.playlistId)) {
      return;
    }
    emit(
      state.copyWith(
        loadingDownloadedPlaylistIds: {
          ...state.loadingDownloadedPlaylistIds,
          event.playlistId,
        },
      ),
    );
    try {
      final details = await _storage!.getDownloadedPlaylistDetails(
        playlistId: event.playlistId,
      );
      final loadingIds = Set<int>.of(state.loadingDownloadedPlaylistIds)
        ..remove(event.playlistId);
      emit(
        state.copyWith(
          loadingDownloadedPlaylistIds: loadingIds,
          downloadedPlaylistTracks: {
            ...state.downloadedPlaylistTracks,
            event.playlistId: details?.tracks ?? const <Track>[],
          },
        ),
      );
    } catch (error, stackTrace) {
      final loadingIds = Set<int>.of(state.loadingDownloadedPlaylistIds)
        ..remove(event.playlistId);
      emit(
        state.copyWith(
          loadingDownloadedPlaylistIds: loadingIds,
          operationErrorSerial: state.operationErrorSerial + 1,
        ),
      );
      await _reportError(
        'Failed to load downloaded playlist ${event.playlistId}',
        error,
        stackTrace,
      );
    }
  }

  Future<void> _runRequest({
    required String breadcrumb,
    required Map<String, Object?> breadcrumbData,
    required Future<void> Function() action,
  }) async {
    try {
      await _addBreadcrumb(breadcrumb, breadcrumbData);
      await action();
    } catch (error, stackTrace) {
      addError(error, stackTrace);
      await _reportError(breadcrumb, error, stackTrace);
    }
  }

  Future<void> _requestNotificationPermissionOnce() async {
    if (_hasRequestedNotificationPermission) {
      return;
    }
    _hasRequestedNotificationPermission = true;
    try {
      final status = await _transfer!.getNotificationPermissionStatus();
      if (status == DownloadNotificationPermissionStatus.undetermined ||
          status == DownloadNotificationPermissionStatus.denied) {
        await _transfer.requestNotificationPermission();
      }
    } catch (error, stackTrace) {
      await _reportError(
        'Failed to request download notification permission',
        error,
        stackTrace,
      );
    }
  }

  Future<Album?> _loadAlbumForTrack(Track track) async {
    final albumId = track.albumId;
    if (albumId == null) {
      return null;
    }
    try {
      return await _catalogStorage!.getAlbum(albumId: albumId);
    } catch (error, stackTrace) {
      await _reportError(
        'Failed to cache album metadata for track ${track.id}',
        error,
        stackTrace,
      );

      return null;
    }
  }

  Future<Map<int, Album>> _loadAlbumsForTracks(List<Track> tracks) async {
    final albumIds = tracks
        .map((track) => track.albumId)
        .whereType<int>()
        .toSet();
    final albums = await Future.wait(
      albumIds.map((albumId) async {
        try {
          return await _catalogStorage!.getAlbum(albumId: albumId);
        } catch (error, stackTrace) {
          await _reportError(
            'Failed to cache album metadata for playlist track',
            error,
            stackTrace,
          );

          return null;
        }
      }),
    );

    return {for (final album in albums.whereType<Album>()) album.id: album};
  }

  void _scheduleSynchronization() {
    if (!state.isReady || isClosed) {
      return;
    }
    _synchronization = _synchronization
        .then((_) => _synchronizeNativeQueue())
        .catchError((Object error, StackTrace stackTrace) async {
          await _reportError(
            'Failed to synchronize native download queue',
            error,
            stackTrace,
          );
        });
  }

  Future<void> _synchronizeNativeQueue() async {
    final storage = _storage!;
    var queue = await storage.getQueue();
    if (queue.current == null && queue.queued.isNotEmpty) {
      await storage.claimNextJob(now: DateTime.now().toUtc());
      queue = await storage.getQueue();
    }

    final jobs = [if (queue.current != null) queue.current!, ...queue.queued];
    if (jobs.isEmpty) {
      return;
    }
    final records = {
      for (final record in await _transfer!.getRecords())
        record.task.id: record,
    };
    final ensuredTaskIds = <String>{};

    for (final job in jobs) {
      final snapshot = await storage.getTrackSnapshot(trackId: job.trackId);
      if (snapshot == null) {
        await _failJob(
          job.id,
          DownloadFailureKind.invalidResponse,
          'Stored track metadata is missing',
          origin: _DownloadFailureOrigin.application,
        );
        continue;
      }

      final audioTask = _audioTask(job, snapshot.track);
      if (audioTask == null) {
        await _failJob(
          job.id,
          DownloadFailureKind.invalidResponse,
          'Track does not have a downloadable remote URI',
          origin: _DownloadFailureOrigin.application,
        );
        continue;
      }
      final audioRecord = records[audioTask.id];
      if (audioRecord?.exception?.kind ==
          DownloadTransferExceptionKind.fileSystem) {
        await _stopQueueForInsufficientStorage(
          audioRecord?.exception?.description,
        );

        return;
      }
      if (audioRecord?.status == DownloadTransferStatus.failed ||
          audioRecord?.status == DownloadTransferStatus.notFound) {
        await _failJob(
          job.id,
          _failureKindForRecord(audioRecord!),
          audioRecord.exception?.description,
        );
        continue;
      }
      if (!ensuredTaskIds.contains(audioTask.id)) {
        await _ensureTask(audioTask, audioRecord);
        ensuredTaskIds.add(audioTask.id);
      }

      final artworkUris = await storage.getPendingArtworkUris(
        trackId: job.trackId,
      );
      for (var index = 0; index < artworkUris.length; index += 1) {
        final task = _artworkTask(job, artworkUris[index], index);
        if (await _transfer.fileExists(task.destination)) {
          continue;
        }
        final artworkRecord = records[task.id];
        if (artworkRecord?.exception?.kind ==
            DownloadTransferExceptionKind.fileSystem) {
          await _stopQueueForInsufficientStorage(
            artworkRecord?.exception?.description,
          );

          return;
        }
        if (artworkRecord?.status == DownloadTransferStatus.failed ||
            artworkRecord?.status == DownloadTransferStatus.notFound) {
          await _failJob(
            job.id,
            _failureKindForRecord(artworkRecord!),
            artworkRecord.exception?.description,
          );
          break;
        }
        if (!ensuredTaskIds.contains(task.id)) {
          await _ensureTask(task, artworkRecord);
          ensuredTaskIds.add(task.id);
        }
      }
    }

    await _tryFinalizeCurrentJob();
  }

  Future<void> _reconcileStartupTransferFailures(
    DownloadTransferRecoveryResult recovery,
  ) async {
    final queue = await _storage!.getQueue();
    final activeJobIds = {
      if (queue.current != null) queue.current!.id,
      ...queue.queued.map((job) => job.id),
    };
    if (activeJobIds.isEmpty) {
      return;
    }

    final reconciledJobIds = <int>{};
    final records = await _transfer!.getRecords();
    for (final record in records) {
      if (record.status != DownloadTransferStatus.failed &&
          record.status != DownloadTransferStatus.notFound) {
        continue;
      }
      final jobId = int.tryParse(record.task.correlationId);
      if (jobId == null ||
          !activeJobIds.contains(jobId) ||
          !reconciledJobIds.add(jobId)) {
        continue;
      }
      if (record.exception?.kind == DownloadTransferExceptionKind.fileSystem) {
        await _stopQueueForInsufficientStorage(record.exception?.description);

        return;
      }
      await _failJob(
        jobId,
        _failureKindForRecord(record),
        record.exception?.description,
      );
    }

    for (final task in recovery.failedToRescheduleTasks) {
      final jobId = int.tryParse(task.correlationId);
      if (jobId == null ||
          !activeJobIds.contains(jobId) ||
          !reconciledJobIds.add(jobId)) {
        continue;
      }
      await _failJob(
        jobId,
        DownloadFailureKind.unknown,
        null,
        origin: _DownloadFailureOrigin.application,
      );
    }
  }

  Future<void> _ensureTask(
    DownloadTransferTask task,
    DownloadTransferRecord? record,
  ) async {
    if (record == null) {
      final accepted = await _transfer!.enqueue(task);
      if (!accepted) {
        throw StateError('Native transfer rejected ${task.id}');
      }

      return;
    }

    if (record.status == DownloadTransferStatus.complete) {
      return;
    }
    if (record.status == DownloadTransferStatus.canceled) {
      await _transfer!.deleteRecord(task.id);
      final accepted = await _transfer.enqueue(task);
      if (!accepted) {
        throw StateError('Native transfer rejected ${task.id}');
      }
    }
  }

  Future<void> _reconcileOrphanedAudioTransfers() async {
    final queue = await _storage!.getQueue();
    final activeJobIds = {
      if (queue.current != null) queue.current!.id,
      ...queue.queued.map((job) => job.id),
    };
    for (final record in await _transfer!.getRecords()) {
      if (record.task.purpose != DownloadTransferPurpose.audio) {
        continue;
      }
      final jobId = int.tryParse(record.task.correlationId);
      if (jobId != null && activeJobIds.contains(jobId)) {
        continue;
      }

      if (!record.status.isFinal) {
        await _transfer.cancel(record.task.id);
      }
      final trackId = int.tryParse(record.task.metadata['trackId'] ?? '');
      final downloadedLocation = trackId == null
          ? null
          : await _storage.getDownloadedTrackLocation(trackId: trackId);
      final relativePath = _relativePath(record.task.destination);
      if (downloadedLocation?.audioRelativePath != relativePath) {
        await _transfer.removeFile(record.task.destination);
      }
      await _transfer.deleteRecord(record.task.id);
    }
  }

  Future<void> _retryPendingFileDeletions() async {
    final relativePaths = await _storage!.getPendingDeletionPaths();
    if (relativePaths.isEmpty) {
      return;
    }
    await _deleteRemovalPaths(
      DownloadRemovalResult(
        removedTrackIds: const [],
        removedDownloadedTrackIds: const [],
        relativePathsToDelete: relativePaths,
      ),
    );
  }

  void _onTransferUpdate(DownloadTransferUpdate update) {
    if (isClosed || !state.isReady) {
      return;
    }
    _synchronization = _synchronization
        .then((_) => _handleTransferUpdate(update))
        .catchError((Object error, StackTrace stackTrace) async {
          await _reportError(
            'Failed to serialize a native download update',
            error,
            stackTrace,
          );
        });
  }

  Future<void> _handleTransferUpdate(DownloadTransferUpdate update) async {
    try {
      if (update is DownloadTransferProgressUpdate &&
          update.task.purpose == DownloadTransferPurpose.audio) {
        final jobId = int.tryParse(update.task.correlationId);
        if (jobId == null) {
          return;
        }
        final totalBytes = update.expectedFileSize;
        await _storage!.updateJobProgress(
          jobId: jobId,
          receivedBytes: totalBytes == null
              ? 0
              : (totalBytes * update.progress).round(),
          totalBytes: totalBytes,
        );

        return;
      }
      if (update is! DownloadTransferStatusUpdate) {
        return;
      }

      final exception = update.exception;
      if (exception?.kind == DownloadTransferExceptionKind.fileSystem) {
        await _stopQueueForInsufficientStorage(exception?.description);

        return;
      }
      if (update.status == DownloadTransferStatus.complete) {
        await _tryFinalizeCurrentJob();

        return;
      }
      if (update.status == DownloadTransferStatus.failed ||
          update.status == DownloadTransferStatus.notFound) {
        final jobId = int.tryParse(update.task.correlationId);
        if (jobId != null) {
          await _failJob(
            jobId,
            _failureKindFor(update),
            exception?.description,
          );
          _scheduleSynchronization();
        }

        return;
      }
      if (update.status == DownloadTransferStatus.canceled) {
        final jobId = int.tryParse(update.task.correlationId);
        if (jobId != null) {
          await _handleNativeCancellation(jobId);
        }
        _scheduleSynchronization();
      }
    } catch (error, stackTrace) {
      await _reportError(
        'Failed to process a native download update',
        error,
        stackTrace,
      );
    }
  }

  Future<void> _tryFinalizeCurrentJob() async {
    final queue = await _storage!.getQueue();
    final job = queue.current;
    if (job == null) {
      return;
    }
    final snapshot = await _storage.getTrackSnapshot(trackId: job.trackId);
    if (snapshot == null) {
      return;
    }
    final audioTask = _audioTask(job, snapshot.track);
    if (audioTask == null) {
      return;
    }
    final audioRecord = await _transfer!.getRecord(audioTask.id);
    if (audioRecord?.status != DownloadTransferStatus.complete ||
        !await _transfer.fileExists(audioTask.destination)) {
      return;
    }

    final artworkRelativePaths = <Uri, String>{};
    final artworkUris = await _storage.getPendingArtworkUris(
      trackId: job.trackId,
    );
    for (var index = 0; index < artworkUris.length; index += 1) {
      final uri = artworkUris[index];
      final task = _artworkTask(job, uri, index);
      final record = await _transfer.getRecord(task.id);
      final exists = await _transfer.fileExists(task.destination);
      if (!exists || record?.status != DownloadTransferStatus.complete) {
        if (record?.status case final status?
            when status == DownloadTransferStatus.failed ||
                status == DownloadTransferStatus.notFound) {
          await _failJob(
            job.id,
            _failureKindForRecord(record!),
            record.exception?.description,
          );
        }

        return;
      }
      artworkRelativePaths[uri] = _relativePath(task.destination);
    }

    if (!await _cacheLyrics(snapshot)) {
      await _failJob(
        job.id,
        DownloadFailureKind.network,
        'Lyrics could not be cached after three attempts',
        origin: _DownloadFailureOrigin.application,
      );

      return;
    }

    final audioByteCount =
        await _transfer.fileSize(audioTask.destination) ??
        audioRecord!.expectedFileSize ??
        0;
    if (audioByteCount <= 0) {
      await _failJob(
        job.id,
        DownloadFailureKind.invalidResponse,
        'Downloaded audio file is empty',
        origin: _DownloadFailureOrigin.application,
      );

      return;
    }

    await _storage.completeJob(
      jobId: job.id,
      audioRelativePath: _relativePath(audioTask.destination),
      audioByteCount: audioByteCount,
      cachedArtworkRelativePaths: artworkRelativePaths,
    );
    await _showApplicationFailureAlertIfQueueEnded();
    _scheduleSynchronization();
  }

  Future<bool> _cacheLyrics(DownloadTrackSnapshot snapshot) async {
    if (snapshot.lyrics.availability != DownloadLyricsAvailability.notFetched) {
      return true;
    }

    for (var attempt = 0; attempt < 3; attempt += 1) {
      try {
        final lyrics = await _lyricsStorage!.getTrackLyrics(
          trackId: snapshot.track.id,
        );
        await _storage!.cacheLyrics(
          lyrics == null
              ? DownloadLyricsSnapshot.notAvailable(snapshot.track.id)
              : DownloadLyricsSnapshot.available(lyrics),
        );

        return true;
      } catch (error, stackTrace) {
        if (attempt == 2) {
          await _reportError(
            'Failed to cache lyrics for track ${snapshot.track.id}',
            error,
            stackTrace,
          );

          return false;
        }
        await Future<void>.delayed(Duration(milliseconds: 250 * (attempt + 1)));
      }
    }

    return false;
  }

  Future<void> _stopQueueForInsufficientStorage(String? message) async {
    if (_isStoppingForStorage) {
      return;
    }
    _isStoppingForStorage = true;
    try {
      await _transfer!.cancelAll();
      final queue = await _storage!.getQueue();
      final jobs = [if (queue.current != null) queue.current!, ...queue.queued];
      for (final job in jobs) {
        await _failJob(
          job.id,
          DownloadFailureKind.insufficientStorage,
          message,
          origin: _DownloadFailureOrigin.dedicatedAlert,
        );
      }
      await _alertNotifications!.showInsufficientStorage();
    } finally {
      _isStoppingForStorage = false;
    }
  }

  Future<void> _handleNativeCancellation(int jobId) async {
    final queue = await _storage!.getQueue();
    final jobs = [if (queue.current != null) queue.current!, ...queue.queued];
    final job = jobs.where((item) => item.id == jobId).firstOrNull;
    if (job == null) {
      return;
    }

    final result = await _storage.removeTrack(trackId: job.trackId);
    await _notifyDownloadedTracksRemoved(result);
    await _deleteRemovalPaths(result);
    await _showApplicationFailureAlertIfQueueEnded();
  }

  Future<void> _failJob(
    int jobId,
    DownloadFailureKind failureKind,
    String? message, {
    _DownloadFailureOrigin origin = _DownloadFailureOrigin.native,
  }) async {
    final queue = await _storage!.getQueue();
    final jobs = [if (queue.current != null) queue.current!, ...queue.queued];
    final job = jobs.where((item) => item.id == jobId).firstOrNull;
    final snapshot = job == null
        ? null
        : await _storage.getTrackSnapshot(trackId: job.trackId);
    final audioTask = job == null || snapshot == null
        ? null
        : _audioTask(job, snapshot.track);
    final result = await _storage.failJob(
      jobId: jobId,
      failureKind: failureKind,
      failureMessage: message,
    );
    await _notifyDownloadedTracksRemoved(result);
    final records = await _transfer!.getRecords();
    for (final record in records) {
      if (record.task.correlationId == '$jobId' && !record.status.isFinal) {
        await _transfer.cancel(record.task.id);
      }
    }
    if (audioTask != null) {
      await _transfer.removeFile(audioTask.destination);
    }
    await _deleteRemovalPaths(result);
    switch (origin) {
      case _DownloadFailureOrigin.native:
        _hasNativeFailureInCurrentQueue = true;
      case _DownloadFailureOrigin.application:
        _hasApplicationFailureInCurrentQueue = true;
      case _DownloadFailureOrigin.dedicatedAlert:
        break;
    }
    await _showApplicationFailureAlertIfQueueEnded();
  }

  Future<void> _showApplicationFailureAlertIfQueueEnded() async {
    final queue = await _storage!.getQueue();
    if (queue.hasWork) {
      return;
    }
    final shouldShow =
        _hasApplicationFailureInCurrentQueue &&
        !_hasNativeFailureInCurrentQueue;
    _hasApplicationFailureInCurrentQueue = false;
    _hasNativeFailureInCurrentQueue = false;
    if (!shouldShow) {
      return;
    }
    try {
      await _alertNotifications!.showDownloadFailures();
    } catch (error, stackTrace) {
      await _reportError(
        'Failed to show grouped download failure notification',
        error,
        stackTrace,
      );
    }
  }

  DownloadFailureKind _failureKindFor(DownloadTransferStatusUpdate update) {
    if (update.status == DownloadTransferStatus.notFound) {
      return DownloadFailureKind.server;
    }
    final exception = update.exception;
    if (exception?.kind == DownloadTransferExceptionKind.fileSystem) {
      return DownloadFailureKind.storage;
    }
    if (exception?.kind == DownloadTransferExceptionKind.invalidUrl) {
      return DownloadFailureKind.invalidResponse;
    }
    if (exception?.kind == DownloadTransferExceptionKind.httpResponse) {
      return DownloadFailureKind.server;
    }
    if (exception?.kind == DownloadTransferExceptionKind.connection) {
      return DownloadFailureKind.network;
    }

    return DownloadFailureKind.unknown;
  }

  DownloadFailureKind _failureKindForRecord(DownloadTransferRecord record) {
    if (record.status == DownloadTransferStatus.notFound) {
      return DownloadFailureKind.server;
    }
    final exception = record.exception;
    if (exception?.kind == DownloadTransferExceptionKind.fileSystem) {
      return DownloadFailureKind.storage;
    }
    if (exception?.kind == DownloadTransferExceptionKind.invalidUrl) {
      return DownloadFailureKind.invalidResponse;
    }
    if (exception?.kind == DownloadTransferExceptionKind.httpResponse) {
      return DownloadFailureKind.server;
    }
    if (exception?.kind == DownloadTransferExceptionKind.connection) {
      return DownloadFailureKind.network;
    }

    return DownloadFailureKind.unknown;
  }

  DownloadTransferTask? _audioTask(DownloadJobSnapshot job, Track track) {
    final remoteUri = _sourceResolver!.resolveRemoteUri(track.file);
    if (remoteUri == null) {
      return null;
    }

    return DownloadTransferTask(
      id: _audioTaskId(job.id),
      purpose: DownloadTransferPurpose.audio,
      correlationId: '${job.id}',
      remoteUri: remoteUri,
      destination: DownloadTransferDestination(
        relativeDirectory: 'downloads/audio',
        filename: '${track.id}${_extensionFor(remoteUri, fallback: '.mp3')}',
      ),
      displayName: track.name,
      creationTime: _creationTime(job.id, 0),
      metadata: {'jobId': '${job.id}', 'trackId': '${track.id}'},
    );
  }

  DownloadTransferTask _artworkTask(
    DownloadJobSnapshot job,
    Uri uri,
    int index,
  ) {
    final hash = _stableUriHash(uri);

    return DownloadTransferTask(
      id: 'offline-artwork-$hash',
      purpose: DownloadTransferPurpose.artwork,
      correlationId: '${job.id}',
      remoteUri: uri,
      destination: DownloadTransferDestination(
        relativeDirectory: 'downloads/artwork',
        filename: '$hash${_extensionFor(uri, fallback: '.jpg')}',
      ),
      displayName: job.trackName,
      creationTime: _creationTime(job.id, index + 1),
      metadata: {
        'jobId': '${job.id}',
        'trackId': '${job.trackId}',
        'remoteUri': uri.toString(),
      },
    );
  }

  DateTime _creationTime(int jobId, int position) {
    return DateTime.fromMillisecondsSinceEpoch(
      jobId * 1000 + position,
      isUtc: true,
    );
  }

  String _audioTaskId(int jobId) => 'offline-audio-$jobId';

  String _stableUriHash(Uri uri) {
    var hash = _fnv1aOffsetBasis;
    for (final codeUnit in uri.toString().codeUnits) {
      hash ^= BigInt.from(codeUnit);
      hash = (hash * _fnv1aPrime) & _positiveInt64Mask;
    }

    return hash.toRadixString(16);
  }

  String _extensionFor(Uri uri, {required String fallback}) {
    final extension = path.extension(uri.path).toLowerCase();
    if (extension.length >= 2 &&
        extension.length <= 6 &&
        RegExp(r'^\.[a-z0-9]+$').hasMatch(extension)) {
      return extension;
    }

    return fallback;
  }

  String _relativePath(DownloadTransferDestination destination) {
    return path.posix.join(destination.relativeDirectory, destination.filename);
  }

  Future<void> _cancelTasksForTrackIds(Iterable<int> trackIds) async {
    for (final trackId in trackIds) {
      await _cancelTasksForTrack(trackId);
    }
  }

  Future<void> _cancelTasksForTrack(
    int trackId, {
    List<Uri>? artworkUris,
  }) async {
    final records = await _transfer!.getRecords();
    for (final record in records) {
      if (record.task.metadata['trackId'] == '$trackId') {
        await _transfer.cancel(record.task.id);
      }
    }
    for (final uri in artworkUris ?? const <Uri>[]) {
      await _transfer.cancel('offline-artwork-${_stableUriHash(uri)}');
    }
  }

  Future<void> _notifyDownloadedTracksRemoved(
    DownloadRemovalResult result,
  ) async {
    final trackIds = result.removedDownloadedTrackIds;
    if (trackIds.isEmpty) {
      return;
    }
    try {
      await _preparePlaybackForTrackRemoval?.call(trackIds);
    } catch (error, stackTrace) {
      await _reportError(
        'Failed to prepare playback for downloaded track removal',
        error,
        stackTrace,
      );
    }
    if (!isClosed) {
      add(_DownloadedTracksRemoved(trackIds));
    }
  }

  Future<void> _deleteRemovalPaths(DownloadRemovalResult result) async {
    final deletedPaths = <String>[];
    for (final relativePath in result.relativePathsToDelete) {
      final destination = DownloadTransferDestination(
        relativeDirectory: path.posix.dirname(relativePath) == '.'
            ? ''
            : path.posix.dirname(relativePath),
        filename: path.posix.basename(relativePath),
      );
      try {
        await _transfer!.removeFile(destination);
        deletedPaths.add(relativePath);
      } catch (error, stackTrace) {
        await _reportError(
          'Failed to delete downloaded file $relativePath',
          error,
          stackTrace,
        );
      }
    }
    if (deletedPaths.isNotEmpty) {
      await _storage!.acknowledgeDeletedPaths(deletedPaths);
    }
  }

  Future<void> _addBreadcrumb(String message, Map<String, Object?> data) async {
    await _errorReporter?.addBreadcrumb(
      Breadcrumb(message: message, category: Category.uiClick, data: data),
    );
  }

  Future<void> _reportError(
    String message,
    Object error,
    StackTrace stackTrace,
  ) async {
    await _errorReporter?.reportError(
      AppError(message, cause: error, stackTrace: stackTrace),
    );
  }

  @override
  Future<void> close() async {
    await _queueSubscription?.cancel();
    await _librarySubscription?.cancel();
    await _transferSubscription?.cancel();
    await _transfer?.dispose();
    await _alertNotifications?.dispose();
    await _storageDisposer?.call();

    return super.close();
  }
}
