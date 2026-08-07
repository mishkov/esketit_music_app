import 'package:equatable/equatable.dart';
import 'package:esketit_music_app/domain/album.dart';
import 'package:esketit_music_app/errors/error_reporter/app_error.dart';
import 'package:esketit_music_app/errors/error_reporter/breadcrumb.dart';
import 'package:esketit_music_app/errors/error_reporter/category.dart';
import 'package:esketit_music_app/errors/error_reporter/error_reporter.dart';
import 'package:esketit_music_app/use_case/catalog/catalog_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class AlbumDetailsEvent extends Equatable {
  const AlbumDetailsEvent();
}

final class LoadAlbumDetails extends AlbumDetailsEvent {
  const LoadAlbumDetails(this.albumId);

  final int albumId;

  @override
  List<Object?> get props => [albumId];
}

class AlbumDetailsBloc extends Bloc<AlbumDetailsEvent, AlbumDetailsState> {
  AlbumDetailsBloc({
    required AlbumDetailsState initialState,
    required CatalogStorage catalogStorage,
    required ErrorReporter errorReporter,
  }) : _catalogStorage = catalogStorage,
       _errorReporter = errorReporter,
       super(initialState) {
    on<LoadAlbumDetails>(_onLoadAlbumDetails);
  }

  final CatalogStorage _catalogStorage;
  final ErrorReporter _errorReporter;

  Future<void> _onLoadAlbumDetails(
    LoadAlbumDetails event,
    Emitter<AlbumDetailsState> emit,
  ) async {
    emit(
      AlbumDetailsState(
        albumId: event.albumId,
        album: null,
        isLoading: true,
        error: null,
      ),
    );

    try {
      await _errorReporter.addBreadcrumb(
        Breadcrumb(
          message: 'Open album URL',
          category: Category.navigation,
          data: {'albumId': event.albumId},
        ),
      );
      final album = await _catalogStorage.getAlbum(albumId: event.albumId);

      emit(
        AlbumDetailsState(
          albumId: event.albumId,
          album: album,
          isLoading: false,
          error: null,
        ),
      );
    } catch (error, stackTrace) {
      final appError = AppError(
        'Failed to load album ${event.albumId} from URL',
        cause: error,
        stackTrace: stackTrace,
      );
      emit(
        AlbumDetailsState(
          albumId: event.albumId,
          album: null,
          isLoading: false,
          error: appError,
        ),
      );
      await _errorReporter.reportError(appError);
    }
  }
}

class AlbumDetailsState extends Equatable {
  const AlbumDetailsState({
    required this.albumId,
    required this.album,
    required this.isLoading,
    required this.error,
  });

  final int albumId;
  final Album? album;
  final bool isLoading;
  final AppError? error;

  @override
  List<Object?> get props => [albumId, album, isLoading, error];
}
