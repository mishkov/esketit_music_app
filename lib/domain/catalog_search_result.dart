import 'package:equatable/equatable.dart';
import 'package:esketit_music_app/domain/album.dart';
import 'package:esketit_music_app/domain/author.dart';
import 'package:esketit_music_app/domain/track.dart';

enum CatalogSearchResultType { author, album, track }

class CatalogSearchResultItem extends Equatable {
  final CatalogSearchResultType type;
  final Author? author;
  final Album? album;
  final Track? track;

  const CatalogSearchResultItem._({
    required this.type,
    this.author,
    this.album,
    this.track,
  });

  const CatalogSearchResultItem.author(Author author)
    : this._(type: CatalogSearchResultType.author, author: author);

  const CatalogSearchResultItem.album(Album album)
    : this._(type: CatalogSearchResultType.album, album: album);

  const CatalogSearchResultItem.track(Track track)
    : this._(type: CatalogSearchResultType.track, track: track);

  @override
  List<Object?> get props => [type, author, album, track];
}

class PaginatedCatalogSearchResults extends Equatable {
  final List<CatalogSearchResultItem> items;
  final int page;
  final int pageSize;
  final int totalItems;
  final int totalPages;

  const PaginatedCatalogSearchResults({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalItems,
    required this.totalPages,
  });

  @override
  List<Object> get props => [items, page, pageSize, totalItems, totalPages];
}
