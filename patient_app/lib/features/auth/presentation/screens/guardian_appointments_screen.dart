import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../guardian/data/models/guardian_appointment.dart';
import '../../../guardian/presentation/providers/guardian_data_provider.dart';
import '../../../guardian/presentation/widgets/guardian_view_helpers.dart';

class GuardianAppointmentsScreen extends ConsumerWidget {
  const GuardianAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPatient = ref.watch(selectedGuardianPatientProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('진료 예약')),
      body: SafeArea(
        child: selectedPatient.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorView(
            message: guardianErrorMessage(error),
            onRetry: () => ref.invalidate(guardianPatientsProvider),
          ),
          data: (patient) {
            if (patient == null) {
              return const _EmptyView(message: '연결된 환자가 없습니다.');
            }
            final appointments = ref.watch(
              guardianAppointmentsProvider(patient.patientId),
            );
            return appointments.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ErrorView(
                message: guardianErrorMessage(error),
                onRetry: () => ref.invalidate(
                  guardianAppointmentsProvider(patient.patientId),
                ),
              ),
              data: (items) => items.isEmpty
                  ? const _EmptyView(message: '예정된 예약이 없습니다.')
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                      itemCount: items.length + 1,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index == items.length) {
                          return const _ReadOnlyNotice(
                            text:
                                '보호자는 예약 정보를 조회만 할 수 있으며 예약 신청, 변경, 취소는 할 수 없습니다.',
                          );
                        }
                        return _AppointmentCard(appointment: items[index]);
                      },
                    ),
            );
          },
        ),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({required this.appointment});

  final GuardianAppointment appointment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_month_outlined,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  appointment.department,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                guardianAppointmentStatusLabel(appointment.status),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('담당 의료진  ${appointment.doctorName}'),
          const SizedBox(height: 8),
          Text('예약 일시  ${guardianDateTimeLabel(appointment.displaySlot)}'),
          if (appointment.confirmedSlot == null) ...[
            const SizedBox(height: 6),
            Text(
              '확정 전 요청 일시입니다.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Center(child: Text(message));
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: onRetry, child: const Text('다시 시도')),
      ],
    ),
  );
}

class _ReadOnlyNotice extends StatelessWidget {
  const _ReadOnlyNotice({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(text, style: AppTextStyles.bodySmall),
  );
}
