import 'package:esketit_music_app/domain/album.dart';
import 'package:esketit_music_app/domain/author.dart';
import 'package:esketit_music_app/ui/albums/album_details_screen.dart';
import 'package:esketit_music_app/ui/player/bottom_player.dart';
import 'package:esketit_music_app/ui/shared/remote_image.dart';
import 'package:esketit_music_app/ui/shared/screen_skeleton.dart';
import 'package:esketit_music_app/unassigned_layer/http_file.dart';
import 'package:esketit_music_app/use_case/catalog/bloc/catalog_bloc.dart';
import 'package:esketit_music_app/use_case/player/bloc/player_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthorDetailsScreen extends StatefulWidget {
  const AuthorDetailsScreen({required this.author, super.key});

  final Author author;

  @override
  State<AuthorDetailsScreen> createState() => _AuthorDetailsScreenState();
}

class _AuthorDetailsScreenState extends State<AuthorDetailsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CatalogBloc>().add(LoadPublishedAlbumsByAuthor(widget.author));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      builder: (context, playerState) {
        final selectedTrackExists = playerState.selectedTrack != null;

        return ScreenSkeleton(
          appBar: AppBar(title: Text(widget.author.currentName)),
          body: Stack(
            children: [
              BlocBuilder<CatalogBloc, CatalogState>(
                builder: (context, state) {
                  final albums = state.albumsByAuthorId[widget.author.id];
                  final isLoading = state.loadingAuthorIds.contains(
                    widget.author.id,
                  );
                  final errorMessage =
                      state.authorAlbumsErrorMessages[widget.author.id];

                  if (isLoading && albums == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (errorMessage != null && albums == null) {
                    return Center(child: Text(errorMessage));
                  }

                  final safeAlbums = albums ?? const <Album>[];

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
                            imageUrl: widget.author.primaryPhotoUrl,
                            icon: Icons.person_rounded,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.author.currentName,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Albums',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      if (safeAlbums.isEmpty)
                        const Text('No published albums yet.'),
                      ...safeAlbums.map((album) => _AlbumTile(album: album)),
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

class _AlbumTile extends StatelessWidget {
  const _AlbumTile({required this.album});

  final Album album;

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox.square(
            dimension: 56,
            child: RemoteImage(
              imageUrl: _albumCoverUrl(album),
              icon: Icons.album_rounded,
            ),
          ),
        ),
        title: Text(album.title),
        subtitle: Text(
          album.releaseDate == null
              ? 'Release date unknown'
              : _formatReleaseDate(album.releaseDate!),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AlbumDetailsScreen(album: album),
            ),
          );
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

String _formatReleaseDate(DateTime releaseDate) {
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
