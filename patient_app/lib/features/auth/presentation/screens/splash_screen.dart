import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthState();
    });
  }

  Future<void> _checkAuthState() async {
    final authState = await ref.read(authProvider.future);

    if (!mounted) {
      return;
    }

    if (!authState.isLoggedIn) {
      context.go(RouteNames.login);
      return;
    }

    if (authState.isNewUser || !authState.isPhoneVerified) {
      context.go(RouteNames.phoneVerification);
      return;
    }

    if (authState.isAppLockEnabled &&
        !authState.isBiometricAuthenticated) {
      context.go(RouteNames.biometricAuth);
      return;
    }

    context.go(RouteNames.home);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.air_rounded,
              size: 72,
              color: AppColors.primary,
            ),
            SizedBox(height: 20),
            Text(
              '숨잇',
              style: AppTextStyles.displayLarge,
            ),
            SizedBox(height: 10),
            Text(
              '환자의 숨을 잇는 건강관리',
              style: AppTextStyles.bodyMedium,
            ),
            SizedBox(height: 32),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}