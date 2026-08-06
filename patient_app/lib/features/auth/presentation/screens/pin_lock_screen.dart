import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../convenience/data/notification_deep_link_coordinator.dart';
import '../../../convenience/presentation/providers/notification_deep_link_provider.dart';
import '../../../convenience/presentation/providers/security_settings_provider.dart';
import '../providers/auth_provider.dart';

class PinLockScreen extends ConsumerStatefulWidget {
  const PinLockScreen({super.key, this.onUnlocked});

  final VoidCallback? onUnlocked;

  @override
  ConsumerState<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends ConsumerState<PinLockScreen> {
  String _pin = '';
  bool _isLoading = false;
  String? _errorText;

  Future<void> _verifyPin() async {
    if (_pin.length != 4 || _isLoading) return;
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final valid = await ref
        .read(securitySettingsProvider.notifier)
        .verifyPin(_pin);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!valid) {
      setState(() {
        _pin = '';
        _errorText = 'PIN 번호가 올바르지 않습니다.';
      });
      return;
    }

    if (widget.onUnlocked != null) {
      widget.onUnlocked!();
      return;
    }

    final authState = await ref.read(authProvider.future);
    if (!mounted) return;
    if (!authState.isLoggedIn) {
      context.go(RouteNames.login);
      return;
    }
    if (authState.isNewUser || !authState.isPhoneVerified) {
      context.go(RouteNames.phoneVerification);
      return;
    }
    final homeRoute = RouteNames.homeForRole(authState.role);
    if (homeRoute == null) {
      await ref.read(authProvider.notifier).signOut();
      if (mounted) context.go(RouteNames.login);
      return;
    }
    if (homeRoute == RouteNames.guardianHome) {
      context.go(homeRoute);
      return;
    }
    final result = ref
        .read(notificationDeepLinkCoordinatorProvider)
        .activateAndHandlePending();
    if (result != NotificationNavigationResult.navigated) {
      context.go(homeRoute);
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _errorText = null;
    });
    try {
      final authenticated = await ref
          .read(authProvider.notifier)
          .authenticateWithBiometrics();
      if (!mounted) return;
      if (authenticated) {
        ref.read(securitySettingsProvider.notifier).unlockWithBiometrics();
        widget.onUnlocked?.call();
        return;
      }
      setState(() => _errorText = '생체인증에 실패했습니다. PIN을 입력해주세요.');
    } catch (_) {
      if (mounted) {
        setState(() => _errorText = '생체인증을 사용할 수 없습니다. PIN을 입력해주세요.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _enterNumber(String number) {
    if (_pin.length >= 4 || _isLoading) return;
    setState(() {
      _pin += number;
      _errorText = null;
    });
    if (_pin.length == 4) _verifyPin();
  }

  void _removeNumber() {
    if (_pin.isEmpty || _isLoading) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _errorText = null;
    });
  }

  Widget _pinDot(int index) {
    final filled = index < _pin.length;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? AppColors.primary : Colors.transparent,
        border: Border.all(
          color: filled ? AppColors.primary : AppColors.border,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _numberButton(String number) {
    return SizedBox(
      width: 72,
      height: 72,
      child: OutlinedButton(
        onPressed: _isLoading ? null : () => _enterNumber(number),
        style: OutlinedButton.styleFrom(
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
        ),
        child: Text(number, style: AppTextStyles.headlineMedium),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final biometricEnabled =
        ref.watch(securitySettingsProvider).value?.biometricEnabled == true;
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Column(
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      size: 64,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'PIN 번호를 입력해주세요',
                      style: AppTextStyles.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '앱 잠금을 해제하려면 설정한 4자리 PIN을 입력해주세요.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        4,
                        (index) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: _pinDot(index),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 24,
                      child: _isLoading
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _errorText ?? '',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.danger,
                              ),
                            ),
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 24,
                      runSpacing: 16,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final number in const [
                          '1',
                          '2',
                          '3',
                          '4',
                          '5',
                          '6',
                          '7',
                          '8',
                          '9',
                        ])
                          _numberButton(number),
                        const SizedBox(width: 72, height: 72),
                        _numberButton('0'),
                        SizedBox(
                          width: 72,
                          height: 72,
                          child: IconButton(
                            onPressed: _isLoading ? null : _removeNumber,
                            icon: const Icon(Icons.backspace_outlined),
                          ),
                        ),
                      ],
                    ),
                    if (biometricEnabled) ...[
                      const SizedBox(height: 20),
                      TextButton.icon(
                        onPressed: _isLoading
                            ? null
                            : _authenticateWithBiometrics,
                        icon: const Icon(Icons.fingerprint_rounded),
                        label: const Text('생체인증으로 잠금 해제'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
