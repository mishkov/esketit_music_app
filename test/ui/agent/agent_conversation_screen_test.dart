import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:esketit_music_app/domain/agent/agent_conversation.dart';
import 'package:esketit_music_app/domain/file/local_file.dart';
import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/l10n/app_localizations.dart';
import 'package:esketit_music_app/ui/agent/agent_conversation_screen.dart';
import 'package:esketit_music_app/ui/player/bottom_player.dart';
import 'package:esketit_music_app/use_case/agent/bloc/agent_conversation_bloc.dart';
import 'package:esketit_music_app/use_case/agent/bloc/agent_inbox_bloc.dart';
import 'package:esketit_music_app/use_case/player/bloc/player_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../use_case/agent/agent_test_support.dart';

void main() {
  testWidgets('draft input stays above the player and keyboard', (
    tester,
  ) async {
    await _pumpConversation(tester, selectedTrack: _track());
    _expectComposerAbovePlayer(tester);

    _setKeyboard(tester, 300);
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'First line\nSecond line');
    await tester.pump();

    _expectComposerAbovePlayer(tester, keyboardHeight: 300);
    expect(find.text('First line\nSecond line'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('existing chat allows a taller player with larger text', (
    tester,
  ) async {
    await _pumpConversation(
      tester,
      selectedTrack: _track(
        name: 'A longer track title that wraps onto multiple lines',
      ),
      conversation: testConversation(),
      textScaleFactor: 1.5,
    );
    _expectComposerAbovePlayer(tester);

    _setKeyboard(tester, 300);
    await tester.pump();

    _expectComposerAbovePlayer(tester, keyboardHeight: 300);
    expect(tester.takeException(), isNull);
  });

  testWidgets('adding and removing the player preserves the draft', (
    tester,
  ) async {
    final states = StreamController<PlayerState>();
    addTearDown(states.close);
    await _pumpConversation(tester, playerStates: states.stream);
    await tester.enterText(find.byType(TextField), 'Keep this draft');
    expect(find.byType(BottomPlayer), findsNothing);

    states.add(PlayerState(selectedTrack: _track(), isPlaying: true));
    await tester.pump();
    _expectComposerAbovePlayer(tester);
    expect(find.text('Keep this draft'), findsOneWidget);

    states.add(PlayerState(selectedTrack: null, isPlaying: false));
    await tester.pump();
    expect(find.byType(BottomPlayer), findsNothing);
    expect(find.text('Keep this draft'), findsOneWidget);
    expect(tester.getRect(find.byType(TextField)).bottom, closeTo(806, 1));
    expect(tester.takeException(), isNull);
  });
}

void _expectComposerAbovePlayer(
  WidgetTester tester, {
  double keyboardHeight = 0,
}) {
  final player = tester.getRect(find.byType(BottomPlayer));
  final input = tester.getRect(find.byType(TextField));
  final send = tester.getRect(find.byTooltip('Send'));
  expect(input.bottom, lessThanOrEqualTo(player.top));
  expect(send.bottom, lessThanOrEqualTo(player.top));
  expect(player.bottom, lessThanOrEqualTo(852 - keyboardHeight));
  expect(find.byType(TextField).hitTestable(), findsOneWidget);
  expect(find.byTooltip('Send').hitTestable(), findsOneWidget);
}

void _setKeyboard(WidgetTester tester, double height) {
  tester.view.viewInsets = FakeViewPadding(bottom: height);
  tester.view.padding = FakeViewPadding(bottom: height == 0 ? 34 : 0);
}

Future<void> _pumpConversation(
  WidgetTester tester, {
  Track? selectedTrack,
  AgentConversation? conversation,
  double textScaleFactor = 1,
  Stream<PlayerState> playerStates = const Stream.empty(),
}) async {
  tester.view.physicalSize = const Size(393, 852);
  tester.view.devicePixelRatio = 1;
  tester.view.viewPadding = const FakeViewPadding(bottom: 34);
  _setKeyboard(tester, 0);
  addTearDown(tester.view.reset);

  final player = _PlayerBloc();
  final inbox = _InboxBloc();
  final chat = _ConversationBloc();
  addTearDown(player.close);
  addTearDown(inbox.close);
  addTearDown(chat.close);
  whenListen(
    player,
    playerStates,
    initialState: PlayerState(
      selectedTrack: selectedTrack,
      isPlaying: selectedTrack != null,
    ),
  );
  whenListen(
    inbox,
    const Stream<AgentInboxState>.empty(),
    initialState: const AgentInboxState(canUseAgent: true),
  );
  whenListen(
    chat,
    const Stream<AgentConversationState>.empty(),
    initialState: AgentConversationState(conversation: conversation),
  );

  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider<PlayerBloc>.value(value: player),
        BlocProvider<AgentInboxBloc>.value(value: inbox),
        BlocProvider<AgentConversationBloc>.value(value: chat),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScaleFactor)),
          child: child!,
        ),
        home: const AgentConversationScreen(),
      ),
    ),
  );
  await tester.pump();
}

Track _track({String name = 'Example track'}) => Track(
  id: 1,
  name: name,
  authors: const [],
  addionalInfo: const [],
  file: LocalFile(path: ''),
  image: LocalFile(path: ''),
  isFavorite: false,
  isDisliked: false,
  isAvailable: true,
);

class _PlayerBloc extends MockBloc<PlayerEvent, PlayerState>
    implements PlayerBloc {
  @override
  Stream<PlayerPlaybackProgress> get playbackProgressStream =>
      const Stream.empty();
}

class _InboxBloc extends MockBloc<AgentInboxEvent, AgentInboxState>
    implements AgentInboxBloc {}

class _ConversationBloc
    extends MockBloc<AgentConversationEvent, AgentConversationState>
    implements AgentConversationBloc {
  @override
  AgentAttachment get attachment => const AgentAttachment(
    type: AgentItemType.track,
    id: 1,
    label: 'Example track',
  );
}
