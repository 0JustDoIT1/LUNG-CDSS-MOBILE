import 'package:go_router/go_router.dart';

import '../../core/widgets/main_shell.dart';
import '../../core/widgets/placeholder_screen.dart';
import 'route_names.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/phone_verification_screen.dart';
import '../../features/auth/presentation/screens/otp_verification_screen.dart';
import '../../features/auth/presentation/screens/pin_lock_screen.dart';
import '../../features/auth/presentation/screens/biometric_auth_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: RouteNames.splash,
  routes: [
    GoRoute(
      path: RouteNames.splash,
      builder: (context, state) {
        return const SplashScreen();
      },
    ),

    GoRoute(
      path: RouteNames.login,
      builder: (context, state) {
        return const LoginScreen();
      },
    ),

    GoRoute(
      path: RouteNames.phoneVerification,
      builder: (context, state) {
        return const PhoneVerificationScreen();
      },
    ),

    GoRoute(
      path: RouteNames.otpVerification,
      builder: (context, state) {
        final phoneNumber = state.extra as String? ?? '';

        return OtpVerificationScreen(
          phoneNumber: phoneNumber,
        );
      },
    ),

    GoRoute(
      path: RouteNames.biometricAuth,
      builder: (context, state) {
        return const BiometricAuthScreen();
      },
    ),

    GoRoute(
      path: RouteNames.pinLock,
      builder: (context, state) {
        return const PinLockScreen();
      },
    ),



    ShellRoute(
      builder: (context, state, child) {
        return MainShell(
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: RouteNames.symptoms,
          builder: (context, state) {
            return const PlaceholderScreen(
              title: '증상·복약',
            );
          },
        ),
        GoRoute(
          path: RouteNames.appointments,
          builder: (context, state) {
            return const PlaceholderScreen(
              title: '예약',
            );
          },
        ),
        GoRoute(
          path: RouteNames.home,
          builder: (context, state) {
            return const HomeScreen();
          },
        ),
        GoRoute(
          path: RouteNames.results,
          builder: (context, state) {
            return const PlaceholderScreen(
              title: '검사',
            );
          },
        ),
        GoRoute(
          path: RouteNames.more,
          builder: (context, state) {
            return const PlaceholderScreen(
              title: '더보기',
            );
          },
        ),
      ],
    ),

    GoRoute(
      path: RouteNames.medication,
      builder: (context, state) {
        return const PlaceholderScreen(
          title: '복약관리',
        );
      },
    ),

    GoRoute(
      path: RouteNames.chatbot,
      builder: (context, state) {
        return const PlaceholderScreen(
          title: 'AI 챗봇',
        );
      },
    ),

    GoRoute(
      path: RouteNames.notifications,
      builder: (context, state) {
        return const PlaceholderScreen(
          title: '알림',
        );
      },
    ),

    GoRoute(
      path: RouteNames.patientQr,
      builder: (context, state) {
        return const PlaceholderScreen(
          title: '진료카드 QR',
        );
      },
    ),

    GoRoute(
      path: RouteNames.intakeForm,
      builder: (context, state) {
        return const PlaceholderScreen(
          title: '문진표',
        );
      },
    ),

    GoRoute(
      path: RouteNames.settings,
      builder: (context, state) {
        return const PlaceholderScreen(
          title: '설정',
        );
      },
    ),
  ],
);