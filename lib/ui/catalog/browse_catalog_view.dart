import 'package:esketit_music_app/domain/author.dart';
import 'package:esketit_music_app/ui/catalog/author_browse_card.dart';
import 'package:esketit_music_app/use_case/catalog/bloc/catalog_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BrowseCatalogView extends StatelessWidget {
  const BrowseCatalogView({required this.selectedTrackExists, super.key});

  final bool selectedTrackExists;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CatalogBloc, CatalogState>(
      builder: (context, state) {
        if (state.isLoadingAuthors && state.authors.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.authorsErrorMessage != null && state.authors.isEmpty) {
          return Center(child: Text(state.authorsErrorMessage!));
        }

        if (state.authors.isEmpty) {
          return const Center(child: Text('No published authors yet.'));
        }

        return ListView(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
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
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) =>
                    _buildAuthorCard(state.authors[index]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAuthorCard(Author author) {
    return SizedBox(width: 180, child: AuthorBrowseCard(author: author));
  }
}
