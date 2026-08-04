import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({
    required this.phoneNumber,
    super.key,
  });

  final String phoneNumber;

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState
    extends ConsumerState<OtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();

  Timer? _timer;
  int _remainingSeconds = 180;
  bool _isLoading = false;
  bool _isResending = false;
  String? _errorText;

  bool get _isExpired => _remainingSeconds <= 0;

  bool get _isValidCode {
    return RegExp(r'^\d{6}$').hasMatch(_otpController.text);
  }

  String get _formattedTime {
    final int minutes = _remainingSeconds ~/ 60;
    final int seconds = _remainingSeconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  String get _maskedPhoneNumber {
    final String numbersOnly =
        widget.phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

    if (numbersOnly.length != 11) {
      return widget.phoneNumber;
    }

    return '${numbersOnly.substring(0, 3)}-****-'
        '${numbersOnly.substring(7)}';
  }

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();

    setState(() {
      _remainingSeconds = 180;
    });

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (_remainingSeconds <= 1) {
          timer.cancel();

          if (mounted) {
            setState(() {
              _remainingSeconds = 0;
            });
          }

          return;
        }

        if (mounted) {
          setState(() {
            _remainingSeconds--;
          });
        }
      },
    );
  }

  Future<void> _verifyCode() async {
    if (_isExpired) {
      setState(() {
        _errorText = '인증번호가 만료되었습니다. 재전송해주세요.';
      });
      return;
    }

    if (!_isValidCode) {
      setState(() {
        _errorText = '6자리 인증번호를 입력해주세요.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final bool isVerified =
        await ref.read(authProvider.notifier).verifyPhoneCode(
              phoneNumber: widget.phoneNumber,
              verificationCode: _otpController.text,
            );

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });

    if (!isVerified) {
      setState(() {
        _errorText = '인증번호가 일치하지 않습니다.';
      });
      return;
    }

    context.go(RouteNames.home);
  }

  Future<void> _resendCode() async {
    if (!_isExpired || _isResending) {
      return;
    }

    setState(() {
      _isResending = true;
      _errorText = null;
      _otpController.clear();
    });

    try {
      await ref.read(authProvider.notifier).sendVerificationCode(
            phoneNumber: widget.phoneNumber,
          );

      if (!mounted) {
        return;
      }

      _startTimer();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('인증번호를 다시 전송했습니다.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorText = '인증번호 재전송에 실패했습니다.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 32,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 420,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.sms_outlined,
                    size: 56,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '인증번호를 입력해주세요',
                    style: AppTextStyles.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$_maskedPhoneNumber로 전송된\n6자리 인증번호를 입력해주세요.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),
                  AppTextField(
                    controller: _otpController,
                    label: '인증번호',
                    hintText: '123456',
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    maxLength: 6,
                    prefixIcon: Icons.lock_outline,
                    errorText: _errorText,
                    onChanged: (_) {
                      setState(() {
                        _errorText = null;
                      });
                    },
                    onSubmitted: (_) {
                      if (_isValidCode && !_isLoading) {
                        _verifyCode();
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _isExpired
                            ? '인증시간이 만료되었습니다.'
                            : '남은 시간 $_formattedTime',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: _isExpired
                              ? AppColors.danger
                              : AppColors.textSecondary,
                        ),
                      ),
                      TextButton(
                        onPressed: _isExpired && !_isResending
                            ? _resendCode
                            : null,
                        child: Text(
                          _isResending ? '재전송 중' : '재전송',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  AppButton(
                    text: '확인',
                    isLoading: _isLoading,
                    onPressed:
                        _isValidCode && !_isLoading && !_isExpired
                            ? _verifyCode
                            : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '테스트 인증번호: 123456',
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