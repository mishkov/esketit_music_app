import 'dart:async';

import 'package:esketit_music_app/use_case/agent/agent_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FirebaseAgentNotifications implements AgentNotifications {
  final _opened = StreamController<String>.broadcast();
  final _tokens = StreamController<String>.broadcast();
  StreamSubscription<RemoteMessage>? _openedSubscription;
  StreamSubscription<String>? _tokenSubscription;
  Future<void>? _initialization;
  String? _latestToken;

  @override
  bool get isConfigured =>
      const String.fromEnvironment('FIREBASE_PROJECT_ID').isNotEmpty &&
      (kIsWeb ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  @override
  Stream<String> get openedConversations => _opened.stream;

  @override
  Stream<String> get refreshedTokens => _tokens.stream;

  @override
  Future<void> initialize() {
    if (!isConfigured) return Future.value();
    final initialization = _initialization ??= _initialize();

    return initialization;
  }

  Future<void> _initialize() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: String.fromEnvironment('FIREBASE_API_KEY'),
          appId: String.fromEnvironment('FIREBASE_APP_ID'),
          messagingSenderId: String.fromEnvironment(
            'FIREBASE_MESSAGING_SENDER_ID',
          ),
          projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
          iosBundleId: String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID'),
        ),
      );
    }
    _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      _onOpened,
    );
    _tokenSubscription = FirebaseMessaging.instance.onRegistered.listen(
      _onRegistered,
    );
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _onOpened(initial);
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      await _register();
    }
  }

  void _onOpened(RemoteMessage message) {
    final identifier = message.data['chatId'];
    if (identifier is String && identifier.isNotEmpty) _opened.add(identifier);
  }

  void _onRegistered(String token) {
    _latestToken = token;
    _tokens.add(token);
  }

  Future<void> _register() => FirebaseMessaging.instance.register(
    vapidKey: kIsWeb
        ? const String.fromEnvironment('FIREBASE_WEB_VAPID_KEY')
        : null,
  );

  @override
  Future<String?> enable() async {
    await initialize();
    if (!isConfigured) return null;
    final settings = await FirebaseMessaging.instance.requestPermission();
    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      return null;
    }

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
    await _register();

    return _latestToken;
  }

  @override
  Future<void> reset() async {
    _latestToken = null;
    if (isConfigured && Firebase.apps.isNotEmpty) {
      await FirebaseMessaging.instance.unregister();
    }
  }

  @override
  Future<void> dispose() async {
    await _openedSubscription?.cancel();
    await _tokenSubscription?.cancel();
    await _opened.close();
    await _tokens.close();
  }
}
