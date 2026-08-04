import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/auth_provider.dart';

class BiometricAuthScreen extends ConsumerStatefulWidget {
  const BiometricAuthScreen({super.key});

  @override
  ConsumerState<BiometricAuthScreen> createState() =>
      _BiometricAuthScreenState();
}

class _BiometricAuthScreenState extends ConsumerState<BiometricAuthScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _authenticate() async {
    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final bool isAuthenticated = await ref
          .read(authProvider.notifier)
          .authenticateWithBiometrics();

      if (!mounted) {
        return;
      }

      if (isAuthenticated) {
        context.go(RouteNames.home);
        return;
      }

      setState(() {
        _errorMessage = '생체인증에 실패했습니다. PIN 번호를 이용해주세요.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = '생체인증을 사용할 수 없습니다.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _openPinLock() {
    context.go(RouteNames.pinLock);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 32,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 380,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(
                        alpha: 0.1,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.fingerprint_rounded,
                      size: 72,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    '생체인증으로 잠금을\n해제해주세요',
                    style: AppTextStyles.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '등록된 지문 또는 얼굴 정보를 이용해\n안전하게 숨잇을 시작할 수 있습니다.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  if (_errorMessage != null) ...[
                    Text(
                      _errorMessage!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.danger,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                  ],
                  AppButton(
                    text: '생체인증 시작',
                    icon: Icons.fingerprint,
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _authenticate,
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    text: 'PIN 번호로 인증',
                    icon: Icons.pin_outlined,
                    isOutlined: true,
                    onPressed: _isLoading ? null : _openPinLock,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '현재 단계에서는 실제 기기 생체인증 대신 '
                    'Mock 인증 결과를 사용합니다.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textDisabled,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}