
import 'dart:math';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../main.dart';
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

  /// 앱이 포그라운드일 때 도착한 푸시. 화면단 배지 새로고침/상단 배너 표시용.
  /// 값이 바뀔 때마다(매 수신마다) 알림 — 상단 배너 위젯, 채팅탭/홈쉘이 구독함.
  final ValueNotifier<RemoteMessage?> incomingMessage = ValueNotifier(null);

  bool _initialized = false;

  Future<void> init(String accessToken) async {
    debugPrint('[FCM] init() 시작');
    try {
      // 권한요청
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('[FCM] 권한 상태: ${settings.authorizationStatus}');
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('[FCM] 권한 거부됨 — 토큰 등록 중단');
        return; // 거부 시 조용히 종료 — 앱 사용엔 지장 없어야 함
      }

      if (!_initialized) {
        await _setupAndroidChannel();
        _listenForegroundMessages();
        _initialized = true;

        // 종료 상태에서 알림 탭으로 앱이 시작된 경우
        final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
        if (initialMessage != null) {
          debugPrint('[FCM] 종료 상태에서 알림 탭으로 앱 시작됨');
          _handleOpenedMessage(initialMessage);
        }

        // 백그라운드 상태에서 알림을 탭해 앱이 포그라운드로 올라온 경우
        FirebaseMessaging.onMessageOpenedApp.listen((message) {
          debugPrint('[FCM] 백그라운드 상태에서 알림 탭됨');
          _handleOpenedMessage(message);
        });
      }

      // 토큰 발급 + 서버 등록
      final token = await FirebaseMessaging.instance.getToken();
      debugPrint('[FCM] getToken() 결과: ${token == null ? 'null' : '${token.substring(0, 12)}...(len=${token.length})'}');
      if (token != null) {
        await _registerToken(token, accessToken);
      } else {
        debugPrint('[FCM] 토큰이 null이라 서버 등록을 건너뜀');
      }

      // 토큰이 갱신될 때마다(드물게 발생) 재등록
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        debugPrint('[FCM] onTokenRefresh 발생 — 재등록 시도');
        _registerToken(newToken, accessToken);
      });
    } catch (e, st) {
      debugPrint('[FCM] init() 중 예외 발생: $e\n$st');
    }
  }

  Future<void> _registerToken(String fcmToken, String accessToken) async {
    final deviceId = await _getOrCreateDeviceId();
    debugPrint('[FCM] POST /api/auth/device-token/ 호출 시도 (deviceId=$deviceId)');
    try {
      await registerDeviceToken(
        fcmToken: fcmToken,
        deviceId: deviceId,
        accessToken: accessToken,
      );
      debugPrint('[FCM] 디바이스 토큰 서버 등록 성공');
    } on ApiException catch (e) {
      // 등록 실패해도 앱 동작엔 영향 없음 — 다음 앱 실행 시 재시도됨. 원인 파악용으로 로그만 남김.
      debugPrint('[FCM] 디바이스 토큰 서버 등록 실패: ${e.message}');
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
    await _localNotifications.initialize(
      initSettings,
      // 포그라운드에서 직접 띄운 로컬 알림을 탭했을 때 — payload에 deep_link를 담아 전달함
      onDidReceiveNotificationResponse: (response) {
        final deepLink = response.payload;
        debugPrint('[FCM] 포그라운드 로컬 알림 탭됨 (deepLink=$deepLink)');
        if (deepLink != null) _navigateToDeepLink(deepLink);
      },
    );
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
        payload: message.data['deep_link'],
      );

      incomingMessage.value = message;
    });
  }

  /// 백그라운드/종료 상태에서 알림을 탭해 앱으로 들어온 경우 data['deep_link']로 이동.
  void _handleOpenedMessage(RemoteMessage message) {
    final deepLink = message.data['deep_link'];
    if (deepLink != null) _navigateToDeepLink(deepLink);
  }

  void _navigateToDeepLink(String deepLink) {
    debugPrint('[FCM] 딥링크 이동: $deepLink');
    appRouter.push(deepLink);
  }
}