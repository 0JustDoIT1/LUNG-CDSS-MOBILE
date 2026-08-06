import 'package:flutter/foundation.dart';

/// 앱이 백그라운드에서 포그라운드로 돌아올 때마다 값이 바뀌는 전역 알림.
/// FCM 포그라운드 푸시는 앱이 화면에 떠있을 때 온 것만 감지하기 때문에,
/// 백그라운드에 있던 동안 놓친 변경사항을 앱 복귀 시 한 번 새로고침해서 보정하기 위함.
/// (탭들이 fcmService.incomingMessage를 구독하는 것과 동일한 패턴으로 구독해서 사용)
final ValueNotifier<int> appResumeNotifier = ValueNotifier(0);
