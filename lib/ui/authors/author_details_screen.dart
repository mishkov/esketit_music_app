import 'package:esketit_music_app/domain/album.dart';
import 'package:esketit_music_app/domain/author.dart';
import 'package:esketit_music_app/ui/authors/author_details_content.dart';
import 'package:esketit_music_app/ui/authors/author_details_menu.dart';
import 'package:esketit_music_app/ui/shared/screen_skeleton.dart';
import 'package:esketit_music_app/use_case/catalog/bloc/catalog_bloc.dart';
import 'package:esketit_music_app/use_case/player/bloc/player_bloc.dart';
import 'package:esketit_music_app/use_case/settings/bloc/settings_bloc.dart';
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
      buildWhen: (previous, current) =>
          previous.selectedTrack != current.selectedTrack,
      builder: (context, playerState) {
        final selectedTrackExists = playerState.selectedTrack != null;

        return ScreenSkeleton(
          appBar: AppBar(
            title: Text(widget.author.currentName),
            actions: const [AuthorDetailsMenu()],
          ),
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

              return BlocBuilder<SettingsBloc, SettingsState>(
                buildWhen: (previous, current) =>
                    previous.authorAlbumsDisplayMode !=
                    current.authorAlbumsDisplayMode,
                builder: (context, settingsState) {
                  return AuthorDetailsContent(
                    author: widget.author,
                    albums: safeAlbums,
                    selectedTrackExists: selectedTrackExists,
                    albumsDisplayMode: settingsState.authorAlbumsDisplayMode,
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
