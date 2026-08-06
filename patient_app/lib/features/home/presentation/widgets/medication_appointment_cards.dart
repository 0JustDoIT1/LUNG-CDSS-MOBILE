import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../data/models/home_summary.dart';

class HomeAppointmentCard extends StatelessWidget {
  const HomeAppointmentCard({required this.summary, super.key});

  final HomeSummary summary;

  @override
  Widget build(BuildContext context) {
    final appointmentDateTime = summary.nextAppointmentDateTime;
    final formattedDate = appointmentDateTime == null
        ? null
        : _formatAppointmentDate(appointmentDateTime);
    final department = summary.nextAppointmentDepartment;
    final doctor = summary.nextAppointmentDoctor;
    final hasAppointment =
        appointmentDateTime != null &&
        department != null &&
        department.trim().isNotEmpty &&
        doctor != null &&
        doctor.trim().isNotEmpty &&
        formattedDate != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('예약', style: AppTextStyles.headlineMedium),
        const SizedBox(height: 14),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => context.go(RouteNames.appointments),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.calendar_month_outlined,
                          color: AppColors.primary,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    '다음 진료 예약',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hasAppointment
                        ? '$department · $doctor 의료진\n$formattedDate'
                        : '예정된 진료 예약이 없습니다.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      hasAppointment && summary.hasUpcomingAppointment
                          ? '예약 예정'
                          : '일정 없음',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  static String _formatAppointmentDate(DateTime dateTime) {
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '${dateTime.year}.$month.$day  $hour:$minute';
  }
}
