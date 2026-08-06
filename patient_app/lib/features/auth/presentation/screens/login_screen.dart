import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/network/api_exception.dart';
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

                  _SocialLoginButton(
                    key: const Key('google-login-button'),
                    text: 'Google로 계속하기',
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1F1F1F),
                    borderColor: const Color(0xFFDADCE0),
                    icon: Image.asset(
                      'assets/images/google_sign_in_logo.png',
                      width: 24,
                      height: 24,
                    ),
                    isLoading: _loadingProvider == 'google',
                    onPressed: _loadingProvider == null
                        ? () => _signIn('google')
                        : null,
                  ),
                  const SizedBox(height: 12),

                  _SocialLoginButton(
                    key: const Key('kakao-login-button'),
                    text: '카카오로 계속하기',
                    backgroundColor: const Color(0xFFFEE500),
                    foregroundColor: const Color(0xD9000000),
                    icon: SvgPicture.asset(
                      'assets/images/icon_talk_login.svg',
                      package: 'kakao_flutter_sdk_user',
                      width: 22,
                      height: 22,
                    ),
                    isLoading: _loadingProvider == 'kakao',
                    onPressed: _loadingProvider == null
                        ? () => _signIn('kakao')
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

class _SocialLoginButton extends StatelessWidget {
  const _SocialLoginButton({
    required this.text,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.isLoading,
    required this.onPressed,
    this.borderColor,
    super.key,
  });

  final String text;
  final Widget icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor ?? Colors.transparent),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (isLoading)
                SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: foregroundColor,
                  ),
                )
              else ...[
                Positioned(left: 18, child: icon),
                Text(
                  text,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: foregroundColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
