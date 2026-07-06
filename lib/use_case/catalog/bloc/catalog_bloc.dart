import 'package:equatable/equatable.dart';
import 'package:esketit_music_app/domain/album.dart';
import 'package:esketit_music_app/domain/author.dart';
import 'package:esketit_music_app/domain/catalog_search_result.dart';
import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/errors/error_reporter/app_error.dart';
import 'package:esketit_music_app/errors/error_reporter/error_reporter.dart';
import 'package:esketit_music_app/use_case/analytics/analytics_collecting.dart';
import 'package:esketit_music_app/use_case/analytics/analytics_event.dart';
import 'package:esketit_music_app/use_case/catalog/catalog_storage.dart';
import 'package:esketit_music_app/use_case/catalog/recent_search_queries_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';

sealed class CatalogEvent extends Equatable {}

final class CatalogSearchQueryChanged extends CatalogEvent {
  final String query;
  final bool loadSearchResults;
  final bool debounceSearchResultsLoading;

  CatalogSearchQueryChanged(
    this.query, {
    this.loadSearchResults = false,
    this.debounceSearchResultsLoading = false,
  });

  @override
  List<Object?> get props => [
    query,
    loadSearchResults,
    debounceSearchResultsLoading,
  ];
}

final class LoadCatalogSearchResults extends CatalogEvent {
  final int? page;
  final bool debounce;

  LoadCatalogSearchResults({this.page, this.debounce = false});

  @override
  List<Object?> get props => [page, debounce];
}

final class SearchResultClicked extends CatalogEvent {
  final CatalogSearchResultItem result;
  final int resultRank;

  SearchResultClicked({required this.result, required this.resultRank});

  @override
  List<Object?> get props => [result, resultRank];
}

final class LoadRecentSearchQueries extends CatalogEvent {
  @override
  List<Object?> get props => [];
}

final class LoadPublishedAuthors extends CatalogEvent {
  @override
  List<Object?> get props => [];
}

final class LoadPublishedAlbumsByAuthor extends CatalogEvent {
  final Author author;

  LoadPublishedAlbumsByAuthor(this.author);

  @override
  List<Object?> get props => [author];
}

final class LoadAlbumTracks extends CatalogEvent {
  final Album album;

  LoadAlbumTracks(this.album);

  @override
  List<Object?> get props => [album];
}

class CatalogBloc extends Bloc<CatalogEvent, CatalogState> {
  final CatalogStorage _catalogStorage;
  final RecentSearchQueriesStorage _recentSearchQueriesStorage;
  final ErrorReporter _errorReporter;
  final AnalyticsCollecting _analytics;

  CatalogBloc({
    required CatalogState initialState,
    required CatalogStorage catalogStorage,
    required RecentSearchQueriesStorage recentSearchQueriesStorage,
    required ErrorReporter errorReporter,
    AnalyticsCollecting analytics = const NoopAnalyticsCollector(),
  }) : _catalogStorage = catalogStorage,
       _recentSearchQueriesStorage = recentSearchQueriesStorage,
       _errorReporter = errorReporter,
       _analytics = analytics,
       super(initialState) {
    on<CatalogSearchQueryChanged>(_onCatalogSearchQueryChanged);
    on<LoadCatalogSearchResults>(
      _onLoadCatalogSearchResults,
      transformer: _debounceSearchResultsLoading(_searchDebounceDuration),
    );
    on<SearchResultClicked>(_onSearchResultClicked);
    on<LoadRecentSearchQueries>(_onLoadRecentSearchQueries);
    on<LoadPublishedAuthors>(_onLoadPublishedAuthors);
    on<LoadPublishedAlbumsByAuthor>(_onLoadPublishedAlbumsByAuthor);
    on<LoadAlbumTracks>(_onLoadAlbumTracks);
  }

  static const int searchPageSize = 20;
  static const Duration _searchDebounceDuration = Duration(milliseconds: 400);

  static EventTransformer<LoadCatalogSearchResults>
  _debounceSearchResultsLoading(Duration duration) {
    return (events, mapper) => events
        .switchMap(
          (event) =>
              event.debounce ? Rx.timer(event, duration) : Stream.value(event),
        )
        .asyncExpand(mapper);
  }

  Future<void> _onLoadRecentSearchQueries(
    LoadRecentSearchQueries event,
    Emitter<CatalogState> emit,
  ) async {
    try {
      final recentSearchQueries = await _recentSearchQueriesStorage
          .getRecentSearchQueries();
      emit(state.copyWith(recentSearchQueries: recentSearchQueries));
    } catch (error, stackTrace) {
      await _errorReporter.reportError(
        AppError(
          'Failed to load recent search queries',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

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

  static List<Album> _sortAlbumsByReleaseDateDescending(List<Album> albums) {
    final sortedAlbums = List<Album>.of(albums);
    sortedAlbums.sort((left, right) {
      final leftReleaseDate = left.releaseDate;
      final rightReleaseDate = right.releaseDate;

      if (leftReleaseDate == null && rightReleaseDate == null) {
        return 0;
      }
      if (leftReleaseDate == null) {
        return 1;
      }
      if (rightReleaseDate == null) {
        return -1;
      }

      return rightReleaseDate.compareTo(leftReleaseDate);
    });

    return sortedAlbums;
  }

  void _onCatalogSearchQueryChanged(
    CatalogSearchQueryChanged event,
    Emitter<CatalogState> emit,
  ) {
    final query = event.query.trim();

    emit(
      state.copyWith(
        searchQuery: event.query,
        searchPage: 1,
        isLoadingSearch: false,
        clearSearchError: true,
        clearSearchResults: query.isEmpty,
      ),
    );

    if (query.isEmpty || !event.loadSearchResults) {
      return;
    }

    add(LoadCatalogSearchResults(debounce: event.debounceSearchResultsLoading));
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

      List<String>? recentSearchQueries;
      if (requestedPage == 1 && results.items.isNotEmpty) {
        try {
          recentSearchQueries = await _recentSearchQueriesStorage
              .saveRecentSearchQuery(query);
        } catch (error, stackTrace) {
          await _errorReporter.reportError(
            AppError(
              'Failed to save recent search query "$query"',
              cause: error,
              stackTrace: stackTrace,
            ),
          );
        }
      }

      emit(
        state.copyWith(
          searchResults: requestedPage > 1 && state.searchResults != null
              ? _mergeSearchResults(state.searchResults!, results)
              : results,
          recentSearchQueries: recentSearchQueries,
          searchPage: results.page,
          searchPageSize: results.pageSize,
          isLoadingSearch: false,
          clearSearchError: true,
        ),
      );

      if (requestedPage == 1) {
        await _collectAnalytics(
          AnalyticsEvent(
            type: AnalyticsEventType.search,
            searchQuery: query,
            metadata: {
              'resultCount': results.totalItems,
              'filters': const <String, Object?>{},
              'sourceScreen': 'search',
            },
          ),
        );
      }
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

  Future<void> _onSearchResultClicked(
    SearchResultClicked event,
    Emitter<CatalogState> emit,
  ) async {
    final query = state.searchQuery.trim();
    if (query.isEmpty) {
      return;
    }

    await _collectAnalytics(
      AnalyticsEvent(
        type: AnalyticsEventType.searchResultClick,
        trackId: event.result.track?.id,
        albumId: event.result.album?.id,
        searchQuery: query,
        metadata: {
          'resultType': event.result.type.name,
          'resultId': _resultId(event.result),
          'resultRank': event.resultRank,
          if (event.result.track != null)
            'resultTrackId': event.result.track!.id,
          if (event.result.album != null)
            'resultAlbumId': event.result.album!.id,
          if (event.result.author != null)
            'resultAuthorId': event.result.author!.id,
          if (event.result.playlist != null)
            'resultPlaylistId': event.result.playlist!.id,
        },
      ),
    );
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
      final nextAlbumsByAuthorId = Map<int, List<Album>>.of(
        state.albumsByAuthorId,
      )..[authorId] = _sortAlbumsByReleaseDateDescending(albums);
      final nextLoadingAuthorIds = Set<int>.of(state.loadingAuthorIds)
        ..remove(authorId);
      emit(
        state.copyWith(
          albumsByAuthorId: nextAlbumsByAuthorId,
          loadingAuthorIds: nextLoadingAuthorIds,
          clearAuthorAlbumsErrorId: authorId,
        ),
      );
    } catch (error, stackTrace) {
      final nextLoadingAuthorIds = Set<int>.of(state.loadingAuthorIds)
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
      final nextTracksByAlbumId = Map<int, List<Track>>.of(
        state.tracksByAlbumId,
      )..[albumId] = tracks;
      final nextLoadingAlbumIds = Set<int>.of(state.loadingAlbumIds)
        ..remove(albumId);
      emit(
        state.copyWith(
          tracksByAlbumId: nextTracksByAlbumId,
          loadingAlbumIds: nextLoadingAlbumIds,
          clearAlbumTracksErrorId: albumId,
        ),
      );
    } catch (error, stackTrace) {
      final nextLoadingAlbumIds = Set<int>.of(state.loadingAlbumIds)
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

  Future<void> _collectAnalytics(AnalyticsEvent event) async {
    try {
      await _analytics.collect(event);
    } catch (error, stackTrace) {
      await _errorReporter.reportError(
        AppError(
          'Analytics collector leaked an error into catalog logic',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  int? _resultId(CatalogSearchResultItem item) {
    return switch (item.type) {
      CatalogSearchResultType.author => item.author?.id,
      CatalogSearchResultType.album => item.album?.id,
      CatalogSearchResultType.track => item.track?.id,
      CatalogSearchResultType.playlist => item.playlist?.id,
    };
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
  final List<String> recentSearchQueries;
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
    required this.recentSearchQueries,
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
    List<String>? recentSearchQueries,
    int? searchPage,
    int? searchPageSize,
    PaginatedCatalogSearchResults? searchResults,
    bool clearSearchResults = false,
    bool? isLoadingSearch,
    String? searchErrorMessage,
    bool clearSearchError = false,
  }) {
    final nextAuthorAlbumsErrorMessages = Map<int, String>.of(
      authorAlbumsErrorMessages ?? this.authorAlbumsErrorMessages,
    );
    if (clearAuthorAlbumsErrorId != null) {
      nextAuthorAlbumsErrorMessages.remove(clearAuthorAlbumsErrorId);
    }

    final nextAlbumTracksErrorMessages = Map<int, String>.of(
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
      recentSearchQueries: recentSearchQueries ?? this.recentSearchQueries,
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
    recentSearchQueries,
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
