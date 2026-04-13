import 'package:esketit_music_app/domain/album.dart';
import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/ui/albums/album_details_content.dart';
import 'package:esketit_music_app/ui/shared/screen_skeleton.dart';
import 'package:esketit_music_app/use_case/catalog/bloc/catalog_bloc.dart';
import 'package:esketit_music_app/use_case/player/bloc/player_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AlbumDetailsScreen extends StatefulWidget {
  const AlbumDetailsScreen({required this.album, super.key});

  final Album album;

  @override
  State<AlbumDetailsScreen> createState() => _AlbumDetailsScreenState();
}

class _AlbumDetailsScreenState extends State<AlbumDetailsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CatalogBloc>().add(LoadAlbumTracks(widget.album));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      buildWhen: (previous, current) =>
          previous.selectedTrack != current.selectedTrack,
      builder: (context, playerState) {
        final selectedTrackExists = playerState.selectedTrack != null;

        return ScreenSkeleton(
          appBar: AppBar(title: Text(widget.album.title)),
          body: BlocBuilder<CatalogBloc, CatalogState>(
            builder: (context, state) {
              final tracks = state.tracksByAlbumId[widget.album.id];
              final isLoading = state.loadingAlbumIds.contains(widget.album.id);
              final errorMessage =
                  state.albumTracksErrorMessages[widget.album.id];

              if (isLoading && tracks == null) {
                return const Center(child: CircularProgressIndicator());
              }

              if (errorMessage != null && tracks == null) {
                return Center(child: Text(errorMessage));
              }

              final safeTracks = tracks ?? const <Track>[];

              return AlbumDetailsContent(
                album: widget.album,
                tracks: safeTracks,
                selectedTrackExists: selectedTrackExists,
              );
            },
          ),
        );
      },
    );
  }
}
