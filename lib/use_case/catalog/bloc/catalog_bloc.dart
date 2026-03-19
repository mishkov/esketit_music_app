import 'package:equatable/equatable.dart';
import 'package:esketit_music_app/domain/album.dart';
import 'package:esketit_music_app/domain/author.dart';
import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/errors/error_reporter/app_error.dart';
import 'package:esketit_music_app/errors/error_reporter/error_reporter.dart';
import 'package:esketit_music_app/use_case/catalog/catalog_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class CatalogEvent extends Equatable {}

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
    on<LoadPublishedAuthors>(_onLoadPublishedAuthors);
    on<LoadPublishedAlbumsByAuthor>(_onLoadPublishedAlbumsByAuthor);
    on<LoadAlbumTracks>(_onLoadAlbumTracks);
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
  ];
}
