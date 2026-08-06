import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../guardian/data/models/guardian_medication.dart';
import '../../../guardian/presentation/providers/guardian_data_provider.dart';
import '../../../guardian/presentation/widgets/guardian_view_helpers.dart';

class GuardianMedicationsScreen extends ConsumerWidget {
  const GuardianMedicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPatient = ref.watch(selectedGuardianPatientProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('복약 정보')),
      body: SafeArea(
        child: selectedPatient.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _StateView(
            message: guardianErrorMessage(error),
            onRetry: () => ref.invalidate(guardianPatientsProvider),
          ),
          data: (patient) {
            if (patient == null) {
              return const _StateView(message: '연결된 환자가 없습니다.');
            }
            final medications = ref.watch(
              guardianMedicationsProvider(patient.patientId),
            );
            return medications.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _StateView(
                message: guardianErrorMessage(error),
                onRetry: () => ref.invalidate(
                  guardianMedicationsProvider(patient.patientId),
                ),
              ),
              data: (items) => items.isEmpty
                  ? const _StateView(message: '오늘 등록된 복약 정보가 없습니다.')
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, index) =>
                          _MedicationCard(medication: items[index]),
                    ),
            );
          },
        ),
      ),
    );
  }
}

class _MedicationCard extends StatelessWidget {
  const _MedicationCard({required this.medication});
  final GuardianMedication medication;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.medication_outlined, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                medication.drugName,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text('용량  ${medication.dosage}'),
              const SizedBox(height: 4),
              Text('복용 예정  ${guardianDateTimeLabel(medication.scheduledTime)}'),
              if (medication.takenAt != null) ...[
                const SizedBox(height: 4),
                Text('복용 완료  ${guardianDateTimeLabel(medication.takenAt!)}'),
              ],
            ],
          ),
        ),
        Text(
          medication.taken ? '복용 완료' : '복용 전',
          style: AppTextStyles.bodySmall.copyWith(
            color: medication.taken
                ? AppColors.primaryDark
                : AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _StateView extends StatelessWidget {
  const _StateView({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message, textAlign: TextAlign.center),
        if (onRetry != null) ...[
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ],
    ),
  );
}
