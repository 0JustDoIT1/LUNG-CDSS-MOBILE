import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../data/models/guardian.dart';
import '../../../guardian/presentation/providers/guardian_data_provider.dart';
import '../providers/guardian_provider.dart';

class GuardianLinkScreen extends ConsumerWidget {
  const GuardianLinkScreen({super.key});

  String _formatDate(DateTime dateTime) {
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    return '${dateTime.year}.$month.$day';
  }

  String _inviteErrorMessage(Object error) {
    if (error is ApiException) {
      if (error.statusCode == 401) {
        return '로그인이 만료되었습니다. 다시 로그인해주세요.';
      }
      if (error.statusCode == 403) {
        return '보호자 초대코드를 생성할 환자 권한이 없습니다.';
      }
      if (error.statusCode == 500 || error.statusCode == 503) {
        return '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
      }
      if (error.code == 'TIMEOUT') {
        return '서버 응답 시간이 초과되었습니다.';
      }
      if (error.code == 'CONNECTION_ERROR') {
        return '네트워크 연결을 확인해주세요.';
      }
    }
    if (error is FormatException) {
      return '보호자 초대코드 형식을 확인할 수 없습니다.';
    }
    return '보호자 초대코드를 불러오지 못했습니다.';
  }

  Future<void> _createNewCode(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('새 코드를 생성하시겠습니까?'),
        content: const Text('기존에 발급된 미사용 코드는 더 이상 사용할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('새 코드 생성'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await ref.read(guardianInviteProvider.notifier).createNewInvite();
    if (!context.mounted) return;
    if (!ref.read(guardianInviteProvider).hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('새 보호자 초대코드가 생성되었습니다.')),
      );
    }
  }

  Future<void> _unlinkGuardian(
    BuildContext context,
    WidgetRef ref,
    Guardian guardian,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('보호자 연동을 해제하시겠습니까?'),
        content: Text('${guardian.name} 보호자는 더 이상 환자 정보를 확인할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('연동 해제'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    ref.read(guardianProvider.notifier).unlinkGuardian(guardian.id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('보호자 연동을 해제했습니다.')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invite = ref.watch(guardianInviteProvider);
    final linkedGuardians = ref.watch(guardianProvider).linkedGuardians;

    return Scaffold(
      appBar: AppBar(title: const Text('보호자 연동')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            Text(
              '보호자 초대코드',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: invite.when(
                loading: () => const SizedBox(
                  height: 112,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => SizedBox(
                  height: 112,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _inviteErrorMessage(error),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        key: const ValueKey('guardian-invite-retry-button'),
                        onPressed: () => ref.invalidate(guardianInviteProvider),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('다시 시도'),
                      ),
                    ],
                  ),
                ),
                data: (value) => Column(
                  children: [
                    Text(
                      value.inviteCode,
                      key: const ValueKey('guardian-invite-code'),
                      style: AppTextStyles.displayLarge.copyWith(
                        letterSpacing: 6,
                        color: AppColors.primaryDark,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${_formatDate(value.invitedAt.toLocal())} 발급',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      key: const ValueKey('guardian-invite-create-button'),
                      onPressed: () => _createNewCode(context, ref),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('새 코드 생성'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '초대코드를 보호자에게 전달해주세요. 보호자는 이 코드와 본인 이름을 입력해 연동할 수 있습니다.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text('등록된 보호자', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 12),
            if (linkedGuardians.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 32,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.person_add_alt_1_outlined,
                      size: 42,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '등록된 보호자가 없습니다.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...linkedGuardians.map(
                (guardian) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_outline_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                guardian.name,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_formatDate(guardian.linkedAt)} 연동',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              _unlinkGuardian(context, ref, guardian),
                          child: const Text('해제'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
