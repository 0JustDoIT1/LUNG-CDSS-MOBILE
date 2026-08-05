import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../settings/presentation/providers/guardian_provider.dart';

class GuardianHomeScreen extends ConsumerWidget {
  const GuardianHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guardianState = ref.watch(guardianProvider);

    final linkedGuardian =
        guardianState.linkedGuardians.isNotEmpty
            ? guardianState.linkedGuardians.last
            : null;

    final patientName =
        linkedGuardian?.patientName ?? '연동된 환자';

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('보호자 홈'),
        actions: [
          TextButton(
            onPressed: () {
              context.go(RouteNames.login);
            },
            child: const Text('로그아웃'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            40,
          ),
          children: [
            Text(
              '연동된 환자',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              patientName,
              style: AppTextStyles.headlineLarge,
            ),
            const SizedBox(height: 8),

            Text(
              '환자의 주요 진료 정보를 읽기 전용으로 확인할 수 있습니다.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 28),

            _GuardianSummaryCard(
              icon: Icons.science_outlined,
              title: '검사결과',
              value: '확인 가능한 검사결과가 있습니다.',
              description: '최근 검사결과 상태',
              onTap: () {
                context.push(
                  RouteNames.guardianResults,
                );
              },
            ),
            const SizedBox(height: 14),

            _GuardianSummaryCard(
              icon: Icons.calendar_month_outlined,
              title: '다음 진료 예약',
              value: '예정된 진료 예약이 있습니다.',
              description: '예약 일시 및 진료과 확인',
              onTap: () {
                context.push(
                  RouteNames.guardianAppointments,
                );
              },
            ),
            const SizedBox(height: 14),

            _GuardianSummaryCard(
              icon: Icons.monitor_heart_outlined,
              title: '최근 증상 체크',
              value: '최근 증상 기록을 확인할 수 있습니다.',
              description: '읽기 전용 정보',
              onTap: () {
                context.push(
                  RouteNames.guardianSymptoms,
                );
              },
            ),
            const SizedBox(height: 28),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(
                  alpha: 0.08,
                ),
                borderRadius: BorderRadius.circular(16),
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
                      '보호자 화면에서는 환자 정보를 조회만 할 수 있으며, 예약 변경이나 정보 수정은 할 수 없습니다.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuardianSummaryCard extends StatelessWidget {
  const _GuardianSummaryCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.border,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(
                    alpha: 0.1,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style:
                          AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),

                    Text(
                      value,
                      style:
                          AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),

                    Text(
                      description,
                      style:
                          AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}