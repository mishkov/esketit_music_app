import 'package:bloc_test/bloc_test.dart';
import 'package:esketit_music_app/domain/track_lyrics.dart';
import 'package:esketit_music_app/use_case/lyrics/bloc/lyrics_bloc.dart';
import 'package:esketit_music_app/use_case/lyrics/lyrics_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  blocTest<LyricsBloc, LyricsState>(
    'loads lyrics successfully',
    build: () => LyricsBloc(
      lyricsStorage: _FakeLyricsStorage(lyricsByTrackId: {7: _lyrics}),
    ),
    act: (bloc) => bloc.add(const LoadTrackLyrics(7)),
    expect: () => [
      const LyricsState(
        trackId: 7,
        lyrics: null,
        isLoading: true,
        loadFailed: false,
      ),
      const LyricsState(
        trackId: 7,
        lyrics: _lyrics,
        isLoading: false,
        loadFailed: false,
      ),
    ],
  );

  blocTest<LyricsBloc, LyricsState>(
    'emits failure when loading lyrics throws',
    build: () =>
        LyricsBloc(lyricsStorage: _FakeLyricsStorage(shouldThrow: true)),
    act: (bloc) => bloc.add(const LoadTrackLyrics(7)),
    expect: () => const [
      LyricsState(trackId: 7, lyrics: null, isLoading: true, loadFailed: false),
      LyricsState(trackId: 7, lyrics: null, isLoading: false, loadFailed: true),
    ],
  );
}

const _lyrics = TrackLyrics(
  trackId: 7,
  type: TrackLyricsType.plain,
  languageCode: 'en',
  isVerified: true,
  source: 'artist',
  plainText: 'Full lyrics here',
  lines: [],
);

class _FakeLyricsStorage implements LyricsStorage {
  _FakeLyricsStorage({
    this.lyricsByTrackId = const {},
    this.shouldThrow = false,
  });

  final Map<int, TrackLyrics?> lyricsByTrackId;
  final bool shouldThrow;

  @override
  Future<TrackLyrics?> getTrackLyrics({required int trackId}) async {
    if (shouldThrow) {
      throw Exception('failed');
    }

    return lyricsByTrackId[trackId];
  }
}
