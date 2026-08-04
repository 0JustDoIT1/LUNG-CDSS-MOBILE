import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../providers/auth_provider.dart';

class PinLockScreen extends ConsumerStatefulWidget {
  const PinLockScreen({super.key});

  @override
  ConsumerState<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends ConsumerState<PinLockScreen> {
  String _pin = '';
  bool _isLoading = false;
  String? _errorText;

  Future<void> _verifyPin() async {
    if (_pin.length != 4 || _isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final bool isValid = await ref.read(authProvider.notifier).verifyPin(
          pin: _pin,
        );

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });

    if (!isValid) {
      setState(() {
        _pin = '';
        _errorText = 'PIN 번호가 일치하지 않습니다.';
      });
      return;
    }

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

    context.go(RouteNames.home);
  }

  void _enterNumber(String number) {
    if (_pin.length >= 4 || _isLoading) {
      return;
    }

    setState(() {
      _pin += number;
      _errorText = null;
    });

    if (_pin.length == 4) {
      _verifyPin();
    }
  }

  void _removeNumber() {
    if (_pin.isEmpty || _isLoading) {
      return;
    }

    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _errorText = null;
    });
  }

  Widget _buildPinDot(int index) {
    final bool isFilled = index < _pin.length;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isFilled ? AppColors.primary : Colors.transparent,
        border: Border.all(
          color: isFilled ? AppColors.primary : AppColors.border,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _buildNumberButton(String number) {
    return SizedBox(
      width: 72,
      height: 72,
      child: OutlinedButton(
        onPressed: _isLoading ? null : () => _enterNumber(number),
        style: OutlinedButton.styleFrom(
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          number,
          style: AppTextStyles.headlineMedium,
        ),
      ),
    );
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
                maxWidth: 360,
              ),
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
                    '앱 잠금 해제를 위해 4자리 PIN을 입력해주세요.',
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
                        child: _buildPinDot(index),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 24,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
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
                      for (final number in [
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
                        _buildNumberButton(number),
                      const SizedBox(
                        width: 72,
                        height: 72,
                      ),
                      _buildNumberButton('0'),
                      SizedBox(
                        width: 72,
                        height: 72,
                        child: IconButton(
                          onPressed: _isLoading ? null : _removeNumber,
                          icon: const Icon(
                            Icons.backspace_outlined,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '테스트 PIN: 1234',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textDisabled,
                    ),
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