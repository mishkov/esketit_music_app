import 'dart:convert';

import 'package:esketit_music_app/domain/album.dart';
import 'package:esketit_music_app/domain/author.dart';
import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/domain/track_info/text_track_info.dart';
import 'package:esketit_music_app/domain/track_info/track_info.dart';
import 'package:esketit_music_app/errors/http_app_error.dart';
import 'package:esketit_music_app/esketit_rest_api/http_client.dart';
import 'package:esketit_music_app/esketit_rest_api/http_response.dart';
import 'package:esketit_music_app/unassigned_layer/http_file.dart';
import 'package:esketit_music_app/use_case/catalog/catalog_storage.dart';

class EsketitRestApiCatalogStorage implements CatalogStorage {
  final HttpClient _httpClient;
  final Uri _baseUri;

  const EsketitRestApiCatalogStorage({
    required HttpClient httpClient,
    required Uri baseUri,
  }) : _httpClient = httpClient,
       _baseUri = baseUri;

  @override
  Future<List<Author>> getPublishedAuthors() async {
    final authorsResponse = await _httpClient.get('/authors');
    _throwIfNotSuccess(authorsResponse, '/authors');

    final publishedAlbums = await _getPublishedAlbumsPage();
    final publishedAuthorIds = publishedAlbums
        .expand((album) => album.authorIds)
        .toSet();

    return _parseAuthors(authorsResponse.response)
        .where((author) => publishedAuthorIds.contains(author.id))
        .toList(growable: false);
  }

  @override
  Future<List<Album>> getPublishedAlbumsByAuthor({
    required int authorId,
  }) async {
    final response = await _getPublishedAlbumsPage(authorId: authorId);
    return response;
  }

  @override
  Future<List<Track>> getAlbumTracks({required Album album}) async {
    final authorsResponse = await _httpClient.get('/authors');
    _throwIfNotSuccess(authorsResponse, '/authors');

    final tracksResponse = await _httpClient.get('/albums/${album.id}/tracks');
    _throwIfNotSuccess(tracksResponse, '/albums/${album.id}/tracks');

    final authorsById = {
      for (final author in _parseAuthors(authorsResponse.response))
        author.id: author,
    };

    return _parseTracks(
      tracksResponse.response,
      authorsById: authorsById,
      album: album,
    );
  }

  Future<List<Album>> _getPublishedAlbumsPage({int? authorId}) async {
    final albums = <Album>[];
    var currentPage = 1;
    var totalPages = 1;

    do {
      final response = await _httpClient.get(
        _buildAlbumsPath(page: currentPage, authorId: authorId),
      );
      _throwIfNotSuccess(response, '/albums');

      final page = _parseAlbumsPage(response.response);
      albums.addAll(page.items);
      totalPages = page.totalPages;
      currentPage += 1;
    } while (currentPage <= totalPages);

    return albums;
  }

  String _buildAlbumsPath({required int page, int? authorId}) {
    final queryParameters = <String, String>{
      'page': '$page',
      'pageSize': '100',
      'isPublished': 'true',
      if (authorId != null) 'authorId': '$authorId',
    };
    return Uri(path: '/albums', queryParameters: queryParameters).toString();
  }

  List<Author> _parseAuthors(Object? responseBody) {
    final body = _coerceJson(responseBody);
    if (body is! List) {
      throw const FormatException(
        'Expected /authors response to be a JSON list',
      );
    }

    return body
        .whereType<Map<String, dynamic>>()
        .map((item) {
          return Author(
            id: _asInt(item['id']) ?? 0,
            currentName: (item['currentName'] as String?) ?? '',
            photos: ((item['photos'] as List?) ?? const [])
                .whereType<String>()
                .toList(growable: false),
          );
        })
        .where((author) => author.id > 0)
        .toList(growable: false);
  }

  _AlbumsPage _parseAlbumsPage(Object? responseBody) {
    final body = _coerceJson(responseBody);
    if (body is! Map<String, dynamic>) {
      throw const FormatException(
        'Expected /albums response to be a JSON object',
      );
    }

    final items = ((body['items'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(_parseAlbum)
        .toList(growable: false);

    return _AlbumsPage(
      items: items,
      totalPages: _asInt(body['totalPages']) ?? 1,
    );
  }

  Album _parseAlbum(Map<String, dynamic> item) {
    final coverImagePath = (item['coverImagePath'] as String?) ?? '';
    return Album(
      id: _asInt(item['id']) ?? 0,
      title: (item['title'] as String?) ?? '',
      coverImage: HttpFile(uri: _resolveAlbumCoverUri(coverImagePath)),
      authorIds: ((item['authorIds'] as List?) ?? const [])
          .map(_asInt)
          .whereType<int>()
          .toList(growable: false),
      releaseDate: DateTime.tryParse((item['releaseDate'] as String?) ?? ''),
      isPublished: (item['isPublished'] as bool?) ?? false,
      trackIds: ((item['trackIds'] as List?) ?? const [])
          .map(_asInt)
          .whereType<int>()
          .toList(growable: false),
      additionalInfo: _parseAdditionalInfo(item['additionalInfo']),
    );
  }

  List<Track> _parseTracks(
    Object? responseBody, {
    required Map<int, Author> authorsById,
    required Album album,
  }) {
    final body = _coerceJson(responseBody);
    if (body is! List) {
      throw const FormatException(
        'Expected /albums/{id}/tracks response to be a JSON list',
      );
    }

    return body
        .whereType<Map<String, dynamic>>()
        .map((item) {
          final authorIds = ((item['authorIds'] as List?) ?? const [])
              .map(_asInt)
              .whereType<int>();
          final authors = authorIds
              .map((authorId) {
                return authorsById[authorId] ??
                    Author(
                      id: authorId,
                      currentName: 'Author #$authorId',
                      photos: const [],
                    );
              })
              .toList(growable: false);

          return Track(
            id: _asInt(item['id']) ?? 0,
            name: (item['name'] as String?) ?? '',
            authors: authors,
            addionalInfo: _parseAdditionalInfo(item['additionalInfo']),
            file: HttpFile(
              uri: _resolveSongUri((item['audioFilePath'] as String?) ?? ''),
            ),
            image: album.coverImage,
          );
        })
        .where((track) => track.id > 0)
        .toList(growable: false);
  }

  List<TrackInfo> _parseAdditionalInfo(Object? value) {
    final items = value is List ? value : const [];
    final parsed = <TrackInfo>[];

    for (final item in items) {
      if (item is! Map<String, dynamic>) {
        continue;
      }

      switch (item['type']) {
        case 'text':
          parsed.add(
            TextTrackInfo(
              title: (item['title'] as String?) ?? '',
              text: (item['text'] as String?) ?? '',
            ),
          );
      }
    }

    return parsed;
  }

  Uri _resolveAlbumCoverUri(String coverImagePath) {
    final parsed = Uri.tryParse(coverImagePath);
    if (parsed != null && parsed.hasScheme) {
      return parsed;
    }
    if (coverImagePath.isEmpty) {
      return Uri();
    }

    return _baseUri.resolve(
      'album-covers/${Uri.encodeComponent(coverImagePath)}',
    );
  }

  Uri _resolveSongUri(String audioFilePath) {
    final parsed = Uri.tryParse(audioFilePath);
    if (parsed != null && parsed.hasScheme) {
      return parsed;
    }
    if (audioFilePath.isEmpty) {
      return Uri();
    }

    return _baseUri.resolve('songs/${Uri.encodeComponent(audioFilePath)}');
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

class _AlbumsPage {
  final List<Album> items;
  final int totalPages;

  const _AlbumsPage({required this.items, required this.totalPages});
}
