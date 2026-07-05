import 'package:esketit_music_app/domain/author.dart';
import 'package:esketit_music_app/domain/file/abstract_file.dart';
import 'package:esketit_music_app/domain/playlist.dart';
import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/errors/error_reporter/app_error.dart';
import 'package:esketit_music_app/errors/error_reporter/breadcrumb.dart';
import 'package:esketit_music_app/errors/error_reporter/error_reporter.dart';
import 'package:esketit_music_app/use_case/playlists/bloc/playlists_bloc.dart';
import 'package:esketit_music_app/use_case/playlists/playlists_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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

  @override
  Future<void> addTrackToFavorites({required int trackId}) async {}

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
  Future<void> deletePlaylist({required int playlistId}) async {}

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
  }) async {}

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

Playlist _playlist(int id, {required int trackCount}) {
  return Playlist(
    id: id,
    userId: 1,
    name: 'Playlist $id',
    description: '',
    coverImagePath: '',
    visibility: PlaylistVisibility.private,
    trackCount: trackCount,
    system: false,
    isFavorites: false,
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
    isAvailable: true,
  );
}

class _FakeFile extends AbstractFile {
  @override
  List<Object?> get props => const [];
}
