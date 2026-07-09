import 'dart:convert';

import 'package:esketit_music_app/domain/author.dart';
import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/errors/http_app_error.dart';
import 'package:esketit_music_app/esketit_rest_api/esketit_rest_api_url_resolver.dart';
import 'package:esketit_music_app/esketit_rest_api/http_client.dart';
import 'package:esketit_music_app/esketit_rest_api/http_response.dart';
import 'package:esketit_music_app/unassigned_layer/http_file.dart';
import 'package:esketit_music_app/use_case/player/autoplay_storage.dart';

class EsketitRestApiAutoplayStorage implements AutoplayStorage {
  EsketitRestApiAutoplayStorage({
    required HttpClient httpClient,
    required Uri baseUri,
  }) : _httpClient = httpClient,
       _baseUri = baseUri;

  final HttpClient _httpClient;
  final Uri _baseUri;
  final Map<int, Uri> _albumCoverUriByAlbumId = <int, Uri>{};

  @override
  Future<AutoplayTracksBatch> getNextTracks({
    required AutoplayContext context,
    required int count,
    required List<int> recentTrackIds,
    required List<int> excludedTrackIds,
  }) async {
    final authorsResponse = await _httpClient.get('/authors');
    _throwIfNotSuccess(authorsResponse, '/authors');
    final authorsById = _parseAuthorsById(authorsResponse.response);

    const path = '/autoplay/next';
    final response = await _httpClient.post(
      path,
      body: {
        'sourceType': _toApiSourceType(context.sourceType),
        if (context.sourceId != null) 'sourceId': context.sourceId,
        'profile': context.profile,
        'count': count,
        'recentTrackIds': recentTrackIds,
        'excludedTrackIds': excludedTrackIds,
      },
    );
    _throwIfNotSuccess(response, path);

    final body = _decodeJsonMap(response.response, path: path);
    final trackItems = ((body['tracks'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
    await _loadAlbumCovers(trackItems);

    return AutoplayTracksBatch(
      context: context,
      strategy: (body['strategy'] as String?) ?? '',
      tracks: trackItems
          .map((item) => _parseTrack(item, authorsById: authorsById))
          .where((track) => track.id > 0)
          .toList(growable: false),
    );
  }

  Track _parseTrack(
    Map<String, dynamic> item, {
    required Map<int, Author> authorsById,
  }) {
    final authorItems = ((item['authors'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(_parseAuthor)
        .where((author) => author.id > 0)
        .toList(growable: false);
    final fallbackAuthors = ((item['authorIds'] as List?) ?? const [])
        .map(_asInt)
        .whereType<int>()
        .map(
          (authorId) =>
              authorsById[authorId] ??
              Author(
                id: authorId,
                currentName: 'Author #$authorId',
                photos: const [],
              ),
        )
        .toList(growable: false);

    return Track(
      id: _asInt(item['id']) ?? 0,
      name: (item['name'] as String?) ?? '',
      authors: authorItems.isNotEmpty ? authorItems : fallbackAuthors,
      addionalInfo: const [],
      file: HttpFile(
        uri: _resolveSongUri((item['audioFilePath'] as String?) ?? ''),
      ),
      image: HttpFile(uri: _resolveTrackImageUri(item)),
      isFavorite: (item['isFavorite'] as bool?) ?? false,
      isAvailable: (item['isAvailable'] as bool?) ?? true,
    );
  }

  Author _parseAuthor(Map<String, dynamic> item) {
    return Author(
      id: _asInt(item['id']) ?? 0,
      currentName: (item['currentName'] as String?) ?? '',
      photos: ((item['photos'] as List?) ?? const [])
          .whereType<String>()
          .map(_resolveAuthorPhotoUrl)
          .toList(growable: false),
    );
  }

  Uri _resolveTrackImageUri(Map<String, dynamic> item) {
    final rawPath =
        (item['imagePath'] as String?) ??
        (item['coverImagePath'] as String?) ??
        (item['albumImagePath'] as String?) ??
        '';
    if (rawPath.isNotEmpty) {
      return _resolveAlbumCoverUri(rawPath);
    }

    final albumId = _asInt(item['albumId']);
    if (albumId == null) {
      return Uri();
    }

    return _albumCoverUriByAlbumId[albumId] ?? Uri();
  }

  Uri _resolveAlbumCoverUri(String coverImagePath) {
    return resolveEsketitRestApiUrl(
      _baseUri,
      coverImagePath,
      fallbackDirectory: 'album-covers',
    );
  }

  Future<void> _loadAlbumCovers(List<Map<String, dynamic>> trackItems) async {
    final missingAlbumIds = trackItems
        .map((item) => _asInt(item['albumId']))
        .whereType<int>()
        .where((albumId) => !_albumCoverUriByAlbumId.containsKey(albumId))
        .toSet();
    if (missingAlbumIds.isEmpty) {
      return;
    }

    final albumEntries = await Future.wait(
      missingAlbumIds.map(_loadAlbumCoverEntry),
    );
    for (final entry in albumEntries) {
      if (entry == null) {
        continue;
      }

      _albumCoverUriByAlbumId[entry.albumId] = entry.coverUri;
    }
  }

  Future<_AlbumCoverEntry?> _loadAlbumCoverEntry(int albumId) async {
    final path = '/albums/$albumId';
    final response = await _httpClient.get(path);
    _throwIfNotSuccess(response, path);

    final body = _decodeJsonMap(response.response, path: path);

    return _AlbumCoverEntry(
      albumId: albumId,
      coverUri: _resolveAlbumCoverUri(
        (body['coverImagePath'] as String?) ?? '',
      ),
    );
  }

  Uri _resolveSongUri(String audioFilePath) {
    return resolveEsketitRestApiUrl(_baseUri, audioFilePath);
  }

  String _resolveAuthorPhotoUrl(String value) {
    return resolveEsketitRestApiUrlString(
      _baseUri,
      value,
      fallbackDirectory: 'author-photos',
    );
  }

  static void _throwIfNotSuccess(HttpResponse response, String path) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    if (response.statusCode == 401) {
      throw UnauthorizedAppError(path: path, responseBody: response.response);
    }
    if (response.statusCode == 403) {
      throw ForbiddenAppError(path: path, responseBody: response.response);
    }

    throw HttpAppError(
      message: 'Request failed',
      path: path,
      statusCode: response.statusCode,
      responseBody: response.response,
    );
  }

  static Map<String, dynamic> _decodeJsonMap(
    Object? body, {
    required String path,
  }) {
    final decoded = _coerceJson(body);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('Expected JSON object response for $path');
    }

    return decoded;
  }

  static Object? _coerceJson(Object? body) {
    if (body is String) {
      return jsonDecode(body);
    }

    return body;
  }

  Map<int, Author> _parseAuthorsById(Object? responseBody) {
    final body = _coerceJson(responseBody);
    if (body is! List) {
      throw const FormatException(
        'Expected /authors response to be a JSON list',
      );
    }

    final result = <int, Author>{};
    for (final item in body.whereType<Map<String, dynamic>>()) {
      final id = _asInt(item['id']);
      if (id == null) {
        continue;
      }

      result[id] = Author(
        id: id,
        currentName: (item['currentName'] as String?) ?? '',
        photos: ((item['photos'] as List?) ?? const [])
            .whereType<String>()
            .map(_resolveAuthorPhotoUrl)
            .toList(growable: false),
      );
    }

    return result;
  }

  static int? _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse('$value');
  }

  static String _toApiSourceType(AutoplaySourceType sourceType) {
    return switch (sourceType) {
      AutoplaySourceType.myVibe => 'my_vibe',
      AutoplaySourceType.playlist => 'playlist',
      AutoplaySourceType.album => 'album',
      AutoplaySourceType.track => 'track',
    };
  }
}

class _AlbumCoverEntry {
  const _AlbumCoverEntry({required this.albumId, required this.coverUri});

  final int albumId;
  final Uri coverUri;
}
