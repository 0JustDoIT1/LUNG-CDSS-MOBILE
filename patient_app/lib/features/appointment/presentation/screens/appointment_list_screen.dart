import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../data/models/appointment.dart';
import '../providers/appointment_provider.dart';

class AppointmentListScreen extends ConsumerWidget {
  const AppointmentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentState = ref.watch(appointmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('예약'),
      ),
      body: SafeArea(
        child: appointmentState.when(
          loading: () => const AppLoadingView(
            message: '예약 정보를 불러오는 중입니다.',
          ),
          error: (error, stackTrace) => AppErrorView(
            message: '예약 정보를 다시 불러와주세요.',
            onRetry: () {
              ref.invalidate(appointmentsProvider);
            },
          ),
          data: (appointments) {
            if (appointments.isEmpty) {
              return AppEmptyView(
                icon: Icons.calendar_month_outlined,
                title: '등록된 예약이 없습니다.',
                description: '새로운 진료 예약을 신청해보세요.',
                buttonText: '새 예약 신청',
                onPressed: () {
                  context.push(RouteNames.appointmentCreate);
                },
              );
            }

            final scheduledAppointments = appointments
                .where(
                  (appointment) =>
                      appointment.status ==
                      AppointmentStatus.scheduled,
                )
                .toList();

            final pastAppointments = appointments
                .where(
                  (appointment) =>
                      appointment.status !=
                      AppointmentStatus.scheduled,
                )
                .toList();

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(appointmentsProvider);
                await ref.read(appointmentsProvider.future);
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  120,
                ),
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        context.push(
                          RouteNames.appointmentCreate,
                        );
                      },
                      icon: const Icon(
                        Icons.add_rounded,
                      ),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        child: Text('새 예약 신청'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '예정된 예약',
                    style: AppTextStyles.headlineMedium,
                  ),
                  const SizedBox(height: 14),
                  if (scheduledAppointments.isEmpty)
                    const _EmptySectionCard(
                      message: '예정된 예약이 없습니다.',
                    )
                  else
                    ...scheduledAppointments.map(
                      (appointment) => Padding(
                        padding: const EdgeInsets.only(
                          bottom: 14,
                        ),
                        child: _AppointmentCard(
                          appointment: appointment,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  const Text(
                    '지난 예약',
                    style: AppTextStyles.headlineMedium,
                  ),
                  const SizedBox(height: 14),
                  if (pastAppointments.isEmpty)
                    const _EmptySectionCard(
                      message: '지난 예약이 없습니다.',
                    )
                  else
                    ...pastAppointments.map(
                      (appointment) => Padding(
                        padding: const EdgeInsets.only(
                          bottom: 14,
                        ),
                        child: _AppointmentCard(
                          appointment: appointment,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.appointment,
  });

  final Appointment appointment;

  String _formatDate(DateTime dateTime) {
    final String month =
        dateTime.month.toString().padLeft(2, '0');
    final String day =
        dateTime.day.toString().padLeft(2, '0');
    final String hour =
        dateTime.hour.toString().padLeft(2, '0');
    final String minute =
        dateTime.minute.toString().padLeft(2, '0');

    return '${dateTime.year}.$month.$day $hour:$minute';
  }

  Color _statusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.scheduled:
        return AppColors.primary;
      case AppointmentStatus.completed:
        return AppColors.textSecondary;
      case AppointmentStatus.cancelled:
        return AppColors.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(
      appointment.status,
    );

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          context.push(
            RouteNames.appointmentDetail.replaceFirst(
              ':appointmentId',
              appointment.id,
            ),
          );
        },
        child: Container(
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
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(
                        alpha: 0.1,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      Icons.calendar_month_outlined,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.department,
                          style:
                              AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${appointment.doctorName} 의료진',
                          style:
                              AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(
                        alpha: 0.1,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      appointment.status.label,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                _formatDate(
                  appointment.appointmentAt,
                ),
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                appointment.purpose,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      appointment.location,
                      style:
                          AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptySectionCard extends StatelessWidget {
  const _EmptySectionCard({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 28,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        message,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}