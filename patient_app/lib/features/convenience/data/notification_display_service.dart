import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationDisplayService {
  NotificationDisplayService({
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
  }) : _messaging = messaging ?? FirebaseMessaging.instance,
       _localNotifications =
           localNotifications ?? FlutterLocalNotificationsPlugin();

  static const String androidChannelId = 'patient_high_importance';
  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
        androidChannelId,
        '환자 주요 알림',
        description: '검사결과, 예약, 복약 등 주요 알림을 표시합니다.',
        importance: Importance.high,
      );

  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;
  final StreamController<String?> _openedDeepLinks =
      StreamController<String?>.broadcast();
  final Set<String> _shownMessageIds = <String>{};

  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  Future<void>? _startFuture;
  String? _initialDeepLink;

  Stream<String?> get openedDeepLinks => _openedDeepLinks.stream;

  Future<String?> getInitialDeepLink() async {
    await start();
    final deepLink = _initialDeepLink;
    _initialDeepLink = null;
    return deepLink;
  }

  Future<void> start() {
    return _startFuture ??= _initialize();
  }

  Future<void> _initialize() async {
    if (!_isSupportedMobilePlatform) return;

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        _openedDeepLinks.add(response.payload);
      },
    );

    if (defaultTargetPlatform == TargetPlatform.android) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_androidChannel);
    }

    final launchDetails = await _localNotifications
        .getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      _initialDeepLink = launchDetails?.notificationResponse?.payload;
    }

    try {
      await _messaging.requestPermission(alert: true, badge: true, sound: true);
    } catch (_) {
      // Permission denial or an unsupported runtime must not block app startup.
    }

    _foregroundSubscription ??= FirebaseMessaging.onMessage.listen((message) {
      unawaited(_showForegroundNotification(message).catchError((_) {}));
    }, onError: (_) {});
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final deepLink = message.data['deep_link'];
    final messageId = message.messageId;
    final messageKey =
        messageId ??
        '${message.sentTime?.millisecondsSinceEpoch}|'
            '${notification.title}|${notification.body}|$deepLink';
    if (!_shownMessageIds.add(messageKey)) return;
    if (_shownMessageIds.length > 100) {
      _shownMessageIds.remove(_shownMessageIds.first);
    }

    await _localNotifications.show(
      messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          androidChannelId,
          '환자 주요 알림',
          channelDescription: '검사결과, 예약, 복약 등 주요 알림을 표시합니다.',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: deepLink is String ? deepLink : null,
    );
  }

  bool get _isSupportedMobilePlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<void> dispose() async {
    await _foregroundSubscription?.cancel();
    await _openedDeepLinks.close();
  }
}
