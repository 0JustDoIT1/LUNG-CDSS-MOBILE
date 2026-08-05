
import 'dart:math';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/auth_api.dart';
import '../api/device_token_api.dart';

/// FCM 초기화(권한요청/토큰발급/서버등록/안드로이드채널/포그라운드알림)를 담당.
/// 로그인 성공 직후 accessToken을 받아서 init() 호출하는 방식으로 사용.
class FcmService {
  static const _keyDeviceId = 'fcm.deviceId';
  static const _androidChannelId = 'medical_app_default';
  static const _androidChannelName = '기본 알림';

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init(String accessToken) async {
    // 권한요청
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return; // 거부 시 조용히 종료 — 앱 사용엔 지장 없어야 함
    }

    if (!_initialized) {
      await _setupAndroidChannel();
      _listenForegroundMessages();
      _initialized = true;
    }

    // 토큰 발급 + 서버 등록
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await _registerToken(token, accessToken);
    }

    // 토큰이 갱신될 때마다(드물게 발생) 재등록
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      _registerToken(newToken, accessToken);
    });
  }

  Future<void> _registerToken(String fcmToken, String accessToken) async {
    final deviceId = await _getOrCreateDeviceId();
    try {
      await registerDeviceToken(
        fcmToken: fcmToken,
        deviceId: deviceId,
        accessToken: accessToken,
      );
    } on ApiException catch (_) {
      // 등록 실패해도 조용히 무시 — 다음 앱 실행 시 재시도됨
    }
  }

  Future<String> _getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    var deviceId = prefs.getString(_keyDeviceId);
    if (deviceId == null) {
      deviceId = _generateDeviceId();
      await prefs.setString(_keyDeviceId, deviceId);
    }
    return deviceId;
  }

  String _generateDeviceId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    // UUID v4 형식으로 맞춤
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int start, int end) =>
        bytes.sublist(start, end).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
  }

  Future<void> _setupAndroidChannel() async {
    const channel = AndroidNotificationChannel(
      _androidChannelId,
      _androidChannelName,
      description: '숨-잇 기본 알림 채널',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _localNotifications.initialize(initSettings);
  }

  void _listenForegroundMessages() {
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;

      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannelId,
            _androidChannelName,
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    });
  }
}