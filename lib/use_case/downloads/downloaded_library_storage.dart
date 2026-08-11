import 'package:esketit_music_app/domain/album.dart';
import 'package:esketit_music_app/domain/author.dart';
import 'package:esketit_music_app/domain/playlist.dart';
import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/domain/track_lyrics.dart';
import 'package:esketit_music_app/use_case/downloads/download_models.dart';
import 'package:esketit_music_app/use_case/playlists/playlists_storage.dart';

abstract class DownloadedLibraryStorage {
  Stream<Set<int>> watchDownloadedTrackIds();

  Stream<DownloadedLibrarySnapshot> watchLibrary();

  Future<DownloadedLibrarySnapshot> getLibrary();

  Future<List<Track>> getDownloadedTracks();

  Future<Track?> getDownloadedTrack({required int trackId});

  Future<List<Author>> getDownloadedAuthors();

  Future<List<Track>> getDownloadedTracksByAuthor({required int authorId});

  Future<List<Album>> getDownloadedAlbums();

  Future<List<Track>> getDownloadedTracksByAlbum({required int albumId});

  Future<List<Playlist>> getDownloadedPlaylists();

  Future<PlaylistDetailsSnapshot?> getDownloadedPlaylistDetails({
    required int playlistId,
  });

  Future<TrackLyrics?> getCachedLyrics({required int trackId});

  Future<DownloadLyricsSnapshot?> getLyricsSnapshot({required int trackId});

  Future<DownloadedTrackLocation?> getDownloadedTrackLocation({
    required int trackId,
  });
}
