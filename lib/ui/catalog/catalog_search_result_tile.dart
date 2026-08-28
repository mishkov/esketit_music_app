import 'package:esketit_music_app/domain/catalog_search_result.dart';
import 'package:esketit_music_app/ui/catalog/album_search_tile.dart';
import 'package:esketit_music_app/ui/catalog/author_search_tile.dart';
import 'package:esketit_music_app/ui/catalog/playlist_search_tile.dart';
import 'package:esketit_music_app/ui/tracks/track_list_card.dart';
import 'package:esketit_music_app/use_case/player/autoplay_storage.dart';
import 'package:flutter/material.dart';

class CatalogSearchResultTile extends StatelessWidget {
  const CatalogSearchResultTile({
    required this.result,
    required this.onTap,
    super.key,
  });

  final CatalogSearchResultItem result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return switch (result.type) {
      CatalogSearchResultType.author => AuthorSearchTile(
        author: result.author!,
        onTap: onTap,
      ),
      CatalogSearchResultType.album => AlbumSearchTile(
        album: result.album!,
        onTap: onTap,
      ),
      CatalogSearchResultType.track => TrackListCard(
        track: result.track!,
        queue: [result.track!],
        showImage: true,
        onTap: onTap,
        autoplayContext: AutoplayContext(
          sourceType: AutoplaySourceType.track,
          sourceId: result.track!.id,
        ),
      ),
      CatalogSearchResultType.playlist => PlaylistSearchTile(
        playlist: result.playlist!,
        onTap: onTap,
      ),
    };
  }
}
