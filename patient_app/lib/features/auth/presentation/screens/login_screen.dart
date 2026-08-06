import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../convenience/data/notification_deep_link_coordinator.dart';
import '../../../convenience/presentation/providers/notification_deep_link_provider.dart';
import '../../data/kakao_sign_in_service.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  String? _loadingProvider;

  Future<void> _signIn(String provider) async {
    setState(() {
      _loadingProvider = provider;
    });

    await ref.read(authProvider.notifier).signInWithSocial(provider: provider);

    if (!mounted) {
      return;
    }

    setState(() {
      _loadingProvider = null;
    });

    final authAsync = ref.read(authProvider);

    if (authAsync.hasError) {
      if (authAsync.error is SocialLoginCancelledException) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_socialLoginErrorMessage(authAsync.error))),
      );
      return;
    }

    final authState = authAsync.value;

    if (authState == null) {
      return;
    }

    if (authState.isLoggedIn && !authState.isNewUser) {
      final navigationResult = ref
          .read(notificationDeepLinkCoordinatorProvider)
          .activateAndHandlePending();
      if (navigationResult != NotificationNavigationResult.navigated) {
        context.go(RouteNames.home);
      }
      return;
    }

    if (authState.isNewUser) {
      context.go(RouteNames.phoneVerification);
    }
  }

  String _socialLoginErrorMessage(Object? error) {
    if (error is KakaoLoginConfigurationException) {
      return '카카오 로그인 설정을 확인해주세요.';
    }
    if (error is KakaoLoginFailedException) {
      return '카카오 로그인에 실패했습니다. 네트워크 연결과 앱 설정을 확인해주세요.';
    }
    if (error is StateError) {
      return '소셜 로그인 토큰을 확인할 수 없습니다.';
    }
    if (error is UnsupportedError) {
      return error.message?.toString() ?? '지원하지 않는 로그인 방식입니다.';
    }
    if (error is ApiException) {
      if (error.statusCode == 400) return '소셜 로그인 정보를 확인해주세요.';
      if (error.statusCode == 401) return '소셜 로그인 인증이 유효하지 않습니다.';
      if (error.statusCode == 500 || error.statusCode == 503) {
        return '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
      }
      if (error.code == 'TIMEOUT') return '서버 응답 시간이 초과되었습니다.';
      if (error.code == 'CONNECTION_ERROR') {
        return '네트워크 연결을 확인해주세요.';
      }
    }
    return '로그인에 실패했습니다. 다시 시도해주세요.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset(
                    'assets/images/soomit_logo2.png',
                    width: 170,
                    height: 170,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 8),
                  const SizedBox(height: 10),
                  Text(
                    '환자의 숨을 잇는 건강관리',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  AppButton(
                    text: 'Google로 계속하기',
                    icon: Icons.g_mobiledata,
                    isOutlined: true,
                    isLoading: _loadingProvider == 'google',
                    onPressed: _loadingProvider == null
                        ? () => _signIn('google')
                        : null,
                  ),
                  const SizedBox(height: 12),

                  AppButton(
                    text: '카카오로 계속하기',
                    icon: Icons.chat_bubble_outline,
                    isLoading: _loadingProvider == 'kakao',
                    onPressed: _loadingProvider == null
                        ? () => _signIn('kakao')
                        : null,
                  ),
                  const SizedBox(height: 12),

                  AppButton(
                    text: '네이버로 계속하기',
                    icon: Icons.language,
                    isOutlined: true,
                    isLoading: _loadingProvider == 'naver',
                    onPressed: _loadingProvider == null
                        ? () => _signIn('naver')
                        : null,
                  ),
                  const SizedBox(height: 28),

                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '보호자이신가요?',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),

                  const SizedBox(height: 12),

                  OutlinedButton.icon(
                    onPressed: () {
                      context.push(RouteNames.guardianLogin);
                    },
                    icon: const Icon(Icons.family_restroom_outlined),
                    label: const Text('보호자로 로그인'),
                  ),

                  const SizedBox(height: 28),

                  Text(
                    '계속 진행하면 서비스 이용약관 및 개인정보처리방침에 동의한 것으로 간주합니다.',
                    style: AppTextStyles.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  TextButton(onPressed: () {}, child: const Text('자세히 보기')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
