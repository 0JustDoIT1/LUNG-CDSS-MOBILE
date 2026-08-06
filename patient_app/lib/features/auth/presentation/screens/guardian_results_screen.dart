import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../guardian/data/models/guardian_result.dart';
import '../../../guardian/presentation/providers/guardian_data_provider.dart';
import '../../../guardian/presentation/widgets/guardian_view_helpers.dart';

class GuardianResultsScreen extends ConsumerWidget {
  const GuardianResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPatient = ref.watch(selectedGuardianPatientProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('검사결과')),
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
            final results = ref.watch(
              guardianResultsProvider(patient.patientId),
            );
            return results.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _StateView(
                message: guardianErrorMessage(error),
                onRetry: () =>
                    ref.invalidate(guardianResultsProvider(patient.patientId)),
              ),
              data: (items) => items.isEmpty
                  ? const _StateView(message: '등록된 결과가 없습니다.')
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, index) =>
                          _ResultCard(result: items[index]),
                    ),
            );
          },
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});
  final GuardianResult result;

  @override
  Widget build(BuildContext context) => Container(
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
            const Icon(Icons.science_outlined, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                guardianSubtypeLabel(result.finalSubtype),
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        if (result.genePredictions.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...result.genePredictions.map(
            (prediction) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.biotech_outlined,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      prediction.geneName,
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                  Text(
                    prediction.likelihood == null
                        ? '정보 없음'
                        : '${(prediction.likelihood! * 100).toStringAsFixed(1)}%',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (result.confirmedAt != null) ...[
          const SizedBox(height: 10),
          Text('확정일  ${guardianDateLabel(result.confirmedAt!)}'),
        ],
        if (result.releasedAt != null) ...[
          const SizedBox(height: 6),
          Text('공개일  ${guardianDateLabel(result.releasedAt!)}'),
        ],
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
