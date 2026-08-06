import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../auth/session_controller.dart';
import '../constants/user_role.dart';
import '../security/security_settings_controller.dart';
import '../../features/auth/screens/biometric_auth_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/pin_lock_screen.dart';
import '../../features/doctor/screens/doctor_home_screen.dart';
import '../../features/nurse/screens/nurse_home_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../chat/chat_deep_link_screen.dart';

/// 앱 전체 라우팅.
///
/// 시작하면 스플래시(/splash)가 잠깐 뜨고 자동으로 /login으로 이동.
/// 로그인 안 되어 있으면 무조건 /login으로 보내고,
/// 로그인 되어 있는데 앱잠금이 아직 안 풀렸으면 /pin-lock(또는 /biometric-auth)으로 보낸다.
/// 로그인 + 잠금해제 상태에서 /login,/pin-lock,/biometric-auth,/splash에 있으면 역할별 홈으로 보낸다.
/// 나중에 딥링크(예: 특정 케이스/알림 클릭)도 이 라우터에 경로 추가해서 붙이면 됨.
GoRouter buildRouter(SessionController session, SecuritySettingsController security) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: Listenable.merge([session, security]),
    redirect: (context, state) {
      final loggedIn = session.isLoggedIn;
      final atLogin = state.matchedLocation == '/login';
      final atSplash = state.matchedLocation == '/splash';
      final atPinLock = state.matchedLocation == '/pin-lock';
      final atBiometric = state.matchedLocation == '/biometric-auth';

      if (!loggedIn) return (atLogin || atSplash) ? null : '/login';

      if (security.needsUnlock) {
        if (atPinLock || atBiometric) return null;
        return security.biometricEnabled ? '/biometric-auth' : '/pin-lock';
      }

      if (atLogin || atSplash || atPinLock || atBiometric) {
        return session.role == UserRole.doctor ? '/doctor' : '/nurse';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/pin-lock',
        builder: (context, state) => const PinLockScreen(),
      ),
      GoRoute(
        path: '/biometric-auth',
        builder: (context, state) => const BiometricAuthScreen(),
      ),
      GoRoute(
        path: '/doctor',
        builder: (context, state) => const DoctorHomeScreen(),
      ),
      GoRoute(
        path: '/nurse',
        builder: (context, state) => const NurseHomeScreen(),
      ),
      GoRoute(
        path: '/chat/:threadId',
        builder: (context, state) => ChatDeepLinkScreen(
          threadId: state.pathParameters['threadId']!,
        ),
      ),
    ],
  );
}