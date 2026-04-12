import 'package:equatable/equatable.dart';
import 'package:esketit_music_app/domain/track_lyrics.dart';
import 'package:esketit_music_app/use_case/lyrics/lyrics_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class LyricsEvent extends Equatable {
  const LyricsEvent();

  @override
  List<Object?> get props => [];
}

final class LoadTrackLyrics extends LyricsEvent {
  const LoadTrackLyrics(this.trackId);

  final int trackId;

  @override
  List<Object?> get props => [trackId];
}

class LyricsBloc extends Bloc<LyricsEvent, LyricsState> {
  LyricsBloc({required LyricsStorage lyricsStorage})
    : _lyricsStorage = lyricsStorage,
      super(const LyricsState.initial()) {
    on<LoadTrackLyrics>(_onLoadTrackLyrics);
  }

  final LyricsStorage _lyricsStorage;

  Future<void> _onLoadTrackLyrics(
    LoadTrackLyrics event,
    Emitter<LyricsState> emit,
  ) async {
    if (state.isLoading && state.trackId == event.trackId) {
      return;
    }

    emit(
      LyricsState(
        trackId: event.trackId,
        lyrics: state.trackId == event.trackId ? state.lyrics : null,
        isLoading: true,
        loadFailed: false,
      ),
    );

    try {
      final lyrics = await _lyricsStorage.getTrackLyrics(
        trackId: event.trackId,
      );
      emit(
        LyricsState(
          trackId: event.trackId,
          lyrics: lyrics,
          isLoading: false,
          loadFailed: false,
        ),
      );
    } catch (_) {
      emit(
        LyricsState(
          trackId: event.trackId,
          lyrics: null,
          isLoading: false,
          loadFailed: true,
        ),
      );
    }
  }
}

class LyricsState extends Equatable {
  const LyricsState({
    required this.trackId,
    required this.lyrics,
    required this.isLoading,
    required this.loadFailed,
  });

  const LyricsState.initial()
    : trackId = null,
      lyrics = null,
      isLoading = false,
      loadFailed = false;

  final int? trackId;
  final TrackLyrics? lyrics;
  final bool isLoading;
  final bool loadFailed;

  @override
  List<Object?> get props => [trackId, lyrics, isLoading, loadFailed];
}
