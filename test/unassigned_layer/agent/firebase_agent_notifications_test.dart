import 'dart:async';

import 'package:esketit_music_app/unassigned_layer/agent/firebase_agent_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:firebase_messaging_platform_interface/firebase_messaging_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final core = _FirebaseCore();
  final messaging = _FirebaseMessaging();

  setUpAll(() {
    FirebasePlatform.instance = core;
    FirebaseMessagingPlatform.instance = messaging;
  });

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    core.apps.clear();
    messaging.reset();
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  tearDownAll(() => messaging.registrations.close());

  test(
    'initialization waits for Apple registration and restores foreground alerts',
    () async {
      final notifications = _createNotifications();
      messaging.authorization = AuthorizationStatus.authorized;
      messaging.pendingAppleTokens = 1;
      final token = notifications.refreshedTokens.first;

      await notifications.initialize();

      expect(await token, 'installation-id');
      expect(messaging.appleTokenReads, 2);
      expect(messaging.registerCount, 1);
      expect(messaging.foregroundAlerts, isTrue);
      expect(messaging.permissionRequests, 0);
    },
  );

  test(
    'failed initialization can retry without duplicate stream subscriptions',
    () async {
      final notifications = _createNotifications();
      messaging.initialMessageFailures = 1;
      final tokens = <String>[];
      final subscription = notifications.refreshedTokens.listen(tokens.add);
      addTearDown(subscription.cancel);

      await expectLater(notifications.initialize(), throwsStateError);
      expect(messaging.registrations.hasListener, isFalse);
      await notifications.initialize();
      messaging.registrations.add('refreshed-installation');
      await Future<void>.delayed(Duration.zero);

      expect(tokens, ['refreshed-installation']);
    },
  );

  test(
    'startup does not ask permission and enabling registers after consent',
    () async {
      final notifications = _createNotifications();
      await notifications.initialize();
      expect(messaging.permissionRequests, 0);
      expect(messaging.registerCount, 0);
      final token = notifications.refreshedTokens.first;

      await notifications.enable();

      expect(await token, 'installation-id');
      expect(messaging.permissionRequests, 1);
      expect(messaging.registerCount, 1);
    },
  );

  test(
    'a transient startup registration failure does not disable later enabling',
    () async {
      final notifications = _createNotifications();
      messaging.authorization = AuthorizationStatus.authorized;
      messaging.registrationFailures = 1;
      await expectLater(notifications.initialize(), throwsStateError);

      final token = notifications.refreshedTokens.first;
      await notifications.enable();

      expect(await token, 'installation-id');
    },
  );

  test(
    'an unavailable Apple token can be retried without premature FCM registration',
    () async {
      final notifications = _createNotifications();
      messaging.pendingAppleTokens = 20;
      await expectLater(
        notifications.enable(),
        throwsA(isA<TimeoutException>()),
      );
      expect(messaging.registerCount, 0);

      messaging.pendingAppleTokens = 0;
      final token = notifications.refreshedTokens.first;
      await notifications.enable();

      expect(await token, 'installation-id');
    },
  );

  test(
    'cold start and background notification taps preserve their chat targets',
    () async {
      final notifications = _createNotifications();
      messaging.initialMessage = const RemoteMessage(
        data: {'chatId': 'cold-chat'},
      );
      final initial = notifications.openedConversations.first;
      await notifications.initialize();
      expect(await initial, 'cold-chat');

      final background = notifications.openedConversations.first;
      FirebaseMessagingPlatform.onMessageOpenedApp.add(
        const RemoteMessage(data: {'chatId': 'background-chat'}),
      );
      expect(await background, 'background-chat');
    },
  );

  test(
    'native registration errors are forwarded and the stream can recover',
    () async {
      final notifications = _createNotifications();
      await notifications.initialize();
      final result = expectLater(
        notifications.refreshedTokens,
        emitsInOrder([emitsError(isA<StateError>()), 'recovered-installation']),
      );
      messaging.registrations.addError(StateError('Registration unavailable'));
      messaging.registrations.add('recovered-installation');
      await result;
    },
  );
}

const _options = FirebaseOptions(
  apiKey: 'test-api-key',
  appId: 'test-app',
  messagingSenderId: 'test-sender',
  projectId: 'test-project',
);

FirebaseAgentNotifications _createNotifications() {
  final notifications = FirebaseAgentNotifications(options: _options);
  addTearDown(notifications.dispose);

  return notifications;
}

class _FirebaseCore extends FirebasePlatform {
  @override
  final List<FirebaseAppPlatform> apps = [];

  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) =>
      apps.single;

  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    final application = FirebaseAppPlatform(
      name ?? defaultFirebaseAppName,
      options ?? _options,
    );
    apps.add(application);

    return application;
  }
}

class _FirebaseMessaging extends FirebaseMessagingPlatform {
  final registrations = StreamController<String>.broadcast();
  AuthorizationStatus authorization = AuthorizationStatus.notDetermined;
  RemoteMessage? initialMessage;
  int initialMessageFailures = 0;
  int registrationFailures = 0;
  int pendingAppleTokens = 0;
  int appleTokenReads = 0;
  int registerCount = 0;
  int permissionRequests = 0;
  bool foregroundAlerts = false;

  void reset() {
    authorization = AuthorizationStatus.notDetermined;
    initialMessage = null;
    initialMessageFailures = 0;
    registrationFailures = 0;
    pendingAppleTokens = 0;
    appleTokenReads = 0;
    registerCount = 0;
    permissionRequests = 0;
    foregroundAlerts = false;
  }

  @override
  FirebaseMessagingPlatform delegateFor({required FirebaseApp app}) => this;

  @override
  FirebaseMessagingPlatform setInitialValues({bool? isAutoInitEnabled}) => this;

  @override
  Stream<String> get onRegistered => registrations.stream;

  @override
  Future<RemoteMessage?> getInitialMessage() async {
    if (initialMessageFailures > 0) {
      initialMessageFailures--;
      throw StateError('Temporary platform failure');
    }

    return initialMessage;
  }

  @override
  Future<NotificationSettings> getNotificationSettings() async =>
      _settings(authorization);

  @override
  Future<NotificationSettings> requestPermission({
    bool alert = true,
    bool announcement = false,
    bool badge = true,
    bool carPlay = false,
    bool criticalAlert = false,
    bool provisional = false,
    bool sound = true,
    bool providesAppNotificationSettings = false,
  }) async {
    permissionRequests++;
    authorization = AuthorizationStatus.authorized;

    return _settings(authorization);
  }

  @override
  Future<String?> getAPNSToken() async {
    appleTokenReads++;
    if (pendingAppleTokens > 0) {
      pendingAppleTokens--;

      return null;
    }

    return 'apple-token';
  }

  @override
  Future<void> register({
    String? vapidKey,
    String? serviceWorkerScriptPath,
  }) async {
    registerCount++;
    if (registrationFailures > 0) {
      registrationFailures--;
      throw StateError('Temporary registration failure');
    }
    registrations.add('installation-id');
  }

  @override
  Future<void> setForegroundNotificationPresentationOptions({
    bool alert = false,
    bool badge = false,
    bool sound = false,
  }) async {
    foregroundAlerts = alert && badge && sound;
  }
}

NotificationSettings _settings(AuthorizationStatus authorization) =>
    NotificationSettings(
      authorizationStatus: authorization,
      alert: AppleNotificationSetting.enabled,
      announcement: AppleNotificationSetting.disabled,
      badge: AppleNotificationSetting.enabled,
      carPlay: AppleNotificationSetting.disabled,
      lockScreen: AppleNotificationSetting.enabled,
      notificationCenter: AppleNotificationSetting.enabled,
      showPreviews: AppleShowPreviewSetting.always,
      timeSensitive: AppleNotificationSetting.disabled,
      criticalAlert: AppleNotificationSetting.disabled,
      sound: AppleNotificationSetting.enabled,
      providesAppNotificationSettings: AppleNotificationSetting.disabled,
    );
