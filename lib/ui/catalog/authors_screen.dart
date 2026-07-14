import 'package:esketit_music_app/domain/author.dart';
import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/catalog/author_card.dart';
import 'package:esketit_music_app/ui/shared/screen_skeleton.dart';
import 'package:esketit_music_app/use_case/catalog/bloc/catalog_bloc.dart';
import 'package:esketit_music_app/use_case/player/bloc/player_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthorsScreen extends StatefulWidget {
  const AuthorsScreen({super.key});

  @override
  State<AuthorsScreen> createState() => _AuthorsScreenState();
}

class _AuthorsScreenState extends State<AuthorsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CatalogBloc>().add(LoadPublishedAuthors());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ScreenSkeleton(
      appBar: AppBar(title: Text(l10n.authorsTitle)),
      body: BlocBuilder<PlayerBloc, PlayerState>(
        buildWhen: (previous, current) =>
            previous.selectedTrack != current.selectedTrack,
        builder: (context, playerState) {
          final selectedTrackExists = playerState.selectedTrack != null;

          return BlocBuilder<CatalogBloc, CatalogState>(
            builder: (context, state) {
              if (state.isLoadingAuthors && state.authors.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state.authorsErrorMessage != null && state.authors.isEmpty) {
                return Center(child: Text(state.authorsErrorMessage!));
              }

              if (state.authors.isEmpty) {
                return Center(child: Text(l10n.noPublishedAuthorsYet));
              }

              return GridView.builder(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: selectedTrackExists ? 100 : 16,
                ),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  mainAxisExtent: 240,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemCount: state.authors.length,
                itemBuilder: (context, index) =>
                    _buildAuthorCard(state.authors[index]),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAuthorCard(Author author) {
    return AuthorCard(author: author);
  }
}
