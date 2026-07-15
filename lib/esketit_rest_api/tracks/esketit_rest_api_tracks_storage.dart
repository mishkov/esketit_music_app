import 'dart:convert';

import 'package:esketit_music_app/domain/author.dart';
import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/errors/error_reporter/app_error.dart';
import 'package:esketit_music_app/errors/http_app_error.dart';
import 'package:esketit_music_app/esketit_rest_api/esketit_rest_api_url_resolver.dart';
import 'package:esketit_music_app/esketit_rest_api/http_client.dart';
import 'package:esketit_music_app/esketit_rest_api/http_response.dart';
import 'package:esketit_music_app/unassigned_layer/http_file.dart';
import 'package:esketit_music_app/use_case/tracks/tracks_storage.dart';

class EsketitRestApiTracksStorage implements TracksStorage {
  final HttpClient _httpClient;
  final Uri _baseUri;

  const EsketitRestApiTracksStorage({
    required HttpClient httpClient,
    required Uri baseUri,
  }) : _httpClient = httpClient,
       _baseUri = baseUri;

  @override
  Future<PaginatedTracks> getTracks({
    required int page,
    required int pageSize,
    TracksSort sort = TracksSort.id,
    TracksSortOrder order = TracksSortOrder.ascending,
  }) async {
    final authorsResponse = await _httpClient.get('/authors');
    _throwIfNotSuccess(authorsResponse, '/authors');

    final tracksPath = Uri(
      path: '/tracks',
      queryParameters: {
        'page': '$page',
        'pageSize': '$pageSize',
        'sort': _toSortParameter(sort),
        'order': _toOrderParameter(order),
      },
    ).toString();
    final tracksResponse = await _httpClient.get(tracksPath);
    _throwIfNotSuccess(tracksResponse, '/tracks');

    final authorsById = _parseAuthorsById(authorsResponse.response);

    return _parseTracksPage(tracksResponse.response, authorsById);
  }

  void _throwIfNotSuccess(HttpResponse response, String path) {
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

  Map<int, Author> _parseAuthorsById(Object? responseBody) {
    final body = _coerceJson(responseBody);
    if (body is! List) {
      throw AppError(
        'Expected /authors response to be a JSON list',
        cause: body,
      );
    }

    final result = <int, Author>{};
    for (final item in body) {
      if (item is! Map<String, dynamic>) {
        continue;
      }
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

  PaginatedTracks _parseTracksPage(
    Object? responseBody,
    Map<int, Author> authorsById,
  ) {
    final body = _coerceJson(responseBody);
    if (body is List) {
      final tracks = _parseTracks(body, authorsById);

      return PaginatedTracks(
        items: tracks,
        page: 1,
        pageSize: tracks.length,
        totalItems: tracks.length,
        totalPages: tracks.isEmpty ? 0 : 1,
      );
    }

    if (body is! Map<String, dynamic>) {
      throw AppError(
        'Expected /tracks response to be a JSON object',
        cause: body,
      );
    }

    final items = body['items'];
    final tracks = items is List
        ? _parseTracks(items, authorsById)
        : const <Track>[];

    return PaginatedTracks(
      items: tracks,
      page: _asInt(body['page']) ?? 1,
      pageSize: _asInt(body['pageSize']) ?? tracks.length,
      totalItems: _asInt(body['totalItems']) ?? tracks.length,
      totalPages: _asInt(body['totalPages']) ?? (tracks.isEmpty ? 0 : 1),
    );
  }

  List<Track> _parseTracks(Object? responseBody, Map<int, Author> authorsById) {
    final body = _coerceJson(responseBody);
    if (body is! List) {
      throw AppError(
        'Expected /tracks response to be a JSON list',
        cause: body,
      );
    }

    final tracks = <Track>[];
    for (final item in body) {
      if (item is! Map<String, dynamic>) {
        continue;
      }

      final name = (item['name'] as String?) ?? '';
      final audioFilePath = (item['audioFilePath'] as String?) ?? '';
      final albumImagePath =
          (item['imagePath'] as String?) ??
          (item['coverImagePath'] as String?) ??
          (item['albumImagePath'] as String?) ??
          '';
      final authorIds = item['authorIds'];

      final authors = ((item['authors'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(_parseAuthor)
          .where((author) => author.id > 0)
          .toList(growable: false);
      final fallbackAuthors = <Author>[];
      if (authorIds is List) {
        for (final authorIdValue in authorIds) {
          final authorId = _asInt(authorIdValue);
          if (authorId == null) {
            continue;
          }

          final author = authorsById[authorId];
          if (author != null) {
            fallbackAuthors.add(author);
            continue;
          }

          fallbackAuthors.add(
            Author(
              id: authorId,
              currentName: 'Author #$authorId',
              photos: const [],
            ),
          );
        }
      }

      tracks.add(
        Track(
          id: _asInt(item['id']) ?? 0,
          name: name,
          authors: authors.isNotEmpty ? authors : fallbackAuthors,
          addionalInfo: const [],
          file: HttpFile(uri: _resolveSongUri(audioFilePath)),
          image: HttpFile(uri: _resolveAlbumCoverUri(albumImagePath)),
          isFavorite: (item['isFavorite'] as bool?) ?? false,
          isAvailable: (item['isAvailable'] as bool?) ?? true,
        ),
      );
    }

    return tracks;
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

  Uri _resolveAlbumCoverUri(String coverImagePath) {
    return resolveEsketitRestApiUrl(
      _baseUri,
      coverImagePath,
      fallbackDirectory: 'album-covers',
    );
  }

  Uri _resolveSongUri(String audioFilePath) {
    return resolveEsketitRestApiUrl(
      _baseUri,
      audioFilePath,
      fallbackDirectory: 'songs',
    );
  }

  String _resolveAuthorPhotoUrl(String value) {
    return resolveEsketitRestApiUrlString(
      _baseUri,
      value,
      fallbackDirectory: 'author-photos',
    );
  }

  String _toSortParameter(TracksSort sort) {
    return switch (sort) {
      TracksSort.id => 'id',
      TracksSort.addedAt => 'createdAt',
    };
  }

  String _toOrderParameter(TracksSortOrder order) {
    return switch (order) {
      TracksSortOrder.ascending => 'asc',
      TracksSortOrder.descending => 'desc',
    };
  }

  static Object? _coerceJson(Object? body) {
    if (body is String) {
      return jsonDecode(body);
    }

    return body;
  }

  static int? _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }

    return null;
  }
}
