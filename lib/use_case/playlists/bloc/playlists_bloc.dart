import 'package:equatable/equatable.dart';
import 'package:esketit_music_app/domain/playlist.dart';
import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/errors/error_reporter/app_error.dart';
import 'package:esketit_music_app/errors/error_reporter/error_reporter.dart';
import 'package:esketit_music_app/use_case/playlists/playlists_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class PlaylistsEvent extends Equatable {
  const PlaylistsEvent();

  @override
  List<Object?> get props => [];
}

final class LoadPlaylists extends PlaylistsEvent {
  const LoadPlaylists({this.forceRefresh = false});

  final bool forceRefresh;

  @override
  List<Object?> get props => [forceRefresh];
}

final class LoadPlaylistDetails extends PlaylistsEvent {
  const LoadPlaylistDetails(this.playlistId, {this.forceRefresh = false});

  final int playlistId;
  final bool forceRefresh;

  @override
  List<Object?> get props => [playlistId, forceRefresh];
}

final class CreatePlaylistRequested extends PlaylistsEvent {
  const CreatePlaylistRequested(this.input, {this.coverFile});

  final PlaylistUpsertInput input;
  final PlaylistCoverUploadInput? coverFile;

  @override
  List<Object?> get props => [input, coverFile];
}

final class UpdatePlaylistRequested extends PlaylistsEvent {
  const UpdatePlaylistRequested({
    required this.playlistId,
    required this.input,
    this.coverFile,
  });

  final int playlistId;
  final PlaylistUpsertInput input;
  final PlaylistCoverUploadInput? coverFile;

  @override
  List<Object?> get props => [playlistId, input, coverFile];
}

final class DeletePlaylistRequested extends PlaylistsEvent {
  const DeletePlaylistRequested(this.playlist);

  final Playlist playlist;

  @override
  List<Object?> get props => [playlist];
}

final class ToggleFavoriteRequested extends PlaylistsEvent {
  const ToggleFavoriteRequested({
    required this.trackId,
    required this.shouldBeFavorite,
  });

  final int trackId;
  final bool shouldBeFavorite;

  @override
  List<Object?> get props => [trackId, shouldBeFavorite];
}

final class AddTrackToPlaylistsRequested extends PlaylistsEvent {
  const AddTrackToPlaylistsRequested({
    required this.trackId,
    required this.playlistIds,
  });

  final int trackId;
  final List<int> playlistIds;

  @override
  List<Object?> get props => [trackId, playlistIds];
}

final class UpdateTrackPlaylistsRequested extends PlaylistsEvent {
  const UpdateTrackPlaylistsRequested({
    required this.trackId,
    required this.addPlaylistIds,
    required this.removePlaylistIds,
  });

  final int trackId;
  final List<int> addPlaylistIds;
  final List<int> removePlaylistIds;

  @override
  List<Object?> get props => [trackId, addPlaylistIds, removePlaylistIds];
}

final class RemoveTrackFromPlaylistRequested extends PlaylistsEvent {
  const RemoveTrackFromPlaylistRequested({
    required this.trackId,
    required this.playlistId,
  });

  final int trackId;
  final int playlistId;

  @override
  List<Object?> get props => [trackId, playlistId];
}

final class ReorderPlaylistTracksRequested extends PlaylistsEvent {
  const ReorderPlaylistTracksRequested({
    required this.playlistId,
    required this.trackIds,
  });

  final int playlistId;
  final List<int> trackIds;

  @override
  List<Object?> get props => [playlistId, trackIds];
}

final class ClearPlaylists extends PlaylistsEvent {
  const ClearPlaylists();
}

class PlaylistsBloc extends Bloc<PlaylistsEvent, PlaylistsState> {
  PlaylistsBloc({
    required PlaylistsStorage playlistsStorage,
    required ErrorReporter errorReporter,
  }) : _playlistsStorage = playlistsStorage,
       _errorReporter = errorReporter,
       super(const PlaylistsState.initial()) {
    on<LoadPlaylists>(_onLoadPlaylists);
    on<LoadPlaylistDetails>(_onLoadPlaylistDetails);
    on<CreatePlaylistRequested>(_onCreatePlaylistRequested);
    on<UpdatePlaylistRequested>(_onUpdatePlaylistRequested);
    on<DeletePlaylistRequested>(_onDeletePlaylistRequested);
    on<ToggleFavoriteRequested>(_onToggleFavoriteRequested);
    on<AddTrackToPlaylistsRequested>(_onAddTrackToPlaylistsRequested);
    on<UpdateTrackPlaylistsRequested>(_onUpdateTrackPlaylistsRequested);
    on<RemoveTrackFromPlaylistRequested>(_onRemoveTrackFromPlaylistRequested);
    on<ReorderPlaylistTracksRequested>(_onReorderPlaylistTracksRequested);
    on<ClearPlaylists>((event, emit) => emit(const PlaylistsState.initial()));
  }

  final PlaylistsStorage _playlistsStorage;
  final ErrorReporter _errorReporter;

  Future<void> _onLoadPlaylists(
    LoadPlaylists event,
    Emitter<PlaylistsState> emit,
  ) async {
    if (state.isLoadingPlaylists) {
      return;
    }
    if (!event.forceRefresh && state.playlists.isNotEmpty) {
      return;
    }

    emit(state.copyWith(isLoadingPlaylists: true, clearPlaylistsError: true));

    try {
      final playlists = _sortPlaylists(await _playlistsStorage.getPlaylists());
      emit(
        state.copyWith(
          playlists: playlists,
          isLoadingPlaylists: false,
          clearPlaylistsError: true,
        ),
      );
    } catch (error, stackTrace) {
      emit(
        state.copyWith(
          isLoadingPlaylists: false,
          playlistsErrorMessage: 'Failed to load playlists.',
        ),
      );
      await _reportError('Failed to load playlists', error, stackTrace);
    }
  }

  Future<void> _onLoadPlaylistDetails(
    LoadPlaylistDetails event,
    Emitter<PlaylistsState> emit,
  ) async {
    if (state.loadingPlaylistIds.contains(event.playlistId)) {
      return;
    }
    if (!event.forceRefresh &&
        state.playlistTracksById.containsKey(event.playlistId) &&
        state.playlists.any((playlist) => playlist.id == event.playlistId)) {
      return;
    }

    emit(
      state.copyWith(
        loadingPlaylistIds: {...state.loadingPlaylistIds, event.playlistId},
        clearPlaylistErrorId: event.playlistId,
      ),
    );

    try {
      final playlist = await _playlistsStorage.getPlaylist(
        playlistId: event.playlistId,
      );
      final tracks = await _playlistsStorage.getPlaylistTracks(
        playlistId: event.playlistId,
      );

      final updatedPlaylists = _upsertPlaylist(state.playlists, playlist);
      final updatedTracks = Map<int, List<Track>>.of(state.playlistTracksById)
        ..[event.playlistId] = _applyFavoriteOverrides(tracks);
      final loadingPlaylistIds = Set<int>.of(state.loadingPlaylistIds)
        ..remove(event.playlistId);

      emit(
        state.copyWith(
          playlists: updatedPlaylists,
          playlistTracksById: updatedTracks,
          loadingPlaylistIds: loadingPlaylistIds,
          clearPlaylistErrorId: event.playlistId,
        ),
      );
    } catch (error, stackTrace) {
      final loadingPlaylistIds = Set<int>.of(state.loadingPlaylistIds)
        ..remove(event.playlistId);
      emit(
        state.copyWith(
          loadingPlaylistIds: loadingPlaylistIds,
          playlistErrorMessages: {
            ...state.playlistErrorMessages,
            event.playlistId: 'Failed to load playlist.',
          },
        ),
      );
      await _reportError(
        'Failed to load playlist ${event.playlistId}',
        error,
        stackTrace,
      );
    }
  }

  Future<void> _onCreatePlaylistRequested(
    CreatePlaylistRequested event,
    Emitter<PlaylistsState> emit,
  ) async {
    emit(state.copyWith(isSubmittingPlaylist: true));

    try {
      var createdPlaylist = await _playlistsStorage.createPlaylist(event.input);
      if (event.coverFile != null) {
        try {
          createdPlaylist = await _playlistsStorage.uploadPlaylistCover(
            playlistId: createdPlaylist.id,
            input: event.coverFile!,
          );
        } catch (error, stackTrace) {
          emit(
            state.copyWith(
              isSubmittingPlaylist: false,
              playlists: _upsertPlaylist(state.playlists, createdPlaylist),
            ),
          );
          _emitFeedback(
            emit,
            message: 'Playlist created, but cover upload failed.',
            isError: true,
          );
          await _reportError(
            'Failed to upload cover for playlist ${createdPlaylist.id}',
            error,
            stackTrace,
          );
          return;
        }
      }
      emit(
        state.copyWith(
          isSubmittingPlaylist: false,
          playlists: _upsertPlaylist(state.playlists, createdPlaylist),
        ),
      );
      _emitFeedback(emit, message: 'Playlist created.');
    } catch (error, stackTrace) {
      emit(state.copyWith(isSubmittingPlaylist: false));
      _emitFeedback(emit, message: 'Failed to create playlist.', isError: true);
      await _reportError('Failed to create playlist', error, stackTrace);
    }
  }

  Future<void> _onUpdatePlaylistRequested(
    UpdatePlaylistRequested event,
    Emitter<PlaylistsState> emit,
  ) async {
    emit(state.copyWith(isSubmittingPlaylist: true));

    try {
      var updatedPlaylist = await _playlistsStorage.updatePlaylist(
        playlistId: event.playlistId,
        input: event.input,
      );
      if (event.coverFile != null) {
        try {
          updatedPlaylist = await _playlistsStorage.uploadPlaylistCover(
            playlistId: event.playlistId,
            input: event.coverFile!,
          );
        } catch (error, stackTrace) {
          emit(
            state.copyWith(
              isSubmittingPlaylist: false,
              playlists: _upsertPlaylist(state.playlists, updatedPlaylist),
            ),
          );
          _emitFeedback(
            emit,
            message: 'Playlist updated, but cover upload failed.',
            isError: true,
          );
          await _reportError(
            'Failed to upload cover for playlist ${event.playlistId}',
            error,
            stackTrace,
          );
          return;
        }
      }
      emit(
        state.copyWith(
          isSubmittingPlaylist: false,
          playlists: _upsertPlaylist(state.playlists, updatedPlaylist),
        ),
      );
      _emitFeedback(emit, message: 'Playlist updated.');
    } catch (error, stackTrace) {
      emit(state.copyWith(isSubmittingPlaylist: false));
      _emitFeedback(emit, message: 'Failed to update playlist.', isError: true);
      await _reportError(
        'Failed to update playlist ${event.playlistId}',
        error,
        stackTrace,
      );
    }
  }

  Future<void> _onDeletePlaylistRequested(
    DeletePlaylistRequested event,
    Emitter<PlaylistsState> emit,
  ) async {
    final deletingPlaylistIds = Set<int>.of(state.deletingPlaylistIds)
      ..add(event.playlist.id);
    emit(state.copyWith(deletingPlaylistIds: deletingPlaylistIds));

    try {
      await _playlistsStorage.deletePlaylist(playlistId: event.playlist.id);
      final updatedDeletingIds = Set<int>.of(state.deletingPlaylistIds)
        ..remove(event.playlist.id);
      final updatedTracks = Map<int, List<Track>>.of(state.playlistTracksById)
        ..remove(event.playlist.id);
      emit(
        state.copyWith(
          deletingPlaylistIds: updatedDeletingIds,
          playlists: state.playlists
              .where((playlist) => playlist.id != event.playlist.id)
              .toList(growable: false),
          playlistTracksById: updatedTracks,
        ),
      );
      _emitFeedback(emit, message: 'Playlist deleted.');
    } catch (error, stackTrace) {
      final updatedDeletingIds = Set<int>.of(state.deletingPlaylistIds)
        ..remove(event.playlist.id);
      emit(state.copyWith(deletingPlaylistIds: updatedDeletingIds));
      _emitFeedback(emit, message: 'Failed to delete playlist.', isError: true);
      await _reportError(
        'Failed to delete playlist ${event.playlist.id}',
        error,
        stackTrace,
      );
    }
  }

  Future<void> _onToggleFavoriteRequested(
    ToggleFavoriteRequested event,
    Emitter<PlaylistsState> emit,
  ) async {
    final pendingFavoriteTrackIds = Set<int>.of(state.pendingFavoriteTrackIds)
      ..add(event.trackId);
    final favoriteOverrides = Map<int, bool>.of(state.favoriteOverrides)
      ..[event.trackId] = event.shouldBeFavorite;

    emit(
      state.copyWith(
        pendingFavoriteTrackIds: pendingFavoriteTrackIds,
        favoriteOverrides: favoriteOverrides,
        playlistTracksById: _mapTracks(
          state.playlistTracksById,
          (track) => track.id == event.trackId
              ? track.copyWith(isFavorite: event.shouldBeFavorite)
              : track,
        ),
      ),
    );

    try {
      if (event.shouldBeFavorite) {
        await _playlistsStorage.addTrackToFavorites(trackId: event.trackId);
      } else {
        await _playlistsStorage.removeTrackFromFavorites(
          trackId: event.trackId,
        );
      }

      final updatedPendingIds = Set<int>.of(state.pendingFavoriteTrackIds)
        ..remove(event.trackId);
      emit(state.copyWith(pendingFavoriteTrackIds: updatedPendingIds));
      add(const LoadPlaylists(forceRefresh: true));

      final favoritesPlaylist = state.playlists
          .where((playlist) => playlist.isFavorites)
          .firstOrNull;
      if (favoritesPlaylist != null) {
        add(LoadPlaylistDetails(favoritesPlaylist.id, forceRefresh: true));
      }
    } catch (error, stackTrace) {
      final updatedPendingIds = Set<int>.of(state.pendingFavoriteTrackIds)
        ..remove(event.trackId);
      final revertedOverrides = Map<int, bool>.of(state.favoriteOverrides)
        ..[event.trackId] = !event.shouldBeFavorite;
      emit(
        state.copyWith(
          pendingFavoriteTrackIds: updatedPendingIds,
          favoriteOverrides: revertedOverrides,
          playlistTracksById: _mapTracks(
            state.playlistTracksById,
            (track) => track.id == event.trackId
                ? track.copyWith(isFavorite: !event.shouldBeFavorite)
                : track,
          ),
        ),
      );
      _emitFeedback(emit, message: 'Failed to update favorite.', isError: true);
      await _reportError(
        'Failed to update favorite track ${event.trackId}',
        error,
        stackTrace,
      );
    }
  }

  Future<void> _onAddTrackToPlaylistsRequested(
    AddTrackToPlaylistsRequested event,
    Emitter<PlaylistsState> emit,
  ) async {
    final pendingTrackPlaylistActionIds = Set<int>.of(
      state.pendingTrackPlaylistActionIds,
    )..add(event.trackId);
    emit(
      state.copyWith(
        pendingTrackPlaylistActionIds: pendingTrackPlaylistActionIds,
      ),
    );

    try {
      await _playlistsStorage.addTrackToPlaylists(
        trackId: event.trackId,
        playlistIds: event.playlistIds,
      );

      final updatedPendingIds = Set<int>.of(state.pendingTrackPlaylistActionIds)
        ..remove(event.trackId);
      final playlistTracksById = Map<int, List<Track>>.of(
        state.playlistTracksById,
      );
      final cachedPlaylistIds = event.playlistIds
          .where(playlistTracksById.containsKey)
          .toList(growable: false);
      for (final playlistId in cachedPlaylistIds) {
        playlistTracksById.remove(playlistId);
      }

      emit(
        state.copyWith(
          pendingTrackPlaylistActionIds: updatedPendingIds,
          playlistTracksById: playlistTracksById,
          playlists: state.playlists
              .map((playlist) {
                if (!event.playlistIds.contains(playlist.id)) {
                  return playlist;
                }

                return playlist.copyWith(trackCount: playlist.trackCount + 1);
              })
              .toList(growable: false),
        ),
      );
      _emitFeedback(emit, message: 'Track added to playlists.');
      for (final playlistId in cachedPlaylistIds) {
        add(LoadPlaylistDetails(playlistId, forceRefresh: true));
      }
    } catch (error, stackTrace) {
      final updatedPendingIds = Set<int>.of(state.pendingTrackPlaylistActionIds)
        ..remove(event.trackId);
      emit(state.copyWith(pendingTrackPlaylistActionIds: updatedPendingIds));
      _emitFeedback(
        emit,
        message: 'Failed to add track to playlists.',
        isError: true,
      );
      await _reportError(
        'Failed to add track ${event.trackId} to playlists',
        error,
        stackTrace,
      );
    }
  }

  Future<void> _onUpdateTrackPlaylistsRequested(
    UpdateTrackPlaylistsRequested event,
    Emitter<PlaylistsState> emit,
  ) async {
    if (event.addPlaylistIds.isEmpty && event.removePlaylistIds.isEmpty) {
      return;
    }

    final pendingTrackPlaylistActionIds = Set<int>.of(
      state.pendingTrackPlaylistActionIds,
    )..add(event.trackId);
    emit(
      state.copyWith(
        pendingTrackPlaylistActionIds: pendingTrackPlaylistActionIds,
      ),
    );

    try {
      if (event.addPlaylistIds.isNotEmpty) {
        await _playlistsStorage.addTrackToPlaylists(
          trackId: event.trackId,
          playlistIds: event.addPlaylistIds,
        );
      }

      for (final playlistId in event.removePlaylistIds) {
        await _playlistsStorage.removeTrackFromPlaylist(
          trackId: event.trackId,
          playlistId: playlistId,
        );
      }

      final updatedPendingIds = Set<int>.of(state.pendingTrackPlaylistActionIds)
        ..remove(event.trackId);
      final playlistTracksById = Map<int, List<Track>>.of(
        state.playlistTracksById,
      );
      final cachedAddedPlaylistIds = event.addPlaylistIds
          .where(playlistTracksById.containsKey)
          .toList(growable: false);
      for (final playlistId in cachedAddedPlaylistIds) {
        playlistTracksById.remove(playlistId);
      }
      for (final playlistId in event.removePlaylistIds) {
        final tracks = playlistTracksById[playlistId];
        if (tracks == null) {
          continue;
        }
        playlistTracksById[playlistId] = tracks
            .where((track) => track.id != event.trackId)
            .toList(growable: false);
      }

      emit(
        state.copyWith(
          pendingTrackPlaylistActionIds: updatedPendingIds,
          playlistTracksById: playlistTracksById,
          playlists: state.playlists
              .map((playlist) {
                if (event.addPlaylistIds.contains(playlist.id)) {
                  return playlist.copyWith(trackCount: playlist.trackCount + 1);
                }

                if (event.removePlaylistIds.contains(playlist.id)) {
                  return playlist.copyWith(
                    trackCount: (playlist.trackCount - 1).clamp(0, 1 << 31),
                  );
                }

                return playlist;
              })
              .toList(growable: false),
        ),
      );
      _emitFeedback(emit, message: 'Playlists updated.');
      for (final playlistId in cachedAddedPlaylistIds) {
        add(LoadPlaylistDetails(playlistId, forceRefresh: true));
      }
    } catch (error, stackTrace) {
      final updatedPendingIds = Set<int>.of(state.pendingTrackPlaylistActionIds)
        ..remove(event.trackId);
      emit(state.copyWith(pendingTrackPlaylistActionIds: updatedPendingIds));
      _emitFeedback(
        emit,
        message: 'Failed to update playlists.',
        isError: true,
      );
      await _reportError(
        'Failed to update playlists for track ${event.trackId}',
        error,
        stackTrace,
      );
    }
  }

  Future<void> _onRemoveTrackFromPlaylistRequested(
    RemoveTrackFromPlaylistRequested event,
    Emitter<PlaylistsState> emit,
  ) async {
    final pendingTrackPlaylistActionIds = Set<int>.of(
      state.pendingTrackPlaylistActionIds,
    )..add(event.trackId);
    final previousTracks =
        state.playlistTracksById[event.playlistId] ?? const <Track>[];
    final nextTracks = previousTracks
        .where((track) => track.id != event.trackId)
        .toList(growable: false);

    emit(
      state.copyWith(
        pendingTrackPlaylistActionIds: pendingTrackPlaylistActionIds,
        playlistTracksById: {
          ...state.playlistTracksById,
          event.playlistId: nextTracks,
        },
        playlists: state.playlists
            .map((playlist) {
              if (playlist.id != event.playlistId) {
                return playlist;
              }

              return playlist.copyWith(
                trackCount: (playlist.trackCount - 1).clamp(0, 1 << 31),
              );
            })
            .toList(growable: false),
      ),
    );

    try {
      await _playlistsStorage.removeTrackFromPlaylist(
        trackId: event.trackId,
        playlistId: event.playlistId,
      );
      final updatedPendingIds = Set<int>.of(state.pendingTrackPlaylistActionIds)
        ..remove(event.trackId);
      emit(state.copyWith(pendingTrackPlaylistActionIds: updatedPendingIds));
      _emitFeedback(emit, message: 'Track removed from playlist.');
    } catch (error, stackTrace) {
      final updatedPendingIds = Set<int>.of(state.pendingTrackPlaylistActionIds)
        ..remove(event.trackId);
      emit(
        state.copyWith(
          pendingTrackPlaylistActionIds: updatedPendingIds,
          playlistTracksById: {
            ...state.playlistTracksById,
            event.playlistId: previousTracks,
          },
          playlists: state.playlists
              .map((playlist) {
                if (playlist.id != event.playlistId) {
                  return playlist;
                }

                return playlist.copyWith(trackCount: playlist.trackCount + 1);
              })
              .toList(growable: false),
        ),
      );
      _emitFeedback(
        emit,
        message: 'Failed to remove track from playlist.',
        isError: true,
      );
      await _reportError(
        'Failed to remove track ${event.trackId} from playlist ${event.playlistId}',
        error,
        stackTrace,
      );
    }
  }

  Future<void> _onReorderPlaylistTracksRequested(
    ReorderPlaylistTracksRequested event,
    Emitter<PlaylistsState> emit,
  ) async {
    final previousTracks = state.playlistTracksById[event.playlistId];
    if (previousTracks == null) {
      return;
    }

    final trackById = {for (final track in previousTracks) track.id: track};
    final reorderedTracks = event.trackIds
        .map((trackId) => trackById[trackId])
        .whereType<Track>()
        .toList(growable: false);
    if (reorderedTracks.length != previousTracks.length) {
      return;
    }

    final reorderingPlaylistIds = Set<int>.of(state.reorderingPlaylistIds)
      ..add(event.playlistId);
    emit(
      state.copyWith(
        reorderingPlaylistIds: reorderingPlaylistIds,
        playlistTracksById: {
          ...state.playlistTracksById,
          event.playlistId: reorderedTracks,
        },
      ),
    );

    try {
      await _playlistsStorage.reorderPlaylistTracks(
        playlistId: event.playlistId,
        trackIds: event.trackIds,
      );
      final updatedReorderingIds = Set<int>.of(state.reorderingPlaylistIds)
        ..remove(event.playlistId);
      emit(state.copyWith(reorderingPlaylistIds: updatedReorderingIds));
    } catch (error, stackTrace) {
      final updatedReorderingIds = Set<int>.of(state.reorderingPlaylistIds)
        ..remove(event.playlistId);
      emit(
        state.copyWith(
          reorderingPlaylistIds: updatedReorderingIds,
          playlistTracksById: {
            ...state.playlistTracksById,
            event.playlistId: previousTracks,
          },
        ),
      );
      _emitFeedback(
        emit,
        message: 'Failed to reorder playlist.',
        isError: true,
      );
      await _reportError(
        'Failed to reorder playlist ${event.playlistId}',
        error,
        stackTrace,
      );
    }
  }

  Future<void> _reportError(
    String message,
    Object error,
    StackTrace stackTrace,
  ) {
    return _errorReporter.reportError(
      AppError(message, cause: error, stackTrace: stackTrace),
    );
  }

  void _emitFeedback(
    Emitter<PlaylistsState> emit, {
    required String message,
    bool isError = false,
  }) {
    emit(
      state.copyWith(
        feedbackMessage: message,
        feedbackSerial: state.feedbackSerial + 1,
        isFeedbackError: isError,
      ),
    );
  }

  List<Playlist> _upsertPlaylist(List<Playlist> playlists, Playlist playlist) {
    final updated = playlists.where((item) => item.id != playlist.id).toList();
    updated.add(playlist);

    return _sortPlaylists(updated);
  }

  List<Playlist> _sortPlaylists(List<Playlist> playlists) {
    final sorted = playlists.toList(growable: false);
    sorted.sort((left, right) {
      if (left.isFavorites != right.isFavorites) {
        return left.isFavorites ? -1 : 1;
      }

      return left.name.toLowerCase().compareTo(right.name.toLowerCase());
    });

    return sorted;
  }

  Map<int, List<Track>> _mapTracks(
    Map<int, List<Track>> source,
    Track Function(Track track) mapper,
  ) {
    return {
      for (final entry in source.entries)
        entry.key: entry.value.map(mapper).toList(growable: false),
    };
  }

  List<Track> _applyFavoriteOverrides(List<Track> tracks) {
    return tracks
        .map(
          (track) => track.copyWith(
            isFavorite: state.favoriteOverrides[track.id] ?? track.isFavorite,
          ),
        )
        .toList(growable: false);
  }
}

class PlaylistsState extends Equatable {
  const PlaylistsState({
    required this.playlists,
    required this.isLoadingPlaylists,
    required this.playlistsErrorMessage,
    required this.playlistTracksById,
    required this.loadingPlaylistIds,
    required this.playlistErrorMessages,
    required this.isSubmittingPlaylist,
    required this.deletingPlaylistIds,
    required this.pendingFavoriteTrackIds,
    required this.pendingTrackPlaylistActionIds,
    required this.reorderingPlaylistIds,
    required this.favoriteOverrides,
    required this.feedbackMessage,
    required this.feedbackSerial,
    required this.isFeedbackError,
  });

  const PlaylistsState.initial()
    : this(
        playlists: const [],
        isLoadingPlaylists: false,
        playlistsErrorMessage: null,
        playlistTracksById: const {},
        loadingPlaylistIds: const {},
        playlistErrorMessages: const {},
        isSubmittingPlaylist: false,
        deletingPlaylistIds: const {},
        pendingFavoriteTrackIds: const {},
        pendingTrackPlaylistActionIds: const {},
        reorderingPlaylistIds: const {},
        favoriteOverrides: const {},
        feedbackMessage: null,
        feedbackSerial: 0,
        isFeedbackError: false,
      );

  final List<Playlist> playlists;
  final bool isLoadingPlaylists;
  final String? playlistsErrorMessage;
  final Map<int, List<Track>> playlistTracksById;
  final Set<int> loadingPlaylistIds;
  final Map<int, String> playlistErrorMessages;
  final bool isSubmittingPlaylist;
  final Set<int> deletingPlaylistIds;
  final Set<int> pendingFavoriteTrackIds;
  final Set<int> pendingTrackPlaylistActionIds;
  final Set<int> reorderingPlaylistIds;
  final Map<int, bool> favoriteOverrides;
  final String? feedbackMessage;
  final int feedbackSerial;
  final bool isFeedbackError;

  PlaylistsState copyWith({
    List<Playlist>? playlists,
    bool? isLoadingPlaylists,
    String? playlistsErrorMessage,
    bool clearPlaylistsError = false,
    Map<int, List<Track>>? playlistTracksById,
    Set<int>? loadingPlaylistIds,
    Map<int, String>? playlistErrorMessages,
    int? clearPlaylistErrorId,
    bool? isSubmittingPlaylist,
    Set<int>? deletingPlaylistIds,
    Set<int>? pendingFavoriteTrackIds,
    Set<int>? pendingTrackPlaylistActionIds,
    Set<int>? reorderingPlaylistIds,
    Map<int, bool>? favoriteOverrides,
    String? feedbackMessage,
    int? feedbackSerial,
    bool? isFeedbackError,
  }) {
    final nextPlaylistErrorMessages = Map<int, String>.of(
      playlistErrorMessages ?? this.playlistErrorMessages,
    );
    if (clearPlaylistErrorId != null) {
      nextPlaylistErrorMessages.remove(clearPlaylistErrorId);
    }

    return PlaylistsState(
      playlists: playlists ?? this.playlists,
      isLoadingPlaylists: isLoadingPlaylists ?? this.isLoadingPlaylists,
      playlistsErrorMessage: clearPlaylistsError
          ? null
          : (playlistsErrorMessage ?? this.playlistsErrorMessage),
      playlistTracksById: playlistTracksById ?? this.playlistTracksById,
      loadingPlaylistIds: loadingPlaylistIds ?? this.loadingPlaylistIds,
      playlistErrorMessages: nextPlaylistErrorMessages,
      isSubmittingPlaylist: isSubmittingPlaylist ?? this.isSubmittingPlaylist,
      deletingPlaylistIds: deletingPlaylistIds ?? this.deletingPlaylistIds,
      pendingFavoriteTrackIds:
          pendingFavoriteTrackIds ?? this.pendingFavoriteTrackIds,
      pendingTrackPlaylistActionIds:
          pendingTrackPlaylistActionIds ?? this.pendingTrackPlaylistActionIds,
      reorderingPlaylistIds:
          reorderingPlaylistIds ?? this.reorderingPlaylistIds,
      favoriteOverrides: favoriteOverrides ?? this.favoriteOverrides,
      feedbackMessage: feedbackMessage ?? this.feedbackMessage,
      feedbackSerial: feedbackSerial ?? this.feedbackSerial,
      isFeedbackError: isFeedbackError ?? this.isFeedbackError,
    );
  }

  @override
  List<Object?> get props => [
    playlists,
    isLoadingPlaylists,
    playlistsErrorMessage,
    playlistTracksById,
    loadingPlaylistIds,
    playlistErrorMessages,
    isSubmittingPlaylist,
    deletingPlaylistIds,
    pendingFavoriteTrackIds,
    pendingTrackPlaylistActionIds,
    reorderingPlaylistIds,
    favoriteOverrides,
    feedbackMessage,
    feedbackSerial,
    isFeedbackError,
  ];
}
