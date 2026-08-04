import 'package:go_router/go_router.dart';

import '../auth/session_controller.dart';
import '../constants/user_role.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/doctor/screens/doctor_home_screen.dart';
import '../../features/nurse/screens/nurse_home_screen.dart';
import '../../features/splash/splash_screen.dart';

/// 앱 전체 라우팅.
///
/// 시작하면 스플래시(/splash)가 잠깐 뜨고 자동으로 /login으로 이동.
/// 로그인 안 되어 있으면 무조건 /login으로 보내고,
/// 로그인 되어 있는데 /login에 있으면 역할에 맞는 홈으로 보낸다.
/// 나중에 딥링크(예: 특정 케이스/알림 클릭)도 이 라우터에 경로 추가해서 붙이면 됨.
GoRouter buildRouter(SessionController session) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: session,
    redirect: (context, state) {
      final loggedIn = session.isLoggedIn;
      final atLogin = state.matchedLocation == '/login';
      final atSplash = state.matchedLocation == '/splash';

      if (!loggedIn) return (atLogin || atSplash) ? null : '/login';
      if (atLogin || atSplash) {
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
        path: '/doctor',
        builder: (context, state) => const DoctorHomeScreen(),
      ),
      GoRoute(
        path: '/nurse',
        builder: (context, state) => const NurseHomeScreen(),
      ),
    ],
  );
}