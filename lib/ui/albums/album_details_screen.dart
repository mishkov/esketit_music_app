import 'package:esketit_music_app/domain/album.dart';
import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/ui/player/bottom_player.dart';
import 'package:esketit_music_app/ui/shared/remote_image.dart';
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
    return BlocBuilder<PlayerBloc, PlayerState>(
      builder: (context, playerState) {
        final selectedTrackExists = playerState.selectedTrack != null;
        return Scaffold(
          appBar: AppBar(title: Text(widget.album.title)),
          body: Stack(
            children: [
              BlocBuilder<CatalogBloc, CatalogState>(
                builder: (context, state) {
                  final tracks = state.tracksByAlbumId[widget.album.id];
                  final isLoading = state.loadingAlbumIds.contains(
                    widget.album.id,
                  );
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
                        child: SizedBox(
                          height: 260,
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
                        'Tracks',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      if (safeTracks.isEmpty)
                        const Text('No tracks in this album yet.'),
                      ...safeTracks.asMap().entries.map((entry) {
                        return _TrackTile(
                          index: entry.key,
                          track: entry.value,
                          albumTracks: safeTracks,
                        );
                      }),
                    ],
                  );
                },
              ),
              if (selectedTrackExists)
                const Positioned(
                  bottom: 0,
                  right: 0,
                  left: 0,
                  child: BottomPlayer(),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TrackTile extends StatelessWidget {
  const _TrackTile({
    required this.index,
    required this.track,
    required this.albumTracks,
  });

  final int index;
  final Track track;
  final List<Track> albumTracks;

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(child: Text('${index + 1}')),
        title: Text(track.name),
        subtitle: Text(
          track.authors.map((author) => author.currentName).join(', '),
        ),
        trailing: const Icon(Icons.play_arrow_rounded),
        onTap: () {
          context.read<PlayerBloc>().add(PlayTrack(track, queue: albumTracks));
        },
      ),
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
