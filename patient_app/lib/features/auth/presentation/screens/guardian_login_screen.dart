import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/route_names.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../../../guardian/presentation/guardian_auth_error_message.dart';

class GuardianLoginScreen extends ConsumerStatefulWidget {
  const GuardianLoginScreen({super.key});

  @override
  ConsumerState<GuardianLoginScreen> createState() =>
      _GuardianLoginScreenState();
}

class _GuardianLoginScreenState extends ConsumerState<GuardianLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final code = _codeController.text.trim().toUpperCase();
    final name = _nameController.text.trim();

    final success = await ref
        .read(authProvider.notifier)
        .registerGuardian(inviteCode: code, name: name);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (!success) {
      final error = ref.read(authProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(guardianRegistrationErrorMessage(error))),
      );
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('보호자 연동이 완료되었습니다.')));

    context.go(RouteNames.guardianHome);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('보호자 로그인')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.family_restroom_rounded,
                        size: 38,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '보호자 등록코드를\n입력해주세요',
                      style: AppTextStyles.headlineLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '환자에게서 전달받은 6자리 코드로\n보호자 연동을 진행합니다.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    Text(
                      '등록코드',
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _codeController,
                      maxLength: 6,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        hintText: '예: 3F9K2A',
                        counterText: '',
                      ),
                      validator: (value) {
                        final code = value?.trim() ?? '';

                        if (code.isEmpty) {
                          return '등록코드를 입력해주세요.';
                        }

                        if (code.length != 6) {
                          return '6자리 등록코드를 입력해주세요.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    Text(
                      '보호자 이름',
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(hintText: '이름을 입력해주세요'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '보호자 이름을 입력해주세요.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    AppButton(
                      text: '등록하기',
                      isLoading: _isLoading,
                      onPressed: _isLoading ? null : _submit,
                    ),
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
