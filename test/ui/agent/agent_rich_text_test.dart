import 'package:esketit_music_app/domain/agent/agent_conversation.dart';
import 'package:esketit_music_app/errors/error_reporter/error_reporter.dart';
import 'package:esketit_music_app/l10n/app_localizations.dart';
import 'package:esketit_music_app/ui/agent/agent_message_card.dart';
import 'package:esketit_music_app/ui/agent/agent_question_card.dart';
import 'package:esketit_music_app/ui/agent/agent_rich_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/auth_test_support.dart';

const _source =
    'Released in 2010. [Official label](https://label.example/release)';
const _channel = MethodChannel('plugins.flutter.io/url_launcher');

void main() {
  final launches = <MethodCall>[];

  setUp(() {
    launches.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
          launches.add(call);

          return true;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  testWidgets('assistant citation is selectable and opens its HTTP source', (
    tester,
  ) async {
    final reporter = await _pump(
      tester,
      const AgentMessageCard(
        message: AgentMessage(
          id: 'research',
          role: AgentMessageRole.assistant,
          text: _source,
        ),
      ),
    );
    expect(find.byType(SelectionArea), findsOneWidget);
    expect(
      find.textContaining('[Official label]', findRichText: true),
      findsNothing,
    );
    await tester.tapOnText(find.textRange.ofSubstring('Official label'));
    await tester.pump();

    expect(launches.single.method, 'launch');
    expect(launches.single.arguments['url'], 'https://label.example/release');
    expect(launches.single.arguments['useSafariVC'], isFalse);
    expect(reporter.breadcrumbs.single.data, {'host': 'label.example'});
  });

  testWidgets('clarification questions render tappable citations and choices', (
    tester,
  ) async {
    await _pump(
      tester,
      const AgentQuestionCard(
        question: AgentQuestion(
          id: 'question',
          text: _source,
          options: ['Original', 'Remix'],
        ),
        isEnabled: false,
      ),
    );
    await tester.tapOnText(find.textRange.ofSubstring('Official label'));
    await tester.pump();

    expect(launches.single.arguments['url'], 'https://label.example/release');
    expect(find.widgetWithText(OutlinedButton, 'Original'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Remix'), findsOneWidget);
  });

  testWidgets('user messages keep literal Markdown text', (tester) async {
    await _pump(
      tester,
      const AgentMessageCard(
        message: AgentMessage(
          id: 'user',
          role: AgentMessageRole.user,
          text: _source,
        ),
      ),
    );
    expect(find.widgetWithText(SelectableText, _source), findsOneWidget);
    expect(find.byType(AgentRichText), findsNothing);
    expect(launches, isEmpty);
  });

  for (final destination in [
    'file:///private/data',
    'custom:open',
    '/relative',
    'https://name:password@label.example/release',
  ]) {
    testWidgets('does not open unsupported source $destination', (
      tester,
    ) async {
      await _pump(tester, AgentRichText(text: '[Source](<$destination>)'));
      await tester.tapOnText(find.textRange.ofSubstring('Source'));
      await tester.pump();
      expect(launches, isEmpty);
    });
  }

  testWidgets('research images do not load remote or local content', (
    tester,
  ) async {
    await _pump(
      tester,
      const AgentRichText(
        text:
            '![remote](https://label.example/cover.jpg)\n\n![local](file:///private/cover.jpg)',
      ),
    );
    expect(find.byType(Image), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final throwsError in [false, true]) {
    testWidgets(
      'source opening failure has localized feedback (throws: $throwsError)',
      (tester) async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(_channel, (_) async {
              if (throwsError) throw PlatformException(code: 'unavailable');

              return false;
            });
        await _pump(
          tester,
          const AgentRichText(text: _source),
          locale: const Locale('ru'),
        );
        await tester.tapOnText(find.textRange.ofSubstring('Official label'));
        await tester.pumpAndSettle();

        expect(find.byType(SnackBar), findsOneWidget);
        final context = tester.element(find.byType(AgentRichText));
        expect(
          find.text(AppLocalizations.of(context)!.requestFailedMessage),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}

Future<RecordingAuthErrorReporter> _pump(
  WidgetTester tester,
  Widget child, {
  Locale? locale,
}) async {
  final reporter = RecordingAuthErrorReporter();
  await tester.pumpWidget(
    RepositoryProvider<ErrorReporter>.value(
      value: reporter,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    ),
  );

  return reporter;
}
