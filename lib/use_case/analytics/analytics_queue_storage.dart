import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:esketit_music_app/key_value_storage/shared/key_value_storage.dart';
import 'package:esketit_music_app/use_case/analytics/analytics_event.dart';

class QueuedAnalyticsEvent extends Equatable {
  const QueuedAnalyticsEvent({
    required this.event,
    required this.queuedAt,
    required this.attemptCount,
    this.nextAttemptAt,
  });

  factory QueuedAnalyticsEvent.initial(AnalyticsEvent event) {
    return QueuedAnalyticsEvent(
      event: event,
      queuedAt: DateTime.now().toUtc(),
      attemptCount: 0,
    );
  }

  final AnalyticsEvent event;
  final DateTime queuedAt;
  final int attemptCount;
  final DateTime? nextAttemptAt;

  QueuedAnalyticsEvent copyWith({
    int? attemptCount,
    DateTime? nextAttemptAt,
    bool clearNextAttemptAt = false,
  }) {
    return QueuedAnalyticsEvent(
      event: event,
      queuedAt: queuedAt,
      attemptCount: attemptCount ?? this.attemptCount,
      nextAttemptAt: clearNextAttemptAt
          ? null
          : (nextAttemptAt ?? this.nextAttemptAt),
    );
  }

  bool isReadyAt(DateTime time) {
    final nextAttempt = nextAttemptAt;

    return nextAttempt == null || !nextAttempt.isAfter(time);
  }

  Map<String, dynamic> toJson() {
    return {
      'event': event.toJson(),
      'queuedAt': queuedAt.toUtc().toIso8601String(),
      'attemptCount': attemptCount,
      if (nextAttemptAt != null)
        'nextAttemptAt': nextAttemptAt!.toUtc().toIso8601String(),
    };
  }

  factory QueuedAnalyticsEvent.fromJson(Map<String, dynamic> json) {
    return QueuedAnalyticsEvent(
      event: AnalyticsEvent.fromJson(
        Map<String, dynamic>.from(json['event'] as Map),
      ),
      queuedAt: DateTime.parse(json['queuedAt'] as String).toUtc(),
      attemptCount: (json['attemptCount'] as num?)?.toInt() ?? 0,
      nextAttemptAt: json['nextAttemptAt'] == null
          ? null
          : DateTime.parse(json['nextAttemptAt'] as String).toUtc(),
    );
  }

  @override
  List<Object?> get props => [event, queuedAt, attemptCount, nextAttemptAt];
}

abstract class AnalyticsQueueStorage {
  Future<List<QueuedAnalyticsEvent>> readAll();

  Future<void> writeAll(List<QueuedAnalyticsEvent> events);
}

class KeyValueAnalyticsQueueStorage implements AnalyticsQueueStorage {
  const KeyValueAnalyticsQueueStorage({
    required KeyValueStorage keyValueStorage,
    this.storageKey = 'analytics.events.queue.v1',
  }) : _keyValueStorage = keyValueStorage;

  final KeyValueStorage _keyValueStorage;
  final String storageKey;

  @override
  Future<List<QueuedAnalyticsEvent>> readAll() async {
    final encoded = await _keyValueStorage.getString(storageKey);
    if (encoded == null || encoded.isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(encoded);
    if (decoded is! List) {
      throw const FormatException('Analytics queue must be a JSON list');
    }

    return decoded
        .whereType<Map>()
        .map(
          (item) =>
              QueuedAnalyticsEvent.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList(growable: false);
  }

  @override
  Future<void> writeAll(List<QueuedAnalyticsEvent> events) {
    return _keyValueStorage.setString(
      storageKey,
      jsonEncode(events.map((event) => event.toJson()).toList()),
    );
  }
}
