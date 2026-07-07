import 'package:esketit_music_app/domain/album.dart';
import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/authors/expanded_author_album_card.dart';
import 'package:esketit_music_app/use_case/catalog/bloc/catalog_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthorExpandedAlbumsSection extends StatefulWidget {
  const AuthorExpandedAlbumsSection({required this.albums, super.key});

  final List<Album> albums;

  @override
  State<AuthorExpandedAlbumsSection> createState() =>
      _AuthorExpandedAlbumsSectionState();
}

class _AuthorExpandedAlbumsSectionState
    extends State<AuthorExpandedAlbumsSection> {
  @override
  void initState() {
    super.initState();
    _loadMissingAlbumTracks();
  }

  @override
  void didUpdateWidget(AuthorExpandedAlbumsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadMissingAlbumTracks();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (widget.albums.isEmpty) {
      return Card.outlined(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.albumsTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(l10n.noPublishedAlbumsYet),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.albumsTitle, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        ...widget.albums.map((album) => ExpandedAuthorAlbumCard(album: album)),
      ],
    );
  }

  void _loadMissingAlbumTracks() {
    final catalogBloc = context.read<CatalogBloc>();
    final state = catalogBloc.state;
    for (final album in widget.albums) {
      if (state.tracksByAlbumId.containsKey(album.id) ||
          state.loadingAlbumIds.contains(album.id) ||
          state.albumTracksErrorMessages.containsKey(album.id)) {
        continue;
      }

      catalogBloc.add(LoadAlbumTracks(album));
    }
  }
}
