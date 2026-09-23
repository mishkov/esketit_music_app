import 'dart:convert';

import 'package:esketit_music_app/errors/auth_app_error.dart';
import 'package:esketit_music_app/errors/error_reporter/breadcrumb.dart';
import 'package:esketit_music_app/errors/error_reporter/encrypter.dart';
import 'package:esketit_music_app/errors/error_reporter/sentry_error_reporter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart' as sentry;

void main() {
  test(
    'authentication event contains safe diagnostics and encrypted user id',
    () async {
      final transport = _RecordingTransport();
      await sentry.Sentry.init((options) {
        options
          ..dsn = 'https://public@example.com/1'
          ..transport = transport
          ..enableDartSymbolication = false;
      });
      addTearDown(sentry.Sentry.close);
      final reporter = SentryErrorReporter(encrypter: _TestEncrypter());
      await reporter.setUserId('raw-user-id');
      await reporter.addBreadcrumb(
        Breadcrumb(
          message: 'Authentication request started',
          context: 'authentication',
          data: const {'operation': 'refresh', 'hasSession': true},
        ),
      );
      final error = AuthAppError.from(
        operation: 'refresh',
        message: 'Authentication request failed',
        error: const FormatException('TOP-SECRET'),
        stackTrace: StackTrace.current,
        details: const {'statusCode': 401},
      );

      await reporter.reportError(error);

      final event = await transport.singleEvent();
      final encodedEvent = jsonEncode(event);
      expect(encodedEvent, isNot(contains('raw-user-id')));
      expect(encodedEvent, isNot(contains('TOP-SECRET')));
      expect(event['user'], containsPair('id', 'encrypted-user-id'));
      expect(event['tags'], containsPair('auth.operation', 'refresh'));
      expect(
        event['contexts'],
        containsPair(
          'authentication',
          containsPair('failureKind', 'invalid_data'),
        ),
      );
      expect(
        event['breadcrumbs'],
        contains(containsPair('data', containsPair('operation', 'refresh'))),
      );
    },
  );
}

class _TestEncrypter implements Encrypter {
  @override
  Future<String> encrypt(String id) async => 'encrypted-user-id';
}

class _RecordingTransport implements sentry.Transport {
  final _envelopes = <sentry.SentryEnvelope>[];

  @override
  Future<sentry.SentryId?> send(sentry.SentryEnvelope envelope) async {
    _envelopes.add(envelope);

    return envelope.header.eventId;
  }

  Future<Map<String, dynamic>> singleEvent() async {
    expect(_envelopes, hasLength(1));
    final data = await _envelopes.single.items.first.dataFactory();

    return jsonDecode(utf8.decode(data)) as Map<String, dynamic>;
  }
}
