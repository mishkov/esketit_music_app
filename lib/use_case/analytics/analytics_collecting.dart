import 'package:esketit_music_app/use_case/analytics/analytics_event.dart';

abstract class AnalyticsCollecting {
  Future<void> collect(AnalyticsEvent event);

  Future<void> collectAll(List<AnalyticsEvent> events);

  Future<void> flushNow();

  void start();

  Future<void> dispose();
}

class NoopAnalyticsCollector implements AnalyticsCollecting {
  const NoopAnalyticsCollector();

  @override
  Future<void> collect(AnalyticsEvent event) async {}

  @override
  Future<void> collectAll(List<AnalyticsEvent> events) async {}

  @override
  Future<void> flushNow() async {}

  @override
  void start() {}

  @override
  Future<void> dispose() async {}
}
