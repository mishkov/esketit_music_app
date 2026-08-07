import 'dart:async';

import 'package:esketit_music_app/domain/author.dart';
import 'package:esketit_music_app/domain/file/abstract_file.dart';
import 'package:esketit_music_app/domain/playlist.dart';
import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/errors/error_reporter/app_error.dart';
import 'package:esketit_music_app/errors/error_reporter/breadcrumb.dart';
import 'package:esketit_music_app/errors/error_reporter/error_reporter.dart';
import 'package:esketit_music_app/use_case/player/autoplay_storage.dart';
import 'package:esketit_music_app/use_case/playlists/bloc/playlists_bloc.dart';
import 'package:esketit_music_app/use_case/playlists/playlists_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads recently added favorite tracks first', () async {
    final playlist = _playlist(7, trackCount: 3, kind: PlaylistKind.favorites);
    final storage = _FakePlaylistsStorage(
      playlists: [playlist],
      playlistTracksById: {
        playlist.id: [_track(1), _track(2), _track(3)],
      },
    );
    final bloc = PlaylistsBloc(
      playlistsStorage: storage,
      errorReporter: _FakeErrorReporter(),
    );

    bloc.add(LoadPlaylistDetails(playlist.id));
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.playlistTracksById[playlist.id], [
      _track(3),
      _track(2),
      _track(1),
    ]);

    await bloc.close();
  });

  test('reloads cached playlist tracks after adding a track to it', () async {
    final playlist = _playlist(7, trackCount: 1);
    final storage = _FakePlaylistsStorage(
      playlists: [playlist],
      playlistTracksById: {
        playlist.id: [_track(1)],
      },
    );
    final bloc = PlaylistsBloc(
      playlistsStorage: storage,
      errorReporter: _FakeErrorReporter(),
    );

    bloc.add(LoadPlaylistDetails(playlist.id));
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.playlistTracksById[playlist.id], [_track(1)]);

    storage.playlistTracksById[playlist.id] = [_track(1), _track(2)];
    bloc.add(
      AddTrackToPlaylistsRequested(trackId: 2, playlistIds: [playlist.id]),
    );
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.playlistTracksById[playlist.id], [_track(1), _track(2)]);
    expect(storage.loadedPlaylistIds, [playlist.id, playlist.id]);

    await bloc.close();
  });

  test('updates track playlist additions and removals', () async {
    final addPlaylist = _playlist(7, trackCount: 0);
    final removePlaylist = _playlist(8, trackCount: 1);
    final track = _track(2);
    final storage = _FakePlaylistsStorage(
      playlists: [addPlaylist, removePlaylist],
      playlistTracksById: {
        addPlaylist.id: const [],
        removePlaylist.id: [track],
      },
    );
    final bloc = PlaylistsBloc(
      playlistsStorage: storage,
      errorReporter: _FakeErrorReporter(),
    );

    bloc.add(const LoadPlaylists());
    bloc.add(LoadPlaylistDetails(removePlaylist.id));
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    bloc.add(
      UpdateTrackPlaylistsRequested(
        trackId: track.id,
        addPlaylistIds: [addPlaylist.id],
        removePlaylistIds: [removePlaylist.id],
      ),
    );
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(storage.addedTrackIds, [track.id]);
    expect(storage.addedTrackPlaylistIds, [
      [addPlaylist.id],
    ]);
    expect(storage.removedTrackIds, [track.id]);
    expect(storage.removedTrackPlaylistIds, [removePlaylist.id]);
    expect(
      bloc.state.playlists
          .singleWhere((playlist) => playlist.id == addPlaylist.id)
          .trackCount,
      1,
    );
    expect(
      bloc.state.playlists
          .singleWhere((playlist) => playlist.id == removePlaylist.id)
          .trackCount,
      0,
    );
    expect(bloc.state.playlistTracksById[removePlaylist.id], isEmpty);

    await bloc.close();
  });

  test(
    'dislike is optimistic, mutually exclusive, and rapid taps are deduplicated',
    () async {
      final track = _track(2).copyWith(isFavorite: true);
      final playlist = _playlist(7, trackCount: 1);
      final storage = _FakePlaylistsStorage(
        playlists: [playlist],
        playlistTracksById: {
          playlist.id: [track],
        },
      );
      final dislikeCompleter = Completer<void>();
      storage.addDislikeCompleter = dislikeCompleter;
      final bloc = PlaylistsBloc(
        playlistsStorage: storage,
        errorReporter: _FakeErrorReporter(),
      );

      bloc.add(LoadPlaylistDetails(playlist.id));
      await _flushEvents();
      const sourceContext = AutoplayContext(
        sourceType: AutoplaySourceType.playlist,
        sourceId: 7,
      );
      const request = ToggleDislikeRequested(
        trackId: 2,
        shouldBeDisliked: true,
        sourceContext: sourceContext,
        sourceQueueIndex: 3,
        sourceWasPlaying: true,
      );
      bloc
        ..add(request)
        ..add(request);
      await _flushEvents();

      expect(storage.addDislikeCallCount, 1);
      expect(bloc.state.isTrackPreferencePending(track.id), isTrue);
      expect(bloc.state.favoriteOverrides[track.id], isFalse);
      expect(bloc.state.dislikeOverrides[track.id], isTrue);
      final optimisticTrack =
          bloc.state.playlistTracksById[playlist.id]!.single;
      expect(optimisticTrack.isFavorite, isFalse);
      expect(optimisticTrack.isDisliked, isTrue);

      dislikeCompleter.complete();
      await _flushEvents();

      expect(bloc.state.isTrackPreferencePending(track.id), isFalse);
      final change = bloc.state.persistedTrackPreferenceChange!;
      expect(change.serial, 1);
      expect(change.trackId, track.id);
      expect(change.isDisliked, isTrue);
      expect(change.collectDislikeAnalytics, isTrue);
      expect(change.sourceContext, sourceContext);
      expect(change.sourceQueueIndex, 3);
      expect(change.sourceWasPlaying, isTrue);

      await bloc.close();
    },
  );

  test(
    'failed dislike restores both preferences and emits no success',
    () async {
      final track = _track(2).copyWith(isFavorite: true);
      final playlist = _playlist(7, trackCount: 1);
      final storage = _FakePlaylistsStorage(
        playlists: [playlist],
        playlistTracksById: {
          playlist.id: [track],
        },
      )..failAddDislike = true;
      final bloc = PlaylistsBloc(
        playlistsStorage: storage,
        errorReporter: _FakeErrorReporter(),
      );

      bloc.add(LoadPlaylistDetails(playlist.id));
      await _flushEvents();
      bloc.add(
        ToggleDislikeRequested(trackId: track.id, shouldBeDisliked: true),
      );
      await _flushEvents();

      expect(bloc.state.favoriteOverrides.containsKey(track.id), isFalse);
      expect(bloc.state.dislikeOverrides.containsKey(track.id), isFalse);
      final restoredTrack = bloc.state.playlistTracksById[playlist.id]!.single;
      expect(restoredTrack.isFavorite, isTrue);
      expect(restoredTrack.isDisliked, isFalse);
      expect(bloc.state.persistedTrackPreferenceChange, isNull);
      expect(
        bloc.state.feedbackReason,
        PlaylistsFeedbackReason.dislikeUpdateFailed,
      );
      expect(bloc.state.isFeedbackError, isTrue);

      await bloc.close();
    },
  );

  test(
    'favorite clears dislike and synchronizes player without analytics',
    () async {
      final track = _track(2).copyWith(isDisliked: true);
      final playlist = _playlist(7, trackCount: 1);
      final storage = _FakePlaylistsStorage(
        playlists: [playlist],
        playlistTracksById: {
          playlist.id: [track],
        },
      );
      final bloc = PlaylistsBloc(
        playlistsStorage: storage,
        errorReporter: _FakeErrorReporter(),
      );

      bloc.add(LoadPlaylistDetails(playlist.id));
      await _flushEvents();
      bloc.add(
        ToggleFavoriteRequested(
          trackId: track.id,
          shouldBeFavorite: true,
          currentIsDisliked: true,
        ),
      );
      await _flushEvents();

      expect(bloc.state.favoriteOverrides[track.id], isTrue);
      expect(bloc.state.dislikeOverrides[track.id], isFalse);
      final updatedTrack = bloc.state.playlistTracksById[playlist.id]!.single;
      expect(updatedTrack.isFavorite, isTrue);
      expect(updatedTrack.isDisliked, isFalse);
      final change = bloc.state.persistedTrackPreferenceChange!;
      expect(change.isDisliked, isFalse);
      expect(change.collectDislikeAnalytics, isFalse);

      await bloc.close();
    },
  );

  test('known system playlists reject generic mutations', () async {
    final playlist = _playlist(
      7,
      trackCount: 1,
      kind: PlaylistKind.dislikes,
      system: true,
    );
    final storage = _FakePlaylistsStorage(
      playlists: [playlist],
      playlistTracksById: {
        playlist.id: [_track(2)],
      },
    );
    final bloc = PlaylistsBloc(
      playlistsStorage: storage,
      errorReporter: _FakeErrorReporter(),
    );

    bloc.add(const LoadPlaylists());
    bloc.add(LoadPlaylistDetails(playlist.id));
    await _flushEvents();
    bloc
      ..add(
        RemoveTrackFromPlaylistRequested(trackId: 2, playlistId: playlist.id),
      )
      ..add(
        ReorderPlaylistTracksRequested(
          playlistId: playlist.id,
          trackIds: const [2],
        ),
      )
      ..add(
        AddTrackToPlaylistsRequested(trackId: 2, playlistIds: [playlist.id]),
      )
      ..add(DeletePlaylistRequested(playlist));
    await _flushEvents();

    expect(storage.removedTrackPlaylistIds, isEmpty);
    expect(storage.addedTrackPlaylistIds, isEmpty);
    expect(storage.reorderCallCount, 0);
    expect(storage.deleteCallCount, 0);
    expect(bloc.state.playlistTracksById[playlist.id], hasLength(1));

    await bloc.close();
  });
}

Future<void> _flushEvents() async {
  for (var index = 0; index < 4; index++) {
    await Future<void>.delayed(Duration.zero);
  }
}

class _FakePlaylistsStorage implements PlaylistsStorage {
  _FakePlaylistsStorage({
    required this.playlists,
    required this.playlistTracksById,
  });

  List<Playlist> playlists;
  Map<int, List<Track>> playlistTracksById;
  final List<int> loadedPlaylistIds = <int>[];
  final List<int> addedTrackIds = <int>[];
  final List<List<int>> addedTrackPlaylistIds = <List<int>>[];
  final List<int> removedTrackIds = <int>[];
  final List<int> removedTrackPlaylistIds = <int>[];
  Completer<void>? addDislikeCompleter;
  bool failAddDislike = false;
  int addDislikeCallCount = 0;
  int reorderCallCount = 0;
  int deleteCallCount = 0;

  @override
  Future<void> addTrackToFavorites({required int trackId}) async {}

  @override
  Future<void> addTrackToDislikes({required int trackId}) async {
    addDislikeCallCount++;
    if (failAddDislike) {
      throw StateError('dislike failed');
    }
    await addDislikeCompleter?.future;
  }

  @override
  Future<void> addTrackToPlaylists({
    required int trackId,
    required List<int> playlistIds,
  }) async {
    addedTrackIds.add(trackId);
    addedTrackPlaylistIds.add(playlistIds);
  }

  @override
  Future<Playlist> createPlaylist(PlaylistUpsertInput input) async =>
      throw UnimplementedError();

  @override
  Future<void> deletePlaylist({required int playlistId}) async {
    deleteCallCount++;
  }

  @override
  Future<Playlist> getPlaylist({required int playlistId}) async {
    loadedPlaylistIds.add(playlistId);

    return playlists.singleWhere((playlist) => playlist.id == playlistId);
  }

  @override
  Future<List<Track>> getPlaylistTracks({required int playlistId}) async =>
      playlistTracksById[playlistId] ?? const <Track>[];

  @override
  Future<List<Playlist>> getPlaylists() async => playlists;

  @override
  Future<void> removeTrackFromFavorites({required int trackId}) async {}

  @override
  Future<void> removeTrackFromDislikes({required int trackId}) async {}

  @override
  Future<void> removeTrackFromPlaylist({
    required int trackId,
    required int playlistId,
  }) async {
    removedTrackIds.add(trackId);
    removedTrackPlaylistIds.add(playlistId);
  }

  @override
  Future<void> reorderPlaylistTracks({
    required int playlistId,
    required List<int> trackIds,
  }) async {
    reorderCallCount++;
  }

  @override
  Future<Playlist> updatePlaylist({
    required int playlistId,
    required PlaylistUpsertInput input,
  }) async => throw UnimplementedError();

  @override
  Future<Playlist> uploadPlaylistCover({
    required int playlistId,
    required PlaylistCoverUploadInput input,
  }) async => throw UnimplementedError();
}

class _FakeErrorReporter implements ErrorReporter {
  @override
  Future<void> addBreadcrumb(Breadcrumb breadcrumb) async {}

  @override
  Future<void> reportError(AppError error) async {}

  @override
  Future<void> setUserId(String? id) async {}
}

Playlist _playlist(
  int id, {
  required int trackCount,
  PlaylistKind kind = PlaylistKind.custom,
  bool system = false,
}) {
  return Playlist(
    id: id,
    userId: 1,
    name: 'Playlist $id',
    description: '',
    coverImagePath: '',
    visibility: PlaylistVisibility.private,
    trackCount: trackCount,
    system: system,
    kind: kind,
  );
}

Track _track(int id) {
  return Track(
    id: id,
    name: 'Track $id',
    authors: const [Author(id: 1, currentName: 'Author', photos: [])],
    addionalInfo: const [],
    file: _FakeFile(),
    image: _FakeFile(),
    isFavorite: false,
    isDisliked: false,
    isAvailable: true,
  );
}

class _FakeFile extends AbstractFile {
  @override
  List<Object?> get props => const [];
}
