import 'package:esketit_music_app/domain/playlist.dart';
import 'package:esketit_music_app/domain/track.dart';

class PlaylistUpsertInput {
  const PlaylistUpsertInput({
    required this.name,
    required this.description,
    required this.coverImagePath,
    required this.visibility,
  });

  final String name;
  final String description;
  final String coverImagePath;
  final PlaylistVisibility visibility;
}

abstract class PlaylistsStorage {
  Future<List<Playlist>> getPlaylists();

  Future<Playlist> getPlaylist({required int playlistId});

  Future<Playlist> createPlaylist(PlaylistUpsertInput input);

  Future<Playlist> updatePlaylist({
    required int playlistId,
    required PlaylistUpsertInput input,
  });

  Future<void> deletePlaylist({required int playlistId});

  Future<List<Track>> getPlaylistTracks({required int playlistId});

  Future<void> reorderPlaylistTracks({
    required int playlistId,
    required List<int> trackIds,
  });

  Future<void> addTrackToPlaylists({
    required int trackId,
    required List<int> playlistIds,
  });

  Future<void> removeTrackFromPlaylist({
    required int trackId,
    required int playlistId,
  });

  Future<void> addTrackToFavorites({required int trackId});

  Future<void> removeTrackFromFavorites({required int trackId});
}
