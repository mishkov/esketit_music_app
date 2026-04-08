import 'package:esketit_music_app/domain/album.dart';
import 'package:esketit_music_app/domain/author.dart';
import 'package:esketit_music_app/ui/albums/album_details_screen.dart';
import 'package:esketit_music_app/ui/authors/author_details_screen.dart';
import 'package:esketit_music_app/unassigned_layer/http_file.dart';
import 'package:flutter/material.dart';

void openAuthorDetails(BuildContext context, Author author) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => AuthorDetailsScreen(author: author),
    ),
  );
}

void openAlbumDetails(BuildContext context, Album album) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (context) => AlbumDetailsScreen(album: album)),
  );
}

String? albumCoverUrl(Album album) {
  final cover = album.coverImage;
  if (cover is! HttpFile) {
    return null;
  }
  final value = cover.uri.toString();

  return value.isEmpty ? null : value;
}
