import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/models/patient_appointment.dart';
import '../providers/appointment_provider.dart';

class AppointmentDetailScreen extends ConsumerWidget {
  const AppointmentDetailScreen({required this.appointmentId, super.key});

  final String appointmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentState = ref.watch(
      appointmentDetailProvider(appointmentId),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('예약 상세')),
      body: SafeArea(
        child: appointmentState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => _ErrorView(
            message: _errorMessage(error),
            onRetry: () => ref.invalidate(myAppointmentsProvider),
          ),
          data: (appointment) {
            if (appointment == null) {
              return const _NotFoundView();
            }
            return _AppointmentDetails(appointment: appointment);
          },
        ),
      ),
    );
  }

  static String _errorMessage(Object error) {
    if (error is FormatException) {
      return '예약 정보 형식을 확인할 수 없습니다.';
    }
    if (error is ApiException) {
      if (error.statusCode == 401) {
        return '인증 정보가 만료됐거나 유효하지 않습니다.';
      }
      if (error.statusCode == 403) {
        return '예약 정보를 조회할 권한이 없습니다.';
      }
      if (error.code == 'TIMEOUT') {
        return '서버 응답 시간이 초과되었습니다.';
      }
      if (error.code == 'CONNECTION_ERROR') {
        return '네트워크 연결을 확인해주세요.';
      }
    }
    return '예약 상세정보를 불러오지 못했습니다.';
  }
}

class _AppointmentDetails extends ConsumerWidget {
  const _AppointmentDetails({required this.appointment});

  final PatientAppointment appointment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = _statusColor(appointment.status);
    final appointmentAt =
        appointment.confirmedSlot ?? appointment.requestedAtSlot;
    final isCancelling = ref.watch(
      appointmentCancelProvider.select((ids) => ids.contains(appointment.id)),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.department,
                          style: AppTextStyles.headlineMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          appointment.doctorName,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(
                    label: _statusLabel(appointment.status),
                    color: statusColor,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _DetailRow(
                icon: Icons.schedule_outlined,
                label: appointment.confirmedSlot == null ? '요청 일시' : '확정 일시',
                value: _formatDate(appointmentAt),
              ),
              const SizedBox(height: 18),
              _DetailRow(
                icon: Icons.person_outline_rounded,
                label: '담당 의사',
                value: appointment.doctorName,
              ),
              const SizedBox(height: 18),
              _DetailRow(
                icon: Icons.event_note_outlined,
                label: '신청 일시',
                value: _formatDate(appointment.createdAt),
              ),
            ],
          ),
        ),
        if (_canCancel(appointment.status)) ...[
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isCancelling
                  ? null
                  : () => _confirmAndCancel(context, ref),
              child: isCancelling
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('예약 취소'),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _confirmAndCancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('예약을 취소하시겠습니까?'),
        content: const Text('취소한 예약은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('아니요'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('예약 취소'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref
          .read(appointmentCancelProvider.notifier)
          .cancelAppointment(appointment.id);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('예약 취소에 실패했습니다.')));
    }
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
        Icon(icon, size: 22, color: AppColors.primary),
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _NotFoundView extends StatelessWidget {
  const _NotFoundView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('예약 정보를 찾을 수 없습니다.', style: AppTextStyles.bodyMedium),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
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
            Text(message, style: AppTextStyles.bodyMedium),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime dateTime) {
  final month = dateTime.month.toString().padLeft(2, '0');
  final day = dateTime.day.toString().padLeft(2, '0');
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '${dateTime.year}.$month.$day $hour:$minute';
}

String _statusLabel(String status) {
  switch (status) {
    case 'requested':
      return '예약 요청';
    case 'confirmed':
    case 'reminded_d7':
    case 'reminded_d1':
      return '예약 확정';
    case 'checked_in':
      return '접수 완료';
    case 'completed':
      return '진료 완료';
    case 'cancelled':
      return '예약 취소';
    case 'no_show':
      return '미방문';
    default:
      return '상태 확인 필요';
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'cancelled':
    case 'no_show':
      return AppColors.danger;
    case 'completed':
      return AppColors.textSecondary;
    default:
      return AppColors.primary;
  }
}

bool _canCancel(String status) {
  return status == 'requested' ||
      status == 'confirmed' ||
      status == 'reminded_d7' ||
      status == 'reminded_d1';
}
