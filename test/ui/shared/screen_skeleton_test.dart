import 'dart:async';

import 'package:esketit_music_app/domain/author.dart';
import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/domain/track_info/text_track_info.dart';
import 'package:esketit_music_app/errors/error_reporter/app_error.dart';
import 'package:esketit_music_app/errors/error_reporter/breadcrumb.dart';
import 'package:esketit_music_app/errors/error_reporter/error_reporter.dart';
import 'package:esketit_music_app/l10n/app_localizations.dart';
import 'package:esketit_music_app/ui/player/bottom_player.dart';
import 'package:esketit_music_app/ui/shared/screen_skeleton.dart';
import 'package:esketit_music_app/unassigned_layer/http_file.dart';
import 'package:esketit_music_app/use_case/player/audio_player.dart';
import 'package:esketit_music_app/use_case/player/bloc/player_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows BottomPlayer by default when a track is selected', (
    tester,
  ) async {
    final playerBloc = _createPlayerBloc(
      selectedTrack: _track(name: 'Track A'),
    );
    addTearDown(playerBloc.close);

    await tester.pumpWidget(_TestApp(playerBloc: playerBloc));

    expect(find.byType(BottomPlayer), findsOneWidget);
    expect(find.text('Track A'), findsOneWidget);
  });

  testWidgets('does not show BottomPlayer when disabled explicitly', (
    tester,
  ) async {
    final playerBloc = _createPlayerBloc(
      selectedTrack: _track(name: 'Track B'),
    );
    addTearDown(playerBloc.close);

    await tester.pumpWidget(
      _TestApp(
        playerBloc: playerBloc,
        child: const ScreenSkeleton(
          enableBottomPlayer: false,
          body: SizedBox.shrink(),
        ),
      ),
    );

    expect(find.byType(BottomPlayer), findsNothing);
    expect(find.text('Track B'), findsNothing);
  });
}

PlayerBloc _createPlayerBloc({Track? selectedTrack}) {
  return PlayerBloc(
    initialState: PlayerState(selectedTrack: selectedTrack, isPlaying: false),
    player: _FakeAudioPlayer(),
    errorReporter: _FakeErrorReporter(),
  );
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.playerBloc, this.child});

  final PlayerBloc playerBloc;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider<PlayerBloc>.value(
        value: playerBloc,
        child: child ?? const ScreenSkeleton(body: SizedBox.shrink()),
      ),
    );
  }
}

class _FakeAudioPlayer implements AudioPlayer {
  final StreamController<bool> _isPlayingController =
      StreamController<bool>.broadcast();
  final StreamController<Track?> _currentTrackController =
      StreamController<Track?>.broadcast();

  @override
  Stream<Track?> get currentTrackStream => _currentTrackController.stream;

  @override
  Stream<bool> get isPlayingStream => _isPlayingController.stream;

  @override
  Future<void> beginPlayingQueue(
    List<Track> tracks, {
    required int initialIndex,
  }) async {}

  @override
  Future<void> togglePlay() async {}

  @override
  Future<void> dispose() async {
    await _isPlayingController.close();
    await _currentTrackController.close();
  }
}

class _FakeErrorReporter implements ErrorReporter {
  @override
  Future<void> addBreadcrumb(Breadcrumb breadcrumb) async {}

  @override
  Future<void> reportError(AppError error) async {}

  @override
  Future<void> setUserId(String? id) async {}
}

Track _track({required String name}) {
  return Track(
    id: name.hashCode,
    name: name,
    authors: const [Author(id: 1, currentName: 'Track Author', photos: [])],
    addionalInfo: [TextTrackInfo(title: 'Mood', text: 'Warm')],
    file: HttpFile(uri: Uri()),
    image: HttpFile(uri: Uri()),
    isFavorite: false,
    isAvailable: true,
  );
}
