import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../guardian/data/models/guardian_appointment.dart';
import '../../../guardian/data/models/guardian_medication.dart';
import '../../../guardian/data/models/guardian_patient.dart';
import '../../../guardian/data/models/guardian_result.dart';
import '../../../guardian/presentation/providers/guardian_data_provider.dart';
import '../../../guardian/presentation/widgets/guardian_view_helpers.dart';
import '../providers/auth_provider.dart';

class GuardianHomeScreen extends ConsumerWidget {
  const GuardianHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientsState = ref.watch(guardianPatientsProvider);
    final selectedState = ref.watch(selectedGuardianPatientProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('보호자 홈'),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted) context.go(RouteNames.login);
            },
            child: const Text('로그아웃'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: selectedState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _HomeStateView(
            message: guardianErrorMessage(error),
            onRetry: () => ref.invalidate(guardianPatientsProvider),
          ),
          data: (selectedPatient) {
            if (selectedPatient == null) {
              return const _HomeStateView(message: '연결된 환자가 없습니다.');
            }
            final patients =
                patientsState.asData?.value ?? const <GuardianPatient>[];
            return _GuardianHomeContent(
              patient: selectedPatient,
              patients: patients,
            );
          },
        ),
      ),
    );
  }
}

class _GuardianHomeContent extends ConsumerWidget {
  const _GuardianHomeContent({required this.patient, required this.patients});

  final GuardianPatient patient;
  final List<GuardianPatient> patients;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(guardianResultsProvider(patient.patientId));
    final appointments = ref.watch(
      guardianAppointmentsProvider(patient.patientId),
    );
    final medications = ref.watch(
      guardianMedicationsProvider(patient.patientId),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        Text(
          '연동된 환자',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        if (patients.length > 1)
          DropdownButtonFormField<String>(
            key: const ValueKey('guardian-patient-selector'),
            initialValue: patient.patientId,
            items: patients
                .map(
                  (item) => DropdownMenuItem<String>(
                    value: item.patientId,
                    child: Text(item.patientName),
                  ),
                )
                .toList(growable: false),
            onChanged: (patientId) {
              if (patientId != null) {
                ref
                    .read(guardianSelectedPatientIdProvider.notifier)
                    .select(patientId);
              }
            },
          )
        else
          Text(patient.patientName, style: AppTextStyles.headlineLarge),
        const SizedBox(height: 28),
        _GuardianSummaryCard(
          icon: Icons.science_outlined,
          title: '검사결과',
          value: _resultSummary(results),
          description: '최근 공개된 결과',
          onRetry: results.hasError
              ? () => ref.invalidate(guardianResultsProvider(patient.patientId))
              : null,
          onTap: () => context.push(RouteNames.guardianResults),
        ),
        const SizedBox(height: 14),
        _GuardianSummaryCard(
          icon: Icons.calendar_month_outlined,
          title: '다음 진료 예약',
          value: _appointmentSummary(appointments),
          description: '예약 일시 및 진료과 확인',
          onRetry: appointments.hasError
              ? () => ref.invalidate(
                  guardianAppointmentsProvider(patient.patientId),
                )
              : null,
          onTap: () => context.push(RouteNames.guardianAppointments),
        ),
        const SizedBox(height: 14),
        _GuardianSummaryCard(
          icon: Icons.medication_outlined,
          title: '오늘의 복약 정보',
          value: _medicationSummary(medications),
          description: '약 이름, 용량 및 복용 시간',
          onRetry: medications.hasError
              ? () => ref.invalidate(
                  guardianMedicationsProvider(patient.patientId),
                )
              : null,
          onTap: () => context.push(RouteNames.guardianMedications),
        ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '보호자 화면에서는 환자의 예약, 복약 정보와 공개된 검사결과만 조회할 수 있으며 수정할 수 없습니다.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  static String _resultSummary(AsyncValue<List<GuardianResult>> state) {
    return state.when(
      loading: () => '검사결과를 불러오는 중입니다.',
      error: (_, _) => '검사결과를 불러오지 못했습니다.',
      data: (items) => items.isEmpty ? '등록된 결과가 없습니다.' : '최근 공개 결과가 있습니다.',
    );
  }

  static String _appointmentSummary(
    AsyncValue<List<GuardianAppointment>> state,
  ) {
    return state.when(
      loading: () => '예약 정보를 불러오는 중입니다.',
      error: (_, _) => '예약 정보를 불러오지 못했습니다.',
      data: (items) => items.isEmpty
          ? '예정된 예약이 없습니다.'
          : '${guardianDateTimeLabel(items.first.displaySlot)} 예약',
    );
  }

  static String _medicationSummary(AsyncValue<List<GuardianMedication>> state) {
    return state.when(
      loading: () => '복약 정보를 불러오는 중입니다.',
      error: (_, _) => '복약 정보를 불러오지 못했습니다.',
      data: (items) {
        if (items.isEmpty) return '오늘 등록된 복약 정보가 없습니다.';
        final takenCount = items.where((item) => item.taken).length;
        return '오늘 ${items.length}건 중 $takenCount건 복용 완료';
      },
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
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String value;
  final String description;
  final VoidCallback onTap;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(icon, size: 36, color: AppColors.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.bodySmall),
                  const SizedBox(height: 6),
                  Text(
                    value,
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
                  if (onRetry != null)
                    TextButton(onPressed: onRetry, child: const Text('다시 시도')),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    ),
  );
}

class _HomeStateView extends StatelessWidget {
  const _HomeStateView({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message),
        if (onRetry != null) ...[
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ],
    ),
  );
}
