import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../data/models/home_summary.dart';

class MedicationAppointmentCards extends StatelessWidget {
  const MedicationAppointmentCards({
    required this.summary,
    super.key,
  });

  final HomeSummary summary;

  String _formatAppointmentDate(DateTime dateTime) {
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '${dateTime.year}.$month.$day  $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final appointmentDateTime = summary.nextAppointmentDateTime;

    final formattedDate = appointmentDateTime == null
        ? null
        : _formatAppointmentDate(appointmentDateTime);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '복약 및 예약',
          style: AppTextStyles.headlineMedium,
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final useColumn = constraints.maxWidth < 560;

            final medicationCard = _MedicationCard(
              summary: summary,
            );

            final appointmentCard = _AppointmentCard(
              summary: summary,
              formattedDate: formattedDate,
            );

            if (useColumn) {
              return Column(
                children: [
                  medicationCard,
                  const SizedBox(height: 14),
                  appointmentCard,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: medicationCard,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: appointmentCard,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _MedicationCard extends StatelessWidget {
  const _MedicationCard({
    required this.summary,
  });

  final HomeSummary summary;

  @override
  Widget build(BuildContext context) {
    final hasMedication = summary.todayMedicationCount > 0;

    return _HomeInfoCard(
      icon: Icons.medication_outlined,
      title: '오늘 복약',
      description: hasMedication
          ? '${summary.completedMedicationCount}/'
              '${summary.todayMedicationCount}회 복약 완료'
          : '등록된 복약 일정이 없습니다.',
      statusText: hasMedication
          ? summary.completedMedicationCount >=
                  summary.todayMedicationCount
              ? '복약완료'
              : '복약 확인'
          : '일정 없음',
      onTap: () {
        context.go(RouteNames.symptoms);
      },
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.summary,
    required this.formattedDate,
  });

  final HomeSummary summary;
  final String? formattedDate;

  @override
  Widget build(BuildContext context) {
    final department = summary.nextAppointmentDepartment;
    final doctor = summary.nextAppointmentDoctor;

    final hasAppointment =
        summary.nextAppointmentDateTime != null &&
        department != null &&
        department.trim().isNotEmpty &&
        doctor != null &&
        doctor.trim().isNotEmpty &&
        formattedDate != null;

    final description = hasAppointment
        ? '$department · $doctor 의료진\n$formattedDate'
        : '예정된 진료 예약이 없습니다.';

    return _HomeInfoCard(
      icon: Icons.calendar_month_outlined,
      title: '다음 진료 예약',
      description: description,
      statusText: hasAppointment &&
              summary.hasUpcomingAppointment
          ? '예약예정'
          : '일정 없음',
      onTap: () {
        context.go(RouteNames.appointments);
      },
    );
  }
}

class _HomeInfoCard extends StatelessWidget {
  const _HomeInfoCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.statusText,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final String statusText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.border,
            ),
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
                  const Spacer(),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
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
                  color: AppColors.primary.withValues(
                    alpha: 0.1,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
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
    );
  }
}