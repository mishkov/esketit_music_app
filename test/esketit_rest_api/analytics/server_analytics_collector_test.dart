import 'dart:convert';

import 'package:esketit_music_app/errors/error_reporter/app_error.dart';
import 'package:esketit_music_app/errors/error_reporter/breadcrumb.dart';
import 'package:esketit_music_app/errors/error_reporter/error_reporter.dart';
import 'package:esketit_music_app/esketit_rest_api/analytics/server_analytics_collector.dart';
import 'package:esketit_music_app/esketit_rest_api/http_client.dart';
import 'package:esketit_music_app/esketit_rest_api/http_response.dart';
import 'package:esketit_music_app/key_value_storage/shared/key_value_storage.dart';
import 'package:esketit_music_app/use_case/analytics/analytics_event.dart';
import 'package:esketit_music_app/use_case/analytics/analytics_queue_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'analytics event serializes and survives durable queue round-trip',
    () async {
      final keyValueStorage = _MemoryKeyValueStorage();
      final queueStorage = KeyValueAnalyticsQueueStorage(
        keyValueStorage: keyValueStorage,
      );
      final event = AnalyticsEvent(
        eventId: 'event-1',
        type: AnalyticsEventType.search,
        searchQuery: 'ambient',
        metadata: {'resultCount': 3},
        clientTime: DateTime.utc(2026, 7, 2, 10),
      );

      await queueStorage.writeAll([QueuedAnalyticsEvent.initial(event)]);
      final restoredEvents = await queueStorage.readAll();

      expect(restoredEvents.single.event, event);
      expect(restoredEvents.single.attemptCount, 0);
    },
  );

  test(
    'flush removes events when accepted and duplicate counts confirm batch',
    () async {
      final keyValueStorage = _MemoryKeyValueStorage();
      final queueStorage = KeyValueAnalyticsQueueStorage(
        keyValueStorage: keyValueStorage,
      );
      await queueStorage.writeAll([
        QueuedAnalyticsEvent.initial(_event('event-1')),
        QueuedAnalyticsEvent.initial(_event('event-2')),
      ]);
      final httpClient = _FakeHttpClient(
        response: const HttpResponse(
          statusCode: 202,
          response: '{"accepted":1,"duplicates":1}',
        ),
      );
      final collector = _collector(
        httpClient: httpClient,
        queueStorage: queueStorage,
        keyValueStorage: keyValueStorage,
      );

      await collector.flushNow();

      expect(await queueStorage.readAll(), isEmpty);
      expect(httpClient.requests.single.path, '/analytics/events');
      final body = httpClient.requests.single.body as Map<String, dynamic>;
      expect(body['clientId'], isNotEmpty);
      expect(body['sessionId'], isNotEmpty);
      expect(body['platform'], 'android');
      expect(body['appVersion'], '2.3.3+20');
      expect(body['events'], hasLength(2));
    },
  );

  test('transient failure keeps events queued with retry state', () async {
    final keyValueStorage = _MemoryKeyValueStorage();
    final queueStorage = KeyValueAnalyticsQueueStorage(
      keyValueStorage: keyValueStorage,
    );
    await queueStorage.writeAll([
      QueuedAnalyticsEvent.initial(_event('event-1')),
    ]);
    final collector = _collector(
      httpClient: _FakeHttpClient(
        response: const HttpResponse(statusCode: 500, response: 'nope'),
      ),
      queueStorage: queueStorage,
      keyValueStorage: keyValueStorage,
    );

    await collector.flushNow();

    final queuedEvents = await queueStorage.readAll();
    expect(queuedEvents.single.event.eventId, 'event-1');
    expect(queuedEvents.single.attemptCount, 1);
    expect(queuedEvents.single.nextAttemptAt, isNotNull);
  });

  test(
    'validation failure is reported and dropped so queue is not blocked',
    () async {
      final keyValueStorage = _MemoryKeyValueStorage();
      final queueStorage = KeyValueAnalyticsQueueStorage(
        keyValueStorage: keyValueStorage,
      );
      await queueStorage.writeAll([
        QueuedAnalyticsEvent.initial(_event('event-1')),
      ]);
      final errorReporter = _FakeErrorReporter();
      final collector = _collector(
        httpClient: _FakeHttpClient(
          response: const HttpResponse(statusCode: 400, response: 'bad event'),
        ),
        queueStorage: queueStorage,
        keyValueStorage: keyValueStorage,
        errorReporter: errorReporter,
      );

      await collector.flushNow();

      expect(await queueStorage.readAll(), isEmpty);
      expect(errorReporter.errors, isNotEmpty);
    },
  );

  test('collector reports and swallows storage failures', () async {
    final errorReporter = _FakeErrorReporter();
    final collector = _collector(
      httpClient: _FakeHttpClient(
        response: const HttpResponse(
          statusCode: 202,
          response: '{"accepted":1,"duplicates":0}',
        ),
      ),
      queueStorage: _ThrowingAnalyticsQueueStorage(),
      keyValueStorage: _MemoryKeyValueStorage(),
      errorReporter: errorReporter,
    );

    await collector.collect(_event('event-1'));
    await collector.flushNow();

    expect(errorReporter.errors, isNotEmpty);
  });
}

ServerAnalyticsCollector _collector({
  required HttpClient httpClient,
  required AnalyticsQueueStorage queueStorage,
  required KeyValueStorage keyValueStorage,
  ErrorReporter? errorReporter,
}) {
  return ServerAnalyticsCollector(
    httpClient: httpClient,
    queueStorage: queueStorage,
    keyValueStorage: keyValueStorage,
    errorReporter: errorReporter ?? _FakeErrorReporter(),
    platform: 'android',
    appVersion: '2.3.3+20',
  );
}

AnalyticsEvent _event(String eventId) {
  return AnalyticsEvent(
    eventId: eventId,
    type: AnalyticsEventType.play,
    trackId: 1,
    clientTime: DateTime.utc(2026, 7, 2, 10),
  );
}

class _FakeHttpClient implements HttpClient {
  _FakeHttpClient({required this.response});

  final HttpResponse response;
  final List<_HttpRequest> requests = <_HttpRequest>[];

  @override
  Future<HttpResponse> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    requests.add(_HttpRequest(path: path, body: _cloneJsonBody(body)));

    return response;
  }

  @override
  Future<HttpResponse> delete(String path, {Map<String, String>? headers}) {
    throw UnimplementedError();
  }

  @override
  Future<HttpResponse> get(String path, {Map<String, String>? headers}) {
    throw UnimplementedError();
  }

  @override
  Future<HttpResponse> postMultipart(
    String path, {
    Map<String, String>? headers,
    required MultipartFileData file,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<HttpResponse> put(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) {
    throw UnimplementedError();
  }

  Object? _cloneJsonBody(Object? body) {
    if (body == null) {
      return null;
    }

    return jsonDecode(jsonEncode(body));
  }
}

class _HttpRequest {
  const _HttpRequest({required this.path, required this.body});

  final String path;
  final Object? body;
}

class _MemoryKeyValueStorage implements KeyValueStorage {
  final Map<String, String> values = <String, String>{};

  @override
  Future<String?> getString(String key) async => values[key];

  @override
  Future<void> setString(String key, String value) async {
    values[key] = value;
  }
}

class _ThrowingAnalyticsQueueStorage implements AnalyticsQueueStorage {
  @override
  Future<List<QueuedAnalyticsEvent>> readAll() async {
    throw StateError('storage failed');
  }

  @override
  Future<void> writeAll(List<QueuedAnalyticsEvent> events) async {
    throw StateError('storage failed');
  }
}

class _FakeErrorReporter implements ErrorReporter {
  final List<AppError> errors = <AppError>[];

  @override
  Future<void> addBreadcrumb(Breadcrumb breadcrumb) async {}

  @override
  Future<void> reportError(AppError error) async {
    errors.add(error);
  }

  @override
  Future<void> setUserId(String? id) async {}
}
