import 'package:esketit_music_app/domain/author.dart';
import 'package:esketit_music_app/ui/authors/author_details_screen.dart';
import 'package:esketit_music_app/ui/player/bottom_player.dart';
import 'package:esketit_music_app/ui/shared/remote_image.dart';
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
    return BlocBuilder<PlayerBloc, PlayerState>(
      builder: (context, playerState) {
        final selectedTrackExists = playerState.selectedTrack != null;
        return Stack(
          children: [
            BlocBuilder<CatalogBloc, CatalogState>(
              builder: (context, state) {
                if (state.isLoadingAuthors && state.authors.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.authorsErrorMessage != null &&
                    state.authors.isEmpty) {
                  return Center(child: Text(state.authorsErrorMessage!));
                }

                if (state.authors.isEmpty) {
                  return const Center(child: Text('No published authors yet.'));
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
                      'Featured Authors',
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
                        itemBuilder: (context, index) {
                          final author = state.authors[index];
                          return SizedBox(
                            width: 180,
                            child: _AuthorCard(author: author),
                          );
                        },
                      ),
                    ),
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
        );
      },
    );
  }
}

class _AuthorCard extends StatelessWidget {
  const _AuthorCard({required this.author});

  final Author author;

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AuthorDetailsScreen(author: author),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: RemoteImage(
                imageUrl: author.primaryPhotoUrl,
                icon: Icons.person_rounded,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                author.currentName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
