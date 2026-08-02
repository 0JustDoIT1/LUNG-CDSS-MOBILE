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

class PhoneVerificationScreen extends ConsumerStatefulWidget {
  const PhoneVerificationScreen({super.key});

  @override
  ConsumerState<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState
    extends ConsumerState<PhoneVerificationScreen> {
  final TextEditingController _phoneController = TextEditingController();

  bool _isLoading = false;
  String? _errorText;

  bool get _isValidPhoneNumber {
    final String numbersOnly =
        _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');

    return RegExp(r'^010\d{8}$').hasMatch(numbersOnly);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String _formatPhoneNumber(String value) {
    final String numbersOnly = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (numbersOnly.length <= 3) {
      return numbersOnly;
    }

    if (numbersOnly.length <= 7) {
      return '${numbersOnly.substring(0, 3)}-'
          '${numbersOnly.substring(3)}';
    }

    final int end = numbersOnly.length > 11 ? 11 : numbersOnly.length;

    return '${numbersOnly.substring(0, 3)}-'
        '${numbersOnly.substring(3, 7)}-'
        '${numbersOnly.substring(7, end)}';
  }

  void _handlePhoneChanged(String value) {
    final String formatted = _formatPhoneNumber(value);

    if (formatted != value) {
      _phoneController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(
          offset: formatted.length,
        ),
      );
    }

    setState(() {
      _errorText = null;
    });
  }

  Future<void> _sendVerificationCode() async {
    if (!_isValidPhoneNumber) {
      setState(() {
        _errorText = '올바른 휴대폰번호를 입력해주세요.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      await ref.read(authProvider.notifier).sendVerificationCode(
            phoneNumber: _phoneController.text,
          );

      if (!mounted) {
        return;
      }

      context.push(
        RouteNames.otpVerification,
        extra: _phoneController.text,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorText = '인증번호 발송에 실패했습니다.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
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
                    Icons.phone_iphone_rounded,
                    size: 56,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '본인확인을 위해\n휴대폰 번호를 입력해주세요',
                    style: AppTextStyles.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '입력한 번호로 6자리 인증번호를 보내드립니다.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),
                  AppTextField(
                    controller: _phoneController,
                    label: '휴대폰번호',
                    hintText: '010-0000-0000',
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    prefixIcon: Icons.phone_outlined,
                    errorText: _errorText,
                    onChanged: _handlePhoneChanged,
                    onSubmitted: (_) {
                      if (_isValidPhoneNumber && !_isLoading) {
                        _sendVerificationCode();
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  AppButton(
                    text: '인증번호 받기',
                    isLoading: _isLoading,
                    onPressed: _isValidPhoneNumber && !_isLoading
                        ? _sendVerificationCode
                        : null,
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