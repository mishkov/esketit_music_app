import 'package:esketit_music_app/domain/author.dart';
import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/catalog/author_card.dart';
import 'package:esketit_music_app/use_case/catalog/bloc/catalog_bloc.dart';
import 'package:esketit_music_app/use_case/player/bloc/player_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CatalogBrowseScreen extends StatefulWidget {
  const CatalogBrowseScreen({super.key});

  @override
  State<CatalogBrowseScreen> createState() => _CatalogBrowseScreenState();
}

class _CatalogBrowseScreenState extends State<CatalogBrowseScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CatalogBloc>().add(LoadPublishedAuthors());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<PlayerBloc, PlayerState>(
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

            return ListView(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: selectedTrackExists ? 100 : 16,
              ),
              children: [
                Text(
                  l10n.featuredAuthorsTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 240,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: state.authors.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 12),
                    itemBuilder: (context, index) =>
                        _buildAuthorCard(state.authors[index]),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildAuthorCard(Author author) {
    return SizedBox(width: 180, child: AuthorCard(author: author));
  }
}
