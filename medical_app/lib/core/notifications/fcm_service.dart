
import 'dart:math';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../main.dart';
import '../api/auth_api.dart';
import '../api/device_token_api.dart';

/// FCM 초기화(권한요청/토큰발급/서버등록/포그라운드알림)를 담당.
/// 로그인 성공 직후 accessToken을 받아서 init() 호출하는 방식으로 사용.
/// 알림 표시는 포그라운드일 땐 인앱 배너(ForegroundMessageBanner)로, 백그라운드/종료 상태일
/// 땐 OS가 FCM notification 필드를 보고 자동으로 시스템 알림을 띄워준다 — 별도 로컬 알림 플러그인 불필요.
class FcmService {
  static const _keyDeviceId = 'fcm.deviceId';

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

  void _listenForegroundMessages() {
    FirebaseMessaging.onMessage.listen((message) {
      // 포그라운드에선 상단 인앱 배너(ForegroundMessageBanner)만 보여줌 — incomingMessage를
      // 구독하는 쪽(배너, 각 탭의 새로고침)에서 처리하므로 여기선 값만 갱신.
      if (message.notification == null) return;
      incomingMessage.value = message;
    });
  }

  /// 백그라운드/종료 상태에서 알림을 탭해 앱으로 들어온 경우 data['deep_link']로 이동.
  void _handleOpenedMessage(RemoteMessage message) {
    final deepLink = message.data['deep_link'];
    if (deepLink != null) navigateToDeepLink(deepLink);
  }

  /// 포그라운드 인앱 배너를 탭했을 때도 동일하게 이 메서드로 이동 처리(ForegroundMessageBanner에서 호출).
  void navigateToDeepLink(String deepLink) {
    debugPrint('[FCM] 딥링크 이동: $deepLink');
    appRouter.push(deepLink);
  }
}