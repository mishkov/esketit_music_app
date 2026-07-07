import 'package:esketit_music_app/domain/album.dart';
import 'package:esketit_music_app/ui/authors/expanded_author_album_header.dart';
import 'package:esketit_music_app/ui/authors/expanded_author_album_tracks.dart';
import 'package:esketit_music_app/use_case/catalog/bloc/catalog_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ExpandedAuthorAlbumCard extends StatelessWidget {
  const ExpandedAuthorAlbumCard({required this.album, super.key});

  final Album album;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CatalogBloc, CatalogState>(
      buildWhen: (previous, current) =>
          previous.tracksByAlbumId[album.id] !=
              current.tracksByAlbumId[album.id] ||
          previous.loadingAlbumIds.contains(album.id) !=
              current.loadingAlbumIds.contains(album.id) ||
          previous.albumTracksErrorMessages[album.id] !=
              current.albumTracksErrorMessages[album.id],
      builder: (context, state) {
        final tracks = state.tracksByAlbumId[album.id];
        final isLoading = state.loadingAlbumIds.contains(album.id);
        final errorMessage = state.albumTracksErrorMessages[album.id];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExpandedAuthorAlbumHeader(album: album),
            const SizedBox(height: 8),
            ExpandedAuthorAlbumTracks(
              album: album,
              tracks: tracks,
              isLoading: isLoading,
              errorMessage: errorMessage,
            ),
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }
}
