import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../app/routes/route_names.dart';
import '../../data/models/patient_appointment.dart';
import '../providers/appointment_provider.dart';

class AppointmentListScreen extends ConsumerWidget {
  const AppointmentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentState = ref.watch(myAppointmentsProvider);
    final cancellingAppointmentIds = ref.watch(appointmentCancelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('예약'),
        actions: [
          TextButton.icon(
            onPressed: () => context.push(RouteNames.appointmentCreate),
            icon: const Icon(Icons.event_available_outlined),
            label: const Text('예약하기'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: appointmentState.when(
          loading: () => const _AppointmentListSkeleton(),
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
                  final appointment = appointments[index];
                  return _AppointmentCard(
                    appointment: appointment,
                    isCancelling: cancellingAppointmentIds.contains(
                      appointment.id,
                    ),
                    onTap: () => context.push(
                      RouteNames.appointmentDetail.replaceFirst(
                        ':appointmentId',
                        Uri.encodeComponent(appointment.id),
                      ),
                    ),
                    onCancel: () =>
                        _confirmAndCancel(context, ref, appointment.id),
                  );
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

  static Future<void> _confirmAndCancel(
    BuildContext context,
    WidgetRef ref,
    String appointmentId,
  ) async {
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

    if (confirmed != true || !context.mounted) {
      return;
    }

    try {
      await ref
          .read(appointmentCancelProvider.notifier)
          .cancelAppointment(appointmentId);
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_cancelErrorMessage(error))));
    }
  }

  static String _cancelErrorMessage(Object error) {
    if (error is ApiException) {
      if (error.statusCode == 401) {
        return '인증 정보가 만료됐거나 유효하지 않습니다.';
      }
      if (error.statusCode == 403) {
        return '예약을 취소할 권한이 없습니다.';
      }
      if (error.statusCode == 404) {
        return '해당 예약을 찾을 수 없습니다.';
      }
      if (error.code == 'TIMEOUT') {
        return '서버 응답 시간이 초과되었습니다.';
      }
      if (error.code == 'CONNECTION_ERROR') {
        return '네트워크 연결을 확인해주세요.';
      }
    }
    return '예약 취소에 실패했습니다.';
  }
}

class _AppointmentListSkeleton extends StatefulWidget {
  const _AppointmentListSkeleton();

  @override
  State<_AppointmentListSkeleton> createState() =>
      _AppointmentListSkeletonState();
}

class _AppointmentListSkeletonState extends State<_AppointmentListSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          children: [
            _AppointmentSkeletonCard(progress: _animation.value),
            const SizedBox(height: 14),
            _AppointmentSkeletonCard(progress: _animation.value),
            const SizedBox(height: 18),
            Text(
              '예약 정보를 불러오는 중입니다.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AppointmentSkeletonCard extends StatelessWidget {
  const _AppointmentSkeletonCard({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 158,
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
              _AppointmentShimmerBone(
                width: 50,
                height: 50,
                borderRadius: 15,
                progress: progress,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FractionallySizedBox(
                      widthFactor: 0.78,
                      alignment: Alignment.centerLeft,
                      child: _AppointmentShimmerBone(
                        width: double.infinity,
                        height: 18,
                        borderRadius: 7,
                        progress: progress,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FractionallySizedBox(
                      widthFactor: 0.58,
                      alignment: Alignment.centerLeft,
                      child: _AppointmentShimmerBone(
                        width: double.infinity,
                        height: 14,
                        borderRadius: 6,
                        progress: progress,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _AppointmentShimmerBone(
                width: 70,
                height: 28,
                borderRadius: 14,
                progress: progress,
              ),
            ],
          ),
          const SizedBox(height: 18),
          _AppointmentShimmerBone(
            width: 154,
            height: 18,
            borderRadius: 7,
            progress: progress,
          ),
          const SizedBox(height: 8),
          _AppointmentShimmerBone(
            width: 72,
            height: 14,
            borderRadius: 6,
            progress: progress,
          ),
        ],
      ),
    );
  }
}

class _AppointmentShimmerBone extends StatelessWidget {
  const _AppointmentShimmerBone({
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.progress,
  });

  final double width;
  final double height;
  final double borderRadius;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final offset = -1.5 + (progress * 3);

    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (bounds) {
        return LinearGradient(
          begin: Alignment(offset - 1, 0),
          end: Alignment(offset + 1, 0),
          colors: const [
            Color(0xFFE7F0F6),
            Color(0xFFF8FCFF),
            Color(0xFFE7F0F6),
          ],
          stops: const [0.25, 0.5, 0.75],
        ).createShader(bounds);
      },
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFE7F0F6),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.appointment,
    required this.isCancelling,
    required this.onTap,
    required this.onCancel,
  });

  final PatientAppointment appointment;
  final bool isCancelling;
  final VoidCallback onTap;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(appointment.status);
    final appointmentAt =
        appointment.confirmedSlot ?? appointment.requestedAtSlot;

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
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
                    child: Icon(
                      Icons.calendar_month_outlined,
                      color: statusColor,
                    ),
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
              if (_canCancel(appointment.status)) ...[
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: isCancelling ? null : onCancel,
                    child: isCancelling
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('예약 취소'),
                  ),
                ),
              ],
            ],
          ),
        ),
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

  static bool _canCancel(String status) {
    switch (status) {
      case 'requested':
      case 'confirmed':
      case 'reminded_d7':
      case 'reminded_d1':
        return true;
      default:
        return false;
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
