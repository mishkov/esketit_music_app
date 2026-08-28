import 'dart:convert';

import 'package:esketit_music_app/domain/album.dart';
import 'package:esketit_music_app/domain/author.dart';
import 'package:esketit_music_app/domain/catalog_search_result.dart';
import 'package:esketit_music_app/domain/file/abstract_file.dart';
import 'package:esketit_music_app/domain/file/local_file.dart';
import 'package:esketit_music_app/domain/playlist.dart';
import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/domain/track_info/text_track_info.dart';
import 'package:esketit_music_app/domain/track_info/track_info.dart';
import 'package:esketit_music_app/key_value_storage/shared/key_value_storage.dart';
import 'package:esketit_music_app/unassigned_layer/http_file.dart';
import 'package:esketit_music_app/use_case/catalog/recent_search_results_storage.dart';

class KeyValueRecentSearchResultsStorage implements RecentSearchResultsStorage {
  KeyValueRecentSearchResultsStorage({required KeyValueStorage keyValueStorage})
    : _keyValueStorage = keyValueStorage;

  static const String _recentSearchResultsKey =
      'catalog.recent_search_results.v1';
  static const int _maxRecentSearchResultsCount = 20;

  final KeyValueStorage _keyValueStorage;

  @override
  Future<List<CatalogSearchResultItem>> getRecentSearchResults() async {
    final storedValue = await _keyValueStorage.getString(
      _recentSearchResultsKey,
    );
    if (storedValue == null || storedValue.isEmpty) {
      return const [];
    }

    try {
      final decodedValue = jsonDecode(storedValue);
      if (decodedValue is! List) {
        return const [];
      }

      return decodedValue
          .whereType<Map>()
          .map((value) => _resultFromJson(Map<String, Object?>.from(value)))
          .whereType<CatalogSearchResultItem>()
          .take(_maxRecentSearchResultsCount)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<List<CatalogSearchResultItem>> saveRecentSearchResult(
    CatalogSearchResultItem result,
  ) async {
    final currentResults = await getRecentSearchResults();
    final nextResults = [
      result,
      ...currentResults.where(
        (currentResult) => !_hasSameIdentity(currentResult, result),
      ),
    ].take(_maxRecentSearchResultsCount).toList(growable: false);

    await _keyValueStorage.setString(
      _recentSearchResultsKey,
      jsonEncode(nextResults.map(_resultToJson).toList(growable: false)),
    );

    return nextResults;
  }

  bool _hasSameIdentity(
    CatalogSearchResultItem left,
    CatalogSearchResultItem right,
  ) {
    return left.type == right.type && _resultId(left) == _resultId(right);
  }

  int _resultId(CatalogSearchResultItem result) {
    return switch (result.type) {
      CatalogSearchResultType.author => result.author!.id,
      CatalogSearchResultType.album => result.album!.id,
      CatalogSearchResultType.track => result.track!.id,
      CatalogSearchResultType.playlist => result.playlist!.id,
    };
  }

  Map<String, Object?> _resultToJson(CatalogSearchResultItem result) {
    return {
      'type': result.type.name,
      'value': switch (result.type) {
        CatalogSearchResultType.author => _authorToJson(result.author!),
        CatalogSearchResultType.album => _albumToJson(result.album!),
        CatalogSearchResultType.track => _trackToJson(result.track!),
        CatalogSearchResultType.playlist => _playlistToJson(result.playlist!),
      },
    };
  }

  CatalogSearchResultItem? _resultFromJson(Map<String, Object?> json) {
    final value = _mapFrom(json['value']);
    if (value == null) {
      return null;
    }

    return switch (json['type']) {
      'author' => switch (_authorFromJson(value)) {
        final author? => CatalogSearchResultItem.author(author),
        null => null,
      },
      'album' => switch (_albumFromJson(value)) {
        final album? => CatalogSearchResultItem.album(album),
        null => null,
      },
      'track' => switch (_trackFromJson(value)) {
        final track? => CatalogSearchResultItem.track(track),
        null => null,
      },
      'playlist' => switch (_playlistFromJson(value)) {
        final playlist? => CatalogSearchResultItem.playlist(playlist),
        null => null,
      },
      _ => null,
    };
  }

  Map<String, Object?> _authorToJson(Author author) {
    return {
      'id': author.id,
      'currentName': author.currentName,
      'photos': author.photos,
    };
  }

  Author? _authorFromJson(Map<String, Object?> json) {
    final id = _intFrom(json['id']);
    final currentName = json['currentName'];
    if (id == null || id <= 0 || currentName is! String) {
      return null;
    }

    return Author(
      id: id,
      currentName: currentName,
      photos: _stringListFrom(json['photos']),
    );
  }

  Map<String, Object?> _albumToJson(Album album) {
    return {
      'id': album.id,
      'title': album.title,
      'coverImage': _fileToJson(album.coverImage),
      'authorIds': album.authorIds,
      'releaseDate': album.releaseDate?.toIso8601String(),
      'isPublished': album.isPublished,
      'trackIds': album.trackIds,
      'additionalInfo': album.additionalInfo
          .map(_trackInfoToJson)
          .whereType<Map<String, Object?>>()
          .toList(growable: false),
    };
  }

  Album? _albumFromJson(Map<String, Object?> json) {
    final id = _intFrom(json['id']);
    final title = json['title'];
    final coverImage = _fileFromJson(_mapFrom(json['coverImage']));
    if (id == null || id <= 0 || title is! String || coverImage == null) {
      return null;
    }

    return Album(
      id: id,
      title: title,
      coverImage: coverImage,
      authorIds: _intListFrom(json['authorIds']),
      releaseDate: _dateTimeFrom(json['releaseDate']),
      isPublished: json['isPublished'] is bool
          ? json['isPublished']! as bool
          : false,
      trackIds: _intListFrom(json['trackIds']),
      additionalInfo: _trackInfoListFrom(json['additionalInfo']),
    );
  }

  Map<String, Object?> _trackToJson(Track track) {
    return {
      'id': track.id,
      'albumId': track.albumId,
      'name': track.name,
      'authors': track.authors.map(_authorToJson).toList(growable: false),
      'additionalInfo': track.addionalInfo
          .map(_trackInfoToJson)
          .whereType<Map<String, Object?>>()
          .toList(growable: false),
      'file': _fileToJson(track.file),
      'image': _fileToJson(track.image),
      'isFavorite': track.isFavorite,
      'isDisliked': track.isDisliked,
      'isAvailable': track.isAvailable,
      'createdAt': track.createdAt?.toIso8601String(),
    };
  }

  Track? _trackFromJson(Map<String, Object?> json) {
    final id = _intFrom(json['id']);
    final name = json['name'];
    final file = _fileFromJson(_mapFrom(json['file']));
    final image = _fileFromJson(_mapFrom(json['image']));
    if (id == null ||
        id <= 0 ||
        name is! String ||
        file == null ||
        image == null) {
      return null;
    }

    return Track(
      id: id,
      albumId: _intFrom(json['albumId']),
      name: name,
      authors: _mapListFrom(
        json['authors'],
      ).map(_authorFromJson).whereType<Author>().toList(growable: false),
      addionalInfo: _trackInfoListFrom(json['additionalInfo']),
      file: file,
      image: image,
      isFavorite: json['isFavorite'] is bool
          ? json['isFavorite']! as bool
          : false,
      isDisliked: json['isDisliked'] is bool
          ? json['isDisliked']! as bool
          : false,
      isAvailable: json['isAvailable'] is bool
          ? json['isAvailable']! as bool
          : true,
      createdAt: _dateTimeFrom(json['createdAt']),
    );
  }

  Map<String, Object?> _playlistToJson(Playlist playlist) {
    return {
      'id': playlist.id,
      'userId': playlist.userId,
      'name': playlist.name,
      'description': playlist.description,
      'coverImagePath': playlist.coverImagePath,
      'visibility': playlist.visibility.name,
      'trackCount': playlist.trackCount,
      'system': playlist.system,
      'kind': playlist.kind.name,
      'shareToken': playlist.shareToken,
    };
  }

  Playlist? _playlistFromJson(Map<String, Object?> json) {
    final id = _intFrom(json['id']);
    final userId = _intFrom(json['userId']);
    final name = json['name'];
    final description = json['description'];
    final coverImagePath = json['coverImagePath'];
    final visibility = _enumFromName(
      PlaylistVisibility.values,
      json['visibility'],
    );
    final trackCount = _intFrom(json['trackCount']);
    final kind = _enumFromName(PlaylistKind.values, json['kind']);
    if (id == null ||
        id <= 0 ||
        userId == null ||
        name is! String ||
        description is! String ||
        coverImagePath is! String ||
        visibility == null ||
        trackCount == null ||
        kind == null) {
      return null;
    }

    return Playlist(
      id: id,
      userId: userId,
      name: name,
      description: description,
      coverImagePath: coverImagePath,
      visibility: visibility,
      trackCount: trackCount,
      system: json['system'] is bool ? json['system']! as bool : false,
      kind: kind,
      shareToken: json['shareToken'] as String?,
    );
  }

  Map<String, Object?> _fileToJson(AbstractFile file) {
    return switch (file) {
      HttpFile(:final uri) => {'type': 'http', 'value': uri.toString()},
      LocalFile(:final path) => {'type': 'local', 'value': path},
      _ => {'type': 'unsupported', 'value': ''},
    };
  }

  AbstractFile? _fileFromJson(Map<String, Object?>? json) {
    final value = json?['value'];
    if (value is! String) {
      return null;
    }

    return switch (json?['type']) {
      'http' => HttpFile(uri: Uri.tryParse(value) ?? Uri()),
      'local' => LocalFile(path: value),
      _ => null,
    };
  }

  Map<String, Object?>? _trackInfoToJson(TrackInfo trackInfo) {
    return switch (trackInfo) {
      TextTrackInfo(:final title, :final text) => {
        'type': 'text',
        'title': title,
        'text': text,
      },
      _ => null,
    };
  }

  List<TrackInfo> _trackInfoListFrom(Object? value) {
    return _mapListFrom(value)
        .map((json) {
          return switch (json['type']) {
            'text' when json['title'] is String && json['text'] is String =>
              TextTrackInfo(
                title: json['title']! as String,
                text: json['text']! as String,
              ),
            _ => null,
          };
        })
        .whereType<TrackInfo>()
        .toList(growable: false);
  }

  Map<String, Object?>? _mapFrom(Object? value) {
    return value is Map ? Map<String, Object?>.from(value) : null;
  }

  List<Map<String, Object?>> _mapListFrom(Object? value) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map>()
        .map((item) => Map<String, Object?>.from(item))
        .toList(growable: false);
  }

  int? _intFrom(Object? value) {
    return value is num ? value.toInt() : null;
  }

  List<int> _intListFrom(Object? value) {
    return value is List
        ? value.map(_intFrom).whereType<int>().toList(growable: false)
        : const [];
  }

  List<String> _stringListFrom(Object? value) {
    return value is List
        ? value.whereType<String>().toList(growable: false)
        : const [];
  }

  DateTime? _dateTimeFrom(Object? value) {
    return value is String ? DateTime.tryParse(value) : null;
  }

  T? _enumFromName<T extends Enum>(List<T> values, Object? value) {
    if (value is! String) {
      return null;
    }

    for (final enumValue in values) {
      if (enumValue.name == value) {
        return enumValue;
      }
    }

    return null;
  }
}
