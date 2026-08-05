import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../data/models/home_summary.dart';

class TodayHealthSummary extends StatelessWidget {
  const TodayHealthSummary({
    required this.summary,
    required this.onMedicationTap,
    required this.onSymptomTap,
    super.key,
  });

  final HomeSummary summary;
  final VoidCallback onMedicationTap;
  final VoidCallback onSymptomTap;

  @override
  Widget build(BuildContext context) {
    final int medicationPercent =
        (summary.medicationProgress * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '오늘의 건강',
          style: AppTextStyles.headlineMedium,
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.border,
            ),
          ),
          child: Column(
            children: [
              _HealthItem(
                icon: Icons.medication_outlined,
                title: '오늘 복약',
                description:
                    '${summary.completedMedicationCount}'
                    '/${summary.todayMedicationCount}회 완료',
                trailing: '$medicationPercent%',
                onTap: onMedicationTap,
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: summary.medicationProgress,
                  minHeight: 8,
                  backgroundColor:
                      AppColors.primary.withValues(alpha: 0.12),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Divider(
                  height: 1,
                  color: AppColors.border,
                ),
              ),
              _HealthItem(
                icon: Icons.monitor_heart_outlined,
                title: '오늘 증상 기록',
                description: summary.hasSymptomRecordToday
                    ? '오늘의 증상을 기록했습니다.'
                    : '아직 오늘의 증상을 기록하지 않았습니다.',
                trailing: summary.hasSymptomRecordToday
                    ? '작성완료'
                    : '미작성',
                trailingColor: summary.hasSymptomRecordToday
                    ? AppColors.primary
                    : AppColors.textSecondary,
                onTap: onSymptomTap,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HealthItem extends StatelessWidget {
  const _HealthItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.trailing,
    this.trailingColor,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final String trailing;
  final Color? trailingColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              trailing,
              style: AppTextStyles.bodySmall.copyWith(
                color: trailingColor ?? AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}