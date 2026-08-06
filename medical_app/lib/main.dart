import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app.dart';
import 'core/notifications/fcm_service.dart';   // ← 추가
import 'firebase_options.dart';

final fcmService = FcmService();   // ← 추가 (전역 싱글턴)

/// 앱 전역 라우터. app.dart의 _MedicalAppViewState.initState()에서 할당됨.
/// FCM 알림 탭(딥링크 이동) 등 위젯 트리 밖에서 네비게이션이 필요할 때 사용.
late GoRouter appRouter;

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MedicalApp());
}