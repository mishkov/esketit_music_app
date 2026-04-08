import 'package:esketit_music_app/domain/album.dart';
import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/shared/remote_image.dart';
import 'package:esketit_music_app/ui/shared/screen_skeleton.dart';
import 'package:esketit_music_app/ui/tracks/track_list_card.dart';
import 'package:esketit_music_app/unassigned_layer/http_file.dart';
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
    final l10n = context.l10n;

    return BlocBuilder<PlayerBloc, PlayerState>(
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

              return ListView(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: selectedTrackExists ? 100 : 16,
                ),
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: RemoteImage(
                        imageUrl: _albumCoverUrl(widget.album),
                        icon: Icons.album_rounded,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.album.title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.tracksTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (safeTracks.isEmpty) Text(l10n.noTracksInAlbumYet),
                  ...safeTracks.asMap().entries.map((entry) {
                    return TrackListCard(
                      track: entry.value,
                      queue: safeTracks
                          .where((track) => track.isAvailable)
                          .toList(growable: false),
                      indexLabel: CircleAvatar(child: Text('${entry.key + 1}')),
                    );
                  }),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

String? _albumCoverUrl(Album album) {
  final cover = album.coverImage;
  if (cover is! HttpFile) {
    return null;
  }
  final value = cover.uri.toString();

  return value.isEmpty ? null : value;
}
