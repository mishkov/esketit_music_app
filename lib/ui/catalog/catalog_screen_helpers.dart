import 'package:esketit_music_app/domain/album.dart';
import 'package:esketit_music_app/domain/author.dart';
import 'package:esketit_music_app/domain/playlist.dart';
import 'package:esketit_music_app/ui/albums/album_details_screen.dart';
import 'package:esketit_music_app/ui/authors/author_details_screen.dart';
import 'package:esketit_music_app/ui/playlists/playlist_details_screen.dart';
import 'package:esketit_music_app/ui/playlists/playlist_routes.dart';
import 'package:esketit_music_app/unassigned_layer/http_file.dart';
import 'package:esketit_music_app/use_case/auth/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

void openPlaylistDetails(BuildContext context, Playlist playlist) {
  final currentUserId = context.read<AuthBloc>().state.session?.user.id;
  if (currentUserId == playlist.userId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PlaylistDetailsScreen(playlistId: playlist.id),
      ),
    );

    return;
  }

  final routePath = switch (playlist.visibility) {
    PlaylistVisibility.public => publicPlaylistRoutePath(playlist.id),
    PlaylistVisibility.shared when playlist.shareToken != null =>
      sharedPlaylistRoutePath(playlist.shareToken!),
    _ => null,
  };

  if (routePath == null) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PlaylistDetailsScreen(playlistId: playlist.id),
      ),
    );

    return;
  }

  Navigator.of(context).pushNamed(routePath);
}

String? albumCoverUrl(Album album) {
  final cover = album.coverImage;
  if (cover is! HttpFile) {
    return null;
  }
  final value = cover.uri.toString();

  return value.isEmpty ? null : value;
}

String? playlistCoverUrl(Playlist playlist) {
  final value = playlist.coverImagePath;

  return value.isEmpty ? null : value;
}
