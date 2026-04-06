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

String formatReleaseDate(DateTime releaseDate) {
  final month = switch (releaseDate.month) {
    1 => 'Jan',
    2 => 'Feb',
    3 => 'Mar',
    4 => 'Apr',
    5 => 'May',
    6 => 'Jun',
    7 => 'Jul',
    8 => 'Aug',
    9 => 'Sep',
    10 => 'Oct',
    11 => 'Nov',
    12 => 'Dec',
    _ => '',
  };

  return '$month ${releaseDate.day}, ${releaseDate.year}';
}
