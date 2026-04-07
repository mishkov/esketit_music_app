import 'package:esketit_music_app/domain/album.dart';
import 'package:esketit_music_app/domain/author.dart';
import 'package:esketit_music_app/ui/authors/album_tile.dart';
import 'package:esketit_music_app/ui/shared/remote_image.dart';
import 'package:esketit_music_app/ui/shared/screen_skeleton.dart';
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
          body: BlocBuilder<CatalogBloc, CatalogState>(
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
                    child: AspectRatio(
                      aspectRatio: 1,
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
                  Text('Albums', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  if (safeAlbums.isEmpty)
                    const Text('No published albums yet.'),
                  ...safeAlbums.map((album) => AlbumTile(album: album)),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
