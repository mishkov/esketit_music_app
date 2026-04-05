import 'package:equatable/equatable.dart';
import 'package:esketit_music_app/domain/album.dart';
import 'package:esketit_music_app/domain/author.dart';
import 'package:esketit_music_app/domain/catalog_search_result.dart';
import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/errors/error_reporter/app_error.dart';
import 'package:esketit_music_app/errors/error_reporter/error_reporter.dart';
import 'package:esketit_music_app/use_case/catalog/catalog_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class CatalogEvent extends Equatable {}

class CatalogSearchQueryChanged extends CatalogEvent {
  final String query;

  CatalogSearchQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class LoadCatalogSearchResults extends CatalogEvent {
  final int? page;

  LoadCatalogSearchResults({this.page});

  @override
  List<Object?> get props => [page];
}

class LoadPublishedAuthors extends CatalogEvent {
  @override
  List<Object?> get props => [];
}

class LoadPublishedAlbumsByAuthor extends CatalogEvent {
  final Author author;

  LoadPublishedAlbumsByAuthor(this.author);

  @override
  List<Object?> get props => [author];
}

class LoadAlbumTracks extends CatalogEvent {
  final Album album;

  LoadAlbumTracks(this.album);

  @override
  List<Object?> get props => [album];
}

class CatalogBloc extends Bloc<CatalogEvent, CatalogState> {
  final CatalogStorage _catalogStorage;
  final ErrorReporter _errorReporter;

  CatalogBloc({
    required CatalogState initialState,
    required CatalogStorage catalogStorage,
    required ErrorReporter errorReporter,
  }) : _catalogStorage = catalogStorage,
       _errorReporter = errorReporter,
       super(initialState) {
    on<CatalogSearchQueryChanged>(_onCatalogSearchQueryChanged);
    on<LoadCatalogSearchResults>(_onLoadCatalogSearchResults);
    on<LoadPublishedAuthors>(_onLoadPublishedAuthors);
    on<LoadPublishedAlbumsByAuthor>(_onLoadPublishedAlbumsByAuthor);
    on<LoadAlbumTracks>(_onLoadAlbumTracks);
  }

  static const int searchPageSize = 20;

  static PaginatedCatalogSearchResults _mergeSearchResults(
    PaginatedCatalogSearchResults previous,
    PaginatedCatalogSearchResults next,
  ) {
    return PaginatedCatalogSearchResults(
      items: [...previous.items, ...next.items],
      page: next.page,
      pageSize: next.pageSize,
      totalItems: next.totalItems,
      totalPages: next.totalPages,
    );
  }

  void _onCatalogSearchQueryChanged(
    CatalogSearchQueryChanged event,
    Emitter<CatalogState> emit,
  ) {
    emit(
      state.copyWith(
        searchQuery: event.query,
        searchPage: 1,
        isLoadingSearch: false,
        clearSearchError: true,
        clearSearchResults: event.query.trim().isEmpty,
      ),
    );
  }

  Future<void> _onLoadCatalogSearchResults(
    LoadCatalogSearchResults event,
    Emitter<CatalogState> emit,
  ) async {
    final query = state.searchQuery.trim();
    if (query.isEmpty) {
      emit(
        state.copyWith(
          isLoadingSearch: false,
          clearSearchError: true,
          clearSearchResults: true,
          searchPage: 1,
        ),
      );
      return;
    }

    final requestedPage = event.page ?? state.searchPage;
    if (state.isLoadingSearch) {
      return;
    }
    if (requestedPage > 1) {
      final currentResults = state.searchResults;
      if (currentResults == null || requestedPage > currentResults.totalPages) {
        return;
      }
    }

    emit(
      state.copyWith(
        searchPage: requestedPage,
        isLoadingSearch: true,
        clearSearchError: true,
      ),
    );

    try {
      final results = await _catalogStorage.search(
        query: query,
        page: requestedPage,
        pageSize: state.searchPageSize,
      );

      if (state.searchQuery.trim() != query ||
          state.searchPage != requestedPage) {
        return;
      }

      emit(
        state.copyWith(
          searchResults: requestedPage > 1 && state.searchResults != null
              ? _mergeSearchResults(state.searchResults!, results)
              : results,
          searchPage: results.page,
          searchPageSize: results.pageSize,
          isLoadingSearch: false,
          clearSearchError: true,
        ),
      );
    } catch (error, stackTrace) {
      if (state.searchQuery.trim() != query ||
          state.searchPage != requestedPage) {
        return;
      }

      emit(
        state.copyWith(
          isLoadingSearch: false,
          searchErrorMessage: 'Failed to search catalog.',
        ),
      );
      await _errorReporter.reportError(
        AppError(
          'Failed to search catalog for "$query" on page $requestedPage',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  Future<void> _onLoadPublishedAuthors(
    LoadPublishedAuthors event,
    Emitter<CatalogState> emit,
  ) async {
    if (state.isLoadingAuthors || state.authors.isNotEmpty) {
      return;
    }

    emit(state.copyWith(isLoadingAuthors: true, clearAuthorsError: true));

    try {
      final authors = await _catalogStorage.getPublishedAuthors();
      emit(
        state.copyWith(
          authors: authors,
          isLoadingAuthors: false,
          clearAuthorsError: true,
        ),
      );
    } catch (error, stackTrace) {
      emit(
        state.copyWith(
          isLoadingAuthors: false,
          authorsErrorMessage: 'Failed to load authors.',
        ),
      );
      await _errorReporter.reportError(
        AppError(
          'Failed to load published authors',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  Future<void> _onLoadPublishedAlbumsByAuthor(
    LoadPublishedAlbumsByAuthor event,
    Emitter<CatalogState> emit,
  ) async {
    final authorId = event.author.id;
    if (state.loadingAuthorIds.contains(authorId) ||
        state.albumsByAuthorId.containsKey(authorId)) {
      return;
    }

    emit(
      state.copyWith(
        loadingAuthorIds: {...state.loadingAuthorIds, authorId},
        clearAuthorAlbumsErrorId: authorId,
      ),
    );

    try {
      final albums = await _catalogStorage.getPublishedAlbumsByAuthor(
        authorId: authorId,
      );
      final nextAlbumsByAuthorId = Map<int, List<Album>>.from(
        state.albumsByAuthorId,
      )..[authorId] = albums;
      final nextLoadingAuthorIds = Set<int>.from(state.loadingAuthorIds)
        ..remove(authorId);
      emit(
        state.copyWith(
          albumsByAuthorId: nextAlbumsByAuthorId,
          loadingAuthorIds: nextLoadingAuthorIds,
          clearAuthorAlbumsErrorId: authorId,
        ),
      );
    } catch (error, stackTrace) {
      final nextLoadingAuthorIds = Set<int>.from(state.loadingAuthorIds)
        ..remove(authorId);
      emit(
        state.copyWith(
          loadingAuthorIds: nextLoadingAuthorIds,
          authorAlbumsErrorMessages: {
            ...state.authorAlbumsErrorMessages,
            authorId: 'Failed to load albums.',
          },
        ),
      );
      await _errorReporter.reportError(
        AppError(
          'Failed to load published albums for author $authorId',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  Future<void> _onLoadAlbumTracks(
    LoadAlbumTracks event,
    Emitter<CatalogState> emit,
  ) async {
    final albumId = event.album.id;
    if (state.loadingAlbumIds.contains(albumId) ||
        state.tracksByAlbumId.containsKey(albumId)) {
      return;
    }

    emit(
      state.copyWith(
        loadingAlbumIds: {...state.loadingAlbumIds, albumId},
        clearAlbumTracksErrorId: albumId,
      ),
    );

    try {
      final tracks = await _catalogStorage.getAlbumTracks(album: event.album);
      final nextTracksByAlbumId = Map<int, List<Track>>.from(
        state.tracksByAlbumId,
      )..[albumId] = tracks;
      final nextLoadingAlbumIds = Set<int>.from(state.loadingAlbumIds)
        ..remove(albumId);
      emit(
        state.copyWith(
          tracksByAlbumId: nextTracksByAlbumId,
          loadingAlbumIds: nextLoadingAlbumIds,
          clearAlbumTracksErrorId: albumId,
        ),
      );
    } catch (error, stackTrace) {
      final nextLoadingAlbumIds = Set<int>.from(state.loadingAlbumIds)
        ..remove(albumId);
      emit(
        state.copyWith(
          loadingAlbumIds: nextLoadingAlbumIds,
          albumTracksErrorMessages: {
            ...state.albumTracksErrorMessages,
            albumId: 'Failed to load tracks.',
          },
        ),
      );
      await _errorReporter.reportError(
        AppError(
          'Failed to load tracks for album $albumId',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}

class CatalogState extends Equatable {
  final List<Author> authors;
  final bool isLoadingAuthors;
  final String? authorsErrorMessage;
  final Map<int, List<Album>> albumsByAuthorId;
  final Set<int> loadingAuthorIds;
  final Map<int, String> authorAlbumsErrorMessages;
  final Map<int, List<Track>> tracksByAlbumId;
  final Set<int> loadingAlbumIds;
  final Map<int, String> albumTracksErrorMessages;
  final String searchQuery;
  final int searchPage;
  final int searchPageSize;
  final PaginatedCatalogSearchResults? searchResults;
  final bool isLoadingSearch;
  final String? searchErrorMessage;

  const CatalogState({
    required this.authors,
    required this.isLoadingAuthors,
    required this.authorsErrorMessage,
    required this.albumsByAuthorId,
    required this.loadingAuthorIds,
    required this.authorAlbumsErrorMessages,
    required this.tracksByAlbumId,
    required this.loadingAlbumIds,
    required this.albumTracksErrorMessages,
    required this.searchQuery,
    required this.searchPage,
    required this.searchPageSize,
    required this.searchResults,
    required this.isLoadingSearch,
    required this.searchErrorMessage,
  });

  CatalogState copyWith({
    List<Author>? authors,
    bool? isLoadingAuthors,
    String? authorsErrorMessage,
    bool clearAuthorsError = false,
    Map<int, List<Album>>? albumsByAuthorId,
    Set<int>? loadingAuthorIds,
    Map<int, String>? authorAlbumsErrorMessages,
    int? clearAuthorAlbumsErrorId,
    Map<int, List<Track>>? tracksByAlbumId,
    Set<int>? loadingAlbumIds,
    Map<int, String>? albumTracksErrorMessages,
    int? clearAlbumTracksErrorId,
    String? searchQuery,
    int? searchPage,
    int? searchPageSize,
    PaginatedCatalogSearchResults? searchResults,
    bool clearSearchResults = false,
    bool? isLoadingSearch,
    String? searchErrorMessage,
    bool clearSearchError = false,
  }) {
    final nextAuthorAlbumsErrorMessages = Map<int, String>.from(
      authorAlbumsErrorMessages ?? this.authorAlbumsErrorMessages,
    );
    if (clearAuthorAlbumsErrorId != null) {
      nextAuthorAlbumsErrorMessages.remove(clearAuthorAlbumsErrorId);
    }

    final nextAlbumTracksErrorMessages = Map<int, String>.from(
      albumTracksErrorMessages ?? this.albumTracksErrorMessages,
    );
    if (clearAlbumTracksErrorId != null) {
      nextAlbumTracksErrorMessages.remove(clearAlbumTracksErrorId);
    }

    return CatalogState(
      authors: authors ?? this.authors,
      isLoadingAuthors: isLoadingAuthors ?? this.isLoadingAuthors,
      authorsErrorMessage: clearAuthorsError
          ? null
          : (authorsErrorMessage ?? this.authorsErrorMessage),
      albumsByAuthorId: albumsByAuthorId ?? this.albumsByAuthorId,
      loadingAuthorIds: loadingAuthorIds ?? this.loadingAuthorIds,
      authorAlbumsErrorMessages: nextAuthorAlbumsErrorMessages,
      tracksByAlbumId: tracksByAlbumId ?? this.tracksByAlbumId,
      loadingAlbumIds: loadingAlbumIds ?? this.loadingAlbumIds,
      albumTracksErrorMessages: nextAlbumTracksErrorMessages,
      searchQuery: searchQuery ?? this.searchQuery,
      searchPage: searchPage ?? this.searchPage,
      searchPageSize: searchPageSize ?? this.searchPageSize,
      searchResults: clearSearchResults
          ? null
          : (searchResults ?? this.searchResults),
      isLoadingSearch: isLoadingSearch ?? this.isLoadingSearch,
      searchErrorMessage: clearSearchError
          ? null
          : (searchErrorMessage ?? this.searchErrorMessage),
    );
  }

  @override
  List<Object?> get props => [
    authors,
    isLoadingAuthors,
    authorsErrorMessage,
    albumsByAuthorId,
    loadingAuthorIds,
    authorAlbumsErrorMessages,
    tracksByAlbumId,
    loadingAlbumIds,
    albumTracksErrorMessages,
    searchQuery,
    searchPage,
    searchPageSize,
    searchResults,
    isLoadingSearch,
    searchErrorMessage,
  ];

  bool get hasActiveSearch => searchQuery.trim().isNotEmpty;

  bool get hasMoreSearchResults {
    final results = searchResults;
    if (results == null) {
      return false;
    }
    return results.page < results.totalPages;
  }
}
