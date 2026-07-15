import 'dart:async';

import 'package:esketit_music_app/domain/author.dart';
import 'package:esketit_music_app/errors/error_reporter/breadcrumb.dart';
import 'package:esketit_music_app/errors/error_reporter/category.dart';
import 'package:esketit_music_app/errors/error_reporter/error_reporter.dart';
import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/auth/login_required_prompt_scope.dart';
import 'package:esketit_music_app/ui/catalog/author_card.dart';
import 'package:esketit_music_app/ui/catalog/authors_screen.dart';
import 'package:esketit_music_app/ui/tracks/last_added_tracks_section.dart';
import 'package:esketit_music_app/use_case/auth/bloc/auth_bloc.dart';
import 'package:esketit_music_app/use_case/catalog/bloc/catalog_bloc.dart';
import 'package:esketit_music_app/use_case/player/autoplay_storage.dart';
import 'package:esketit_music_app/use_case/player/bloc/player_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CatalogBrowseScreen extends StatefulWidget {
  const CatalogBrowseScreen({super.key});

  @override
  State<CatalogBrowseScreen> createState() => _CatalogBrowseScreenState();
}

class _CatalogBrowseScreenState extends State<CatalogBrowseScreen> {
  static const int _featuredAuthorsLimit = 10;

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
            return ListView(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: selectedTrackExists ? 100 : 16,
              ),
              children: [
                Align(
                  child: FilledButton.icon(
                    onPressed: () => _playMyVibe(context),
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: Text(l10n.playMyVibeButton),
                  ),
                ),
                const SizedBox(height: 24),
                const LastAddedTracksSection(),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.featuredAuthorsTitle,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    if (state.authors.length > _featuredAuthorsLimit)
                      TextButton.icon(
                        onPressed: () => _openAuthorsScreen(context),
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: Text(l10n.viewMoreButton),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildAuthorsSection(context, state),
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

  Widget _buildAuthorsSection(BuildContext context, CatalogState state) {
    final l10n = context.l10n;

    if (state.isLoadingAuthors && state.authors.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.authorsErrorMessage != null && state.authors.isEmpty) {
      return Text(state.authorsErrorMessage!);
    }

    if (state.authors.isEmpty) {
      return Text(l10n.noPublishedAuthorsYet);
    }

    final featuredAuthors = state.authors.take(_featuredAuthorsLimit).toList();

    return SizedBox(
      height: 240,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: featuredAuthors.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) =>
            _buildAuthorCard(featuredAuthors[index]),
      ),
    );
  }

  void _playMyVibe(BuildContext context) {
    if (!context.read<AuthBloc>().state.isAuthenticated) {
      LoginRequiredPromptScope.of(context).show();

      return;
    }

    context.read<PlayerBloc>().add(
      const StartAutoplayPlaybackRequested(AutoplayContext.myVibe()),
    );
  }

  void _openAuthorsScreen(BuildContext context) {
    unawaited(
      context.read<ErrorReporter>().addBreadcrumb(
        Breadcrumb(
          message: 'Open all authors screen',
          category: Category.uiClick,
          data: {'sourceScreen': 'home'},
        ),
      ),
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => const AuthorsScreen()),
    );
  }
}
