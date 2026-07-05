import 'dart:math';

import 'package:equatable/equatable.dart';

enum AnalyticsEventType {
  play('play'),
  pause('pause'),
  resume('resume'),
  seek('seek'),
  trackChange('track_change'),
  trackComplete('track_complete'),
  trackSkip('track_skip'),
  search('search'),
  searchResultClick('search_result_click'),
  playbackError('playback_error');

  const AnalyticsEventType(this.value);

  final String value;
}

final class AnalyticsEvent extends Equatable {
  AnalyticsEvent({
    String? eventId,
    required this.type,
    this.trackId,
    this.playlistId,
    this.albumId,
    this.positionMs,
    this.durationMs,
    this.searchQuery,
    Map<String, dynamic>? metadata,
    DateTime? clientTime,
  }) : eventId = eventId ?? AnalyticsEventIdGenerator.generate(),
       metadata = Map<String, dynamic>.unmodifiable(metadata ?? const {}),
       clientTime = (clientTime ?? DateTime.now()).toUtc();

  final String eventId;
  final AnalyticsEventType type;
  final int? trackId;
  final int? playlistId;
  final int? albumId;
  final int? positionMs;
  final int? durationMs;
  final String? searchQuery;
  final Map<String, dynamic> metadata;
  final DateTime clientTime;

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'type': type.value,
      if (trackId != null) 'trackId': trackId,
      if (playlistId != null) 'playlistId': playlistId,
      if (albumId != null) 'albumId': albumId,
      if (positionMs != null) 'positionMs': positionMs,
      if (durationMs != null) 'durationMs': durationMs,
      if (searchQuery != null) 'searchQuery': searchQuery,
      'metadata': metadata,
      'clientTime': clientTime.toUtc().toIso8601String(),
    };
  }

  factory AnalyticsEvent.fromJson(Map<String, dynamic> json) {
    return AnalyticsEvent(
      eventId: json['eventId'] as String,
      type: AnalyticsEventType.values.firstWhere(
        (type) => type.value == json['type'],
      ),
      trackId: _asInt(json['trackId']),
      playlistId: _asInt(json['playlistId']),
      albumId: _asInt(json['albumId']),
      positionMs: _asInt(json['positionMs']),
      durationMs: _asInt(json['durationMs']),
      searchQuery: json['searchQuery'] as String?,
      metadata: Map<String, dynamic>.from(
        (json['metadata'] as Map?) ?? const {},
      ),
      clientTime: DateTime.parse(json['clientTime'] as String).toUtc(),
    );
  }

  @override
  List<Object?> get props => [
    eventId,
    type,
    trackId,
    playlistId,
    albumId,
    positionMs,
    durationMs,
    searchQuery,
    metadata,
    clientTime,
  ];

  static int? _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }

    return null;
  }
}

final class AnalyticsEventIdGenerator {
  AnalyticsEventIdGenerator._();

  static final Random _random = Random.secure();

  static String generate({DateTime? now}) {
    final timestamp = (now ?? DateTime.now()).toUtc().microsecondsSinceEpoch;
    final randomPart = List<int>.generate(
      16,
      (_) => _random.nextInt(256),
      growable: false,
    ).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();

    return 'event-$timestamp-$randomPart';
  }
}
