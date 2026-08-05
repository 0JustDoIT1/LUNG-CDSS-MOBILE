import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../data/models/patient_appointment.dart';
import '../providers/appointment_provider.dart';

class AppointmentListScreen extends ConsumerWidget {
  const AppointmentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentState = ref.watch(myAppointmentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('예약')),
      body: SafeArea(
        child: appointmentState.when(
          loading: () => const AppLoadingView(message: '예약 정보를 불러오는 중입니다.'),
          error: (error, stackTrace) => AppErrorView(
            message: _errorMessage(error),
            onRetry: () => ref.invalidate(myAppointmentsProvider),
          ),
          data: (appointments) {
            if (appointments.isEmpty) {
              return const AppEmptyView(
                icon: Icons.calendar_month_outlined,
                title: '예정된 예약이 없습니다.',
                description: '예약이 등록되면 이 화면에서 확인할 수 있습니다.',
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(myAppointmentsProvider);
                await ref.read(myAppointmentsProvider.future);
              },
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                itemCount: appointments.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  return _AppointmentCard(appointment: appointments[index]);
                },
              ),
            );
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
    return '예약 정보를 불러오지 못했습니다.';
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({required this.appointment});

  final PatientAppointment appointment;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(appointment.status);
    final appointmentAt =
        appointment.confirmedSlot ?? appointment.requestedAtSlot;

    return Container(
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
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(Icons.calendar_month_outlined, color: statusColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.department,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      appointment.doctorName,
                      style: AppTextStyles.bodySmall.copyWith(
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
          const SizedBox(height: 18),
          Text(
            _formatDate(appointmentAt),
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            appointment.confirmedSlot == null ? '요청 일시' : '확정 일시',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime dateTime) {
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '${dateTime.year}.$month.$day $hour:$minute';
  }

  static String _statusLabel(String status) {
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

  static Color _statusColor(String status) {
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
