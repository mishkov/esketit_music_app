import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:esketit_music_app/errors/error_reporter/error_reporter.dart';
import 'package:esketit_music_app/esketit_rest_api/http_client.dart';
import 'package:esketit_music_app/esketit_rest_api/http_response.dart';
import 'package:esketit_music_app/key_value_storage/shared/key_value_storage.dart';
import 'package:esketit_music_app/use_case/analytics/analytics_app_error.dart';
import 'package:esketit_music_app/use_case/analytics/analytics_collecting.dart';
import 'package:esketit_music_app/use_case/analytics/analytics_event.dart';
import 'package:esketit_music_app/use_case/analytics/analytics_queue_storage.dart';

class ServerAnalyticsCollector implements AnalyticsCollecting {
  ServerAnalyticsCollector({
    required HttpClient httpClient,
    required AnalyticsQueueStorage queueStorage,
    required KeyValueStorage keyValueStorage,
    required ErrorReporter errorReporter,
    required String platform,
    required String appVersion,
    Duration flushInterval = const Duration(minutes: 10),
    bool flushImmediatelyAfterCollect = false,
    int maxBatchSize = 100,
  }) : _httpClient = httpClient,
       _queueStorage = queueStorage,
       _keyValueStorage = keyValueStorage,
       _errorReporter = errorReporter,
       _platform = platform,
       _appVersion = appVersion,
       _flushInterval = flushInterval,
       _flushImmediatelyAfterCollect = flushImmediatelyAfterCollect,
       _maxBatchSize = maxBatchSize,
       _sessionId = _generateId('session');

  static const String _eventsPath = '/analytics/events';
  static const String _clientIdStorageKey = 'analytics.client_id.v1';
  static const Duration _initialRetryDelay = Duration(minutes: 1);
  static const Duration _maximumRetryDelay = Duration(hours: 1);

  final HttpClient _httpClient;
  final AnalyticsQueueStorage _queueStorage;
  final KeyValueStorage _keyValueStorage;
  final ErrorReporter _errorReporter;
  final String _platform;
  final String _appVersion;
  final Duration _flushInterval;
  final bool _flushImmediatelyAfterCollect;
  final int _maxBatchSize;
  final String _sessionId;

  Timer? _timer;
  Future<void> _operation = Future<void>.value();

  @override
  Future<void> collect(AnalyticsEvent event) {
    return collectAll([event]);
  }

  @override
  Future<void> collectAll(List<AnalyticsEvent> events) {
    if (events.isEmpty) {
      return Future<void>.value();
    }

    return _schedule(() async {
      try {
        final queuedEvents = await _queueStorage.readAll();
        final nextEvents = [
          ...queuedEvents,
          ...events.map(QueuedAnalyticsEvent.initial),
        ];
        await _queueStorage.writeAll(nextEvents);
      } catch (error, stackTrace) {
        await _reportAnalyticsError(
          'Failed to queue analytics events',
          error: error,
          stackTrace: stackTrace,
          context: {'eventsCount': events.length},
        );
      }
      if (_flushImmediatelyAfterCollect) {
        await _flushReadyEvents();
      }
    });
  }

  @override
  Future<void> flushNow() {
    return _schedule(_flushReadyEvents);
  }

  @override
  void start() {
    _timer ??= Timer.periodic(_flushInterval, (_) {
      unawaited(flushNow());
    });
    unawaited(flushNow());
  }

  @override
  Future<void> dispose() async {
    _timer?.cancel();
    _timer = null;
    await _operation;
  }

  Future<void> _schedule(Future<void> Function() action) {
    final nextOperation = _operation.then((_) => action());
    _operation = nextOperation.catchError((
      Object error,
      StackTrace stackTrace,
    ) {
      return _reportAnalyticsError(
        'Unhandled analytics operation failure',
        error: error,
        stackTrace: stackTrace,
      );
    });

    return _operation;
  }

  Future<void> _flushReadyEvents() async {
    List<QueuedAnalyticsEvent> queuedEvents;
    try {
      queuedEvents = await _queueStorage.readAll();
    } catch (error, stackTrace) {
      await _reportAnalyticsError(
        'Failed to read queued analytics events',
        error: error,
        stackTrace: stackTrace,
      );

      return;
    }
    if (queuedEvents.isEmpty) {
      return;
    }

    final now = DateTime.now().toUtc();
    final readyEvents = queuedEvents
        .where((queuedEvent) => queuedEvent.isReadyAt(now))
        .take(_maxBatchSize)
        .toList(growable: false);
    if (readyEvents.isEmpty) {
      return;
    }

    final batchResult = await _sendBatch(readyEvents);
    switch (batchResult) {
      case _BatchDeliveryResult.delivered:
        await _removeQueuedEvents(readyEvents);
      case _BatchDeliveryResult.dropInvalid:
        await _reportAnalyticsError(
          'Dropping invalid analytics batch after server validation error',
          context: {
            'eventIds': readyEvents
                .map((event) => event.event.eventId)
                .join(','),
          },
        );
        await _removeQueuedEvents(readyEvents);
      case _BatchDeliveryResult.retryLater:
        await _markBatchForRetry(readyEvents);
    }
  }

  Future<_BatchDeliveryResult> _sendBatch(
    List<QueuedAnalyticsEvent> batch,
  ) async {
    final clientId = await _getClientId();
    final body = {
      'clientId': clientId,
      'sessionId': _sessionId,
      'platform': _platform,
      'appVersion': _appVersion,
      'events': batch.map((item) => item.event.toJson()).toList(),
    };

    HttpResponse response;
    try {
      // Delivery is acknowledged only by a successful server response. Events
      // remain queued across restarts until then; uninstalling or wiping local
      // storage before upload is the unavoidable limit of client-side delivery.
      response = await _httpClient.post(_eventsPath, body: body);
    } catch (error, stackTrace) {
      await _reportAnalyticsError(
        'Failed to upload analytics batch',
        error: error,
        stackTrace: stackTrace,
        context: {'eventsCount': batch.length},
      );

      return _BatchDeliveryResult.retryLater;
    }

    if (response.statusCode == 202) {
      if (_isConfirmedDelivery(response, expectedEventsCount: batch.length)) {
        return _BatchDeliveryResult.delivered;
      }
      await _reportAnalyticsError(
        'Analytics batch response did not confirm every submitted event',
        context: {
          'responseBody': response.response,
          'expectedEventsCount': batch.length,
        },
      );

      return _BatchDeliveryResult.retryLater;
    }
    if (response.statusCode == 400) {
      await _reportAnalyticsError(
        'Analytics batch rejected by server validation',
        context: {
          'statusCode': response.statusCode,
          'responseBody': response.response,
          'eventsCount': batch.length,
        },
      );

      return _BatchDeliveryResult.dropInvalid;
    }
    if (response.statusCode == 401) {
      await _reportAnalyticsError(
        'Analytics batch upload was unauthorized',
        context: {'responseBody': response.response},
      );

      return _BatchDeliveryResult.retryLater;
    }
    if (response.statusCode >= 500) {
      await _reportAnalyticsError(
        'Analytics batch upload failed with server error',
        context: {
          'statusCode': response.statusCode,
          'responseBody': response.response,
        },
      );

      return _BatchDeliveryResult.retryLater;
    }

    await _reportAnalyticsError(
      'Analytics batch upload failed with unexpected status',
      context: {
        'statusCode': response.statusCode,
        'responseBody': response.response,
      },
    );

    return _BatchDeliveryResult.retryLater;
  }

  bool _isConfirmedDelivery(
    HttpResponse response, {
    required int expectedEventsCount,
  }) {
    try {
      final body = _coerceJson(response.response);
      if (body is! Map<String, dynamic>) {
        throw const FormatException('Analytics response must be a JSON object');
      }
      final accepted = (body['accepted'] as num?)?.toInt() ?? 0;
      final duplicates = (body['duplicates'] as num?)?.toInt() ?? 0;

      return accepted + duplicates >= expectedEventsCount;
    } catch (error, stackTrace) {
      unawaited(
        _reportAnalyticsError(
          'Failed to parse analytics upload response',
          error: error,
          stackTrace: stackTrace,
          context: {'responseBody': response.response},
        ),
      );

      return false;
    }
  }

  Future<void> _removeQueuedEvents(List<QueuedAnalyticsEvent> batch) async {
    try {
      final deliveredIds = batch
          .map((queuedEvent) => queuedEvent.event.eventId)
          .toSet();
      final queuedEvents = await _queueStorage.readAll();
      await _queueStorage.writeAll(
        queuedEvents
            .where(
              (queuedEvent) =>
                  !deliveredIds.contains(queuedEvent.event.eventId),
            )
            .toList(growable: false),
      );
    } catch (error, stackTrace) {
      await _reportAnalyticsError(
        'Failed to remove delivered analytics events',
        error: error,
        stackTrace: stackTrace,
        context: {'eventsCount': batch.length},
      );
    }
  }

  Future<void> _markBatchForRetry(List<QueuedAnalyticsEvent> batch) async {
    try {
      final batchById = {for (final event in batch) event.event.eventId: event};
      final queuedEvents = await _queueStorage.readAll();
      final updatedEvents = queuedEvents
          .map((queuedEvent) {
            final failedEvent = batchById[queuedEvent.event.eventId];
            if (failedEvent == null) {
              return queuedEvent;
            }

            final nextAttemptCount = failedEvent.attemptCount + 1;
            return failedEvent.copyWith(
              attemptCount: nextAttemptCount,
              nextAttemptAt: DateTime.now().toUtc().add(
                _retryDelay(nextAttemptCount),
              ),
            );
          })
          .toList(growable: false);

      await _queueStorage.writeAll(updatedEvents);
    } catch (error, stackTrace) {
      await _reportAnalyticsError(
        'Failed to persist analytics retry state',
        error: error,
        stackTrace: stackTrace,
        context: {'eventsCount': batch.length},
      );
    }
  }

  Duration _retryDelay(int attemptCount) {
    final exponent = max(0, attemptCount - 1);
    final milliseconds =
        _initialRetryDelay.inMilliseconds * pow(2, exponent).toInt();

    return Duration(
      milliseconds: min(milliseconds, _maximumRetryDelay.inMilliseconds),
    );
  }

  Future<String> _getClientId() async {
    try {
      final existingClientId = await _keyValueStorage.getString(
        _clientIdStorageKey,
      );
      if (existingClientId != null && existingClientId.isNotEmpty) {
        return existingClientId;
      }
    } catch (error, stackTrace) {
      await _reportAnalyticsError(
        'Failed to read analytics client ID',
        error: error,
        stackTrace: stackTrace,
      );
    }

    final clientId = _generateId('client');
    try {
      await _keyValueStorage.setString(_clientIdStorageKey, clientId);
    } catch (error, stackTrace) {
      await _reportAnalyticsError(
        'Failed to persist analytics client ID',
        error: error,
        stackTrace: stackTrace,
      );
    }

    return clientId;
  }

  Future<void> _reportAnalyticsError(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) async {
    try {
      await _errorReporter.reportError(
        AnalyticsAppError(
          message,
          cause: error,
          stackTrace: stackTrace,
          context: context,
        ),
      );
    } catch (_) {
      // Analytics reporting must never escape into user-facing app logic.
    }
  }

  Object? _coerceJson(Object? responseBody) {
    if (responseBody is String) {
      return jsonDecode(responseBody);
    }

    return responseBody;
  }

  static String _generateId(String prefix) {
    return '$prefix-${AnalyticsEventIdGenerator.generate()}';
  }
}

enum _BatchDeliveryResult { delivered, retryLater, dropInvalid }
