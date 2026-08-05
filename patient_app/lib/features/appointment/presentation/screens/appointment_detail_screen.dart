import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../data/models/appointment.dart';
import '../providers/appointment_provider.dart';

class AppointmentDetailScreen extends ConsumerStatefulWidget {
  const AppointmentDetailScreen({
    required this.appointmentId,
    super.key,
  });

  final String appointmentId;

  @override
  ConsumerState<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState
    extends ConsumerState<AppointmentDetailScreen> {
  final List<String> _availableTimes = [
    '09:00',
    '09:30',
    '10:00',
    '10:30',
    '11:00',
    '11:30',
    '13:00',
    '13:30',
    '14:00',
    '14:30',
    '15:00',
    '15:30',
    '16:00',
    '16:30',
  ];

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

  Future<String?> _selectAppointmentTime(
    String initialTime,
  ) async {
    String selectedTime = _availableTimes.contains(initialTime)
        ? initialTime
        : _availableTimes.first;

    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('예약 시간 선택'),
              content: SizedBox(
                width: double.maxFinite,
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _availableTimes.map((time) {
                    return ChoiceChip(
                      label: Text(time),
                      selected: selectedTime == time,
                      onSelected: (selected) {
                        if (!selected) {
                          return;
                        }

                        setDialogState(() {
                          selectedTime = time;
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('취소'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(
                      selectedTime,
                    );
                  },
                  child: const Text('선택'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _changeAppointmentDate(
    Appointment appointment,
  ) async {
    final now = DateTime.now();
    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final appointmentDate = DateTime(
      appointment.appointmentAt.year,
      appointment.appointmentAt.month,
      appointment.appointmentAt.day,
    );

    final initialDate = appointmentDate.isBefore(today)
        ? today
        : appointmentDate;

    final selectedDate = await showDatePicker(
      context: context,
      locale: const Locale('ko', 'KR'),
      initialDate: initialDate,
      firstDate: today,
      lastDate: DateTime(
        today.year + 1,
        today.month,
        today.day,
      ),
      helpText: '예약 날짜 선택',
      cancelText: '취소',
      confirmText: '선택',
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    final initialHour = appointment.appointmentAt.hour
        .toString()
        .padLeft(2, '0');

    final initialMinute = appointment.appointmentAt.minute
        .toString()
        .padLeft(2, '0');

    final selectedTime = await _selectAppointmentTime(
      '$initialHour:$initialMinute',
    );

    if (selectedTime == null || !mounted) {
      return;
    }

    final timeParts = selectedTime.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    final newAppointmentAt = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      hour,
      minute,
    );

    final success = await ref
        .read(appointmentsProvider.notifier)
        .updateAppointmentDate(
          appointmentId: appointment.id,
          newAppointmentAt: newAppointmentAt,
        );

    if (!mounted) {
      return;
    }

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('예약 변경에 실패했습니다.'),
        ),
      );
      return;
    }

    ref.invalidate(
      appointmentDetailProvider(widget.appointmentId),
    );

    ref.invalidate(
      appointmentsProvider,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('예약 일시가 변경되었습니다.'),
      ),
    );
  }

  Future<void> _cancelAppointment(
    Appointment appointment,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('예약을 취소하시겠습니까?'),
          content: const Text(
            '취소한 예약은 다시 되돌릴 수 없습니다.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('닫기'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('예약 취소'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final success = await ref
        .read(appointmentsProvider.notifier)
        .cancelAppointment(
          appointment.id,
        );

    if (!mounted) {
      return;
    }

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('예약 취소에 실패했습니다.'),
        ),
      );
      return;
    }

    ref.invalidate(
      appointmentDetailProvider(widget.appointmentId),
    );

    ref.invalidate(
      appointmentsProvider,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('예약이 취소되었습니다.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appointmentState = ref.watch(
      appointmentDetailProvider(widget.appointmentId),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('예약 상세'),
      ),
      body: SafeArea(
        child: appointmentState.when(
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stackTrace) => _ErrorView(
            onRetry: () {
              ref.invalidate(
                appointmentDetailProvider(
                  widget.appointmentId,
                ),
              );
            },
          ),
          data: (appointment) {
            if (appointment == null) {
              return const _NotFoundView();
            }

            final statusColor = _statusColor(
              appointment.status,
            );

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                20,
                20,
                20,
                40,
              ),
              children: [
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
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: statusColor.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius:
                                  BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.calendar_month_outlined,
                              color: statusColor,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  appointment.department,
                                  style: AppTextStyles
                                      .headlineMedium,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${appointment.doctorName} 의료진',
                                  style: AppTextStyles
                                      .bodyMedium
                                      .copyWith(
                                    color:
                                        AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius:
                                  BorderRadius.circular(20),
                            ),
                            child: Text(
                              appointment.status.label,
                              style:
                                  AppTextStyles.bodySmall.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _DetailRow(
                        icon: Icons.schedule_outlined,
                        label: '예약 일시',
                        value: _formatDate(
                          appointment.appointmentAt,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _DetailRow(
                        icon: Icons.local_hospital_outlined,
                        label: '병원',
                        value: appointment.hospitalName,
                      ),
                      const SizedBox(height: 18),
                      _DetailRow(
                        icon: Icons.location_on_outlined,
                        label: '진료 장소',
                        value: appointment.location,
                      ),
                      const SizedBox(height: 18),
                      _DetailRow(
                        icon: Icons.description_outlined,
                        label: '진료 목적',
                        value: appointment.purpose,
                      ),
                    ],
                  ),
                ),
                if (appointment.memo != null &&
                    appointment.memo!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(
                        alpha: 0.08,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            appointment.memo!,
                            style:
                                AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (appointment.status ==
                    AppointmentStatus.scheduled) ...[
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            _changeAppointmentDate(
                              appointment,
                            );
                          },
                          child: const Text('예약 변경'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            _cancelAppointment(
                              appointment,
                            );
                          },
                          child: const Text('예약 취소'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 22,
          color: AppColors.primary,
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 76,
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _NotFoundView extends StatelessWidget {
  const _NotFoundView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '예약 정보를 찾을 수 없습니다.',
        style: AppTextStyles.bodyMedium,
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.onRetry,
  });

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 52,
              color: AppColors.danger,
            ),
            const SizedBox(height: 16),
            const Text(
              '예약 상세정보를 불러오지 못했습니다.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}
