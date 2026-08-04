import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../data/models/medication_schedule.dart';
import '../../../../data/models/symptom_record.dart';
import '../providers/symptom_medication_provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/route_names.dart';



class SymptomMedicationScreen extends ConsumerWidget {
  const SymptomMedicationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicationState = ref.watch(
      medicationSchedulesProvider,
    );
    final symptomState = ref.watch(
      symptomRecordsProvider,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('증상·복약'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(medicationSchedulesProvider);
          ref.invalidate(symptomRecordsProvider);

          await Future.wait([
            ref.read(medicationSchedulesProvider.future),
            ref.read(symptomRecordsProvider.future),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            120,
          ),
          children: [
            _SectionHeader(
              title: '오늘의 복약',
              actionText: '복약관리',
              onPressed: () {},
            ),
            const SizedBox(height: 14),

            medicationState.when(
              loading: () => const _LoadingCard(),
              error: (error, stackTrace) => _ErrorCard(
                message: '복약 일정을 불러오지 못했습니다.',
                onRetry: () {
                  ref.invalidate(
                    medicationSchedulesProvider,
                  );
                },
              ),
              data: (medications) {
                if (medications.isEmpty) {
                  return const _EmptyCard(
                    icon: Icons.medication_outlined,
                    message: '등록된 복약 일정이 없습니다.',
                  );
                }

                return Column(
                  children: medications.map((medication) {
                    return Padding(
                      padding: const EdgeInsets.only(
                        bottom: 12,
                      ),
                      child: _MedicationCard(
                        medication: medication,
                        onChanged: (isTaken) async {
                          await ref
                              .read(
                                medicationSchedulesProvider
                                    .notifier,
                              )
                              .updateTakenStatus(
                                medicationId: medication.id,
                                isTaken: isTaken,
                              );
                        },
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 24),

            _SectionHeader(
              title: '최근 증상 기록',
              actionText: '전체보기',
              onPressed: () {
                context.push(RouteNames.symptomRecordList);
              },
            ),
            const SizedBox(height: 14),

            symptomState.when(
              loading: () => const _LoadingCard(),
              error: (error, stackTrace) => _ErrorCard(
                message: '증상 기록을 불러오지 못했습니다.',
                onRetry: () {
                  ref.invalidate(symptomRecordsProvider);
                },
              ),
              data: (records) {
                if (records.isEmpty) {
                  return const _EmptyCard(
                    icon: Icons.monitor_heart_outlined,
                    message: '작성된 증상 기록이 없습니다.',
                  );
                }

                return Column(
                  children: records.take(3).map((record) {
                    return Padding(
                      padding: const EdgeInsets.only(
                        bottom: 12,
                      ),
                      child: _SymptomRecordCard(
                        record: record,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  context.push(RouteNames.symptomRecordForm);
                },
                icon: const Icon(
                  Icons.add_rounded,
                ),
                label: const Text('새 증상 기록 작성'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionText,
    required this.onPressed,
  });

  final String title;
  final String actionText;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.headlineMedium,
          ),
        ),
        TextButton(
          onPressed: onPressed,
          child: Text(actionText),
        ),
      ],
    );
  }
}

class _MedicationCard extends StatelessWidget {
  const _MedicationCard({
    required this.medication,
    required this.onChanged,
  });

  final MedicationSchedule medication;
  final ValueChanged<bool> onChanged;

  String _formatTime(DateTime dateTime) {
    final String hour =
        dateTime.hour.toString().padLeft(2, '0');
    final String minute =
        dateTime.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: medication.isTaken
              ? AppColors.primary
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(
                alpha: 0.1,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              medication.isTaken
                  ? Icons.check_rounded
                  : Icons.medication_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medication.medicationName,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${medication.dosage} · '
                  '${medication.instructions}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _formatTime(medication.scheduledAt),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Checkbox(
            value: medication.isTaken,
            onChanged: (value) {
              if (value != null) {
                onChanged(value);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _SymptomRecordCard extends StatelessWidget {
  const _SymptomRecordCard({
    required this.record,
  });

  final SymptomRecord record;

  String _formatDateTime(DateTime dateTime) {
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

  String _severityText(int severity) {
    switch (severity) {
      case 1:
        return '경미';
      case 2:
        return '보통';
      case 3:
        return '심함';
      default:
        return '없음';
    }
  }

  @override
  Widget build(BuildContext context) {
    final String symptomNames = record.symptoms
        .map((symptom) => symptom.name)
        .join(', ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
                child: const Icon(
                  Icons.monitor_heart_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      symptomNames,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _formatDateTime(record.recordedAt),
                      style: AppTextStyles.bodySmall.copyWith(
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
                  color: AppColors.primary.withValues(
                    alpha: 0.1,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _severityText(record.overallSeverity),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (record.memo.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              record.memo,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 120,
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 32,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 42,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.danger,
            size: 42,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}