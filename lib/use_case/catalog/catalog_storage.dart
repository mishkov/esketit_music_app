import 'package:esketit_music_app/domain/album.dart';
import 'package:esketit_music_app/domain/author.dart';
import 'package:esketit_music_app/domain/track.dart';

abstract class CatalogStorage {
  Future<List<Author>> getPublishedAuthors();

  Future<List<Album>> getPublishedAlbumsByAuthor({required int authorId});

  Future<List<Track>> getAlbumTracks({required Album album});
}
