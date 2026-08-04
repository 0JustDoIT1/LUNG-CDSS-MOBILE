import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/models/hospital.dart';
import '../providers/auth_dependency_providers.dart';
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
  final TextEditingController _birthDateController =
      TextEditingController();

  Hospital? _hospital;
  DateTime? _selectedBirthDate;

  bool _isLoadingHospital = true;
  bool _isRegistering = false;

  String? _phoneErrorText;
  String? _birthDateErrorText;
  String? _hospitalErrorText;

  bool get _isValidPhoneNumber {
    final numbersOnly = _phoneController.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    return RegExp(r'^010\d{8}$').hasMatch(numbersOnly);
  }

  bool get _canRegister {
    return _isValidPhoneNumber &&
        _selectedBirthDate != null &&
        _hospital != null &&
        !_isLoadingHospital &&
        !_isRegistering;
  }

  @override
  void initState() {
    super.initState();

    Future<void>.microtask(_loadHospital);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  Future<void> _loadHospital() async {
    setState(() {
      _isLoadingHospital = true;
      _hospitalErrorText = null;
    });

    try {
      final repository = ref.read(authRepositoryProvider);
      final hospital = await repository.getHospital();

      if (!mounted) {
        return;
      }

      setState(() {
        _hospital = hospital;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _hospitalErrorText = '병원 정보를 불러오지 못했습니다.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingHospital = false;
        });
      }
    }
  }

  String _formatPhoneNumber(String value) {
    final numbersOnly = value.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    if (numbersOnly.length <= 3) {
      return numbersOnly;
    }

    if (numbersOnly.length <= 7) {
      return '${numbersOnly.substring(0, 3)}-'
          '${numbersOnly.substring(3)}';
    }

    final end = numbersOnly.length > 11 ? 11 : numbersOnly.length;

    return '${numbersOnly.substring(0, 3)}-'
        '${numbersOnly.substring(3, 7)}-'
        '${numbersOnly.substring(7, end)}';
  }

  void _handlePhoneChanged(String value) {
    final formatted = _formatPhoneNumber(value);

    if (formatted != value) {
      _phoneController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(
          offset: formatted.length,
        ),
      );
    }

    setState(() {
      _phoneErrorText = null;
    });
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  Future<void> _selectBirthDate() async {
    final now = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ??
          DateTime(
            now.year - 30,
            now.month,
            now.day,
          ),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: '생년월일 선택',
      cancelText: '취소',
      confirmText: '확인',
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() {
      _selectedBirthDate = selectedDate;
      _birthDateController.text = _formatDate(selectedDate);
      _birthDateErrorText = null;
    });
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();

    var hasError = false;

    if (!_isValidPhoneNumber) {
      _phoneErrorText = '올바른 휴대폰번호를 입력해주세요.';
      hasError = true;
    }

    if (_selectedBirthDate == null) {
      _birthDateErrorText = '생년월일을 선택해주세요.';
      hasError = true;
    }

    if (_hospital == null) {
      _hospitalErrorText = '병원 정보를 확인해주세요.';
      hasError = true;
    }

    if (hasError) {
      setState(() {});
      return;
    }

    setState(() {
      _isRegistering = true;
    });

    final isSuccess = await ref
        .read(authProvider.notifier)
        .registerPatient(
          birthDate: _selectedBirthDate!,
          hospitalId: _hospital!.id,
          phoneNumber: _phoneController.text,
        );

    if (!mounted) {
      return;
    }

    setState(() {
      _isRegistering = false;
    });

    if (isSuccess) {
      context.go(RouteNames.home);
      return;
    }

    final authAsync = ref.read(authProvider);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          authAsync.error?.toString() ??
              '회원가입에 실패했습니다. 다시 시도해주세요.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
          ),
          onPressed: () {
            context.go(RouteNames.login);
          },
        ),
      ),
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
                    Icons.person_add_alt_1_rounded,
                    size: 56,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '회원가입에 필요한\n정보를 입력해주세요',
                    style: AppTextStyles.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '휴대폰 인증번호 확인 없이\n입력한 정보로 바로 가입합니다.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),

                  AppTextField(
                    controller: _birthDateController,
                    label: '생년월일',
                    hintText: '생년월일을 선택해주세요',
                    prefixIcon: Icons.calendar_month_outlined,
                    errorText: _birthDateErrorText,
                    readOnly: true,
                    onTap: _selectBirthDate,
                  ),

                  const SizedBox(height: 16),

                  AppTextField(
                    controller: _phoneController,
                    label: '휴대폰번호',
                    hintText: '010-0000-0000',
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    prefixIcon: Icons.phone_outlined,
                    errorText: _phoneErrorText,
                    onChanged: _handlePhoneChanged,
                    onSubmitted: (_) {
                      if (_canRegister) {
                        _register();
                      }
                    },
                  ),

                  const SizedBox(height: 16),

                  _HospitalField(
                    hospital: _hospital,
                    isLoading: _isLoadingHospital,
                    errorText: _hospitalErrorText,
                    onRetry: _loadHospital,
                  ),

                  const SizedBox(height: 24),

                  AppButton(
                    text: '가입하기',
                    isLoading: _isRegistering,
                    onPressed: _canRegister ? _register : null,
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

class _HospitalField extends StatelessWidget {
  const _HospitalField({
    required this.hospital,
    required this.isLoading,
    required this.errorText,
    required this.onRetry,
  });

  final Hospital? hospital;
  final bool isLoading;
  final String? errorText;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const InputDecorator(
        decoration: InputDecoration(
          labelText: '소속병원',
          prefixIcon: Icon(
            Icons.local_hospital_outlined,
          ),
          border: OutlineInputBorder(),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
            SizedBox(width: 12),
            Text('병원 정보를 불러오는 중입니다.'),
          ],
        ),
      );
    }

    if (errorText != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InputDecorator(
            decoration: const InputDecoration(
              labelText: '소속병원',
              prefixIcon: Icon(
                Icons.local_hospital_outlined,
              ),
              border: OutlineInputBorder(),
              errorText: '병원 정보를 불러오지 못했습니다.',
            ),
            child: const Text('병원 정보 없음'),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('다시 불러오기'),
          ),
        ],
      );
    }

    return InputDecorator(
      decoration: const InputDecoration(
        labelText: '소속병원',
        prefixIcon: Icon(
          Icons.local_hospital_outlined,
        ),
        border: OutlineInputBorder(),
      ),
      child: Text(
        hospital?.name ?? '',
      ),
    );
  }
}