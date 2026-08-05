import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/models/symptom_record.dart';
import '../../data/models/medication_log.dart';
import '../providers/symptom_medication_provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/route_names.dart';

class SymptomMedicationScreen extends ConsumerWidget {
  const SymptomMedicationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicationState = ref.watch(todayMedicationLogsProvider);
    final processingMedicationIds = ref.watch(medicationTakenProvider);
    final symptomState = ref.watch(symptomRecordsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('증상·복약')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(todayMedicationLogsProvider);
          ref.invalidate(symptomRecordsProvider);

          await Future.wait([
            ref.read(todayMedicationLogsProvider.future),
            ref.read(symptomRecordsProvider.future),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          children: [
            _SectionHeader(
              title: '오늘의 복약',
              actionText: '복약관리',
              onPressed: () {
                context.push(RouteNames.medication);
              },
            ),
            const SizedBox(height: 14),

            medicationState.when(
              loading: () => const _LoadingCard(),
              error: (error, stackTrace) => _ErrorCard(
                message: _medicationErrorMessage(error),
                onRetry: () {
                  ref.invalidate(todayMedicationLogsProvider);
                },
              ),
              data: (medications) {
                if (medications.isEmpty) {
                  return const _EmptyCard(
                    icon: Icons.medication_outlined,
                    message: '오늘 예정된 복약이 없습니다.',
                  );
                }

                return Column(
                  children: medications.map((medication) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _MedicationCard(
                        medication: medication,
                        isProcessing: processingMedicationIds.contains(
                          medication.id,
                        ),
                        onTaken: () =>
                            _markAsTaken(context, ref, medication.id),
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
                message: _symptomErrorMessage(error),
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
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SymptomRecordCard(record: record),
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
                icon: const Icon(Icons.add_rounded),
                label: const Text('새 증상 기록 작성'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _medicationErrorMessage(Object error) {
    if (error is FormatException) {
      return '복약 정보 형식을 확인할 수 없습니다.';
    }

    if (error is ApiException) {
      if (error.statusCode == 401) {
        return '인증 정보가 만료됐거나 유효하지 않습니다.';
      }

      if (error.statusCode == 403) {
        return '복약 정보를 조회할 권한이 없습니다.';
      }

      if (error.code == 'TIMEOUT') {
        return '서버 응답 시간이 초과되었습니다.';
      }

      if (error.code == 'CONNECTION_ERROR') {
        return '네트워크 연결을 확인해주세요.';
      }
    }

    return '복약 정보를 불러오지 못했습니다.';
  }

  static String _symptomErrorMessage(Object error) {
    if (error is FormatException) return '증상 기록 형식을 확인할 수 없습니다.';
    if (error is ApiException) {
      if (error.statusCode == 401) return '인증 정보가 만료됐거나 유효하지 않습니다.';
      if (error.statusCode == 403) return '증상 기록을 조회할 권한이 없습니다.';
      if (error.code == 'TIMEOUT') return '서버 응답 시간이 초과되었습니다.';
      if (error.code == 'CONNECTION_ERROR') return '네트워크 연결을 확인해주세요.';
    }
    return '증상 기록을 불러오지 못했습니다.';
  }

  static Future<void> _markAsTaken(
    BuildContext context,
    WidgetRef ref,
    String logId,
  ) async {
    try {
      await ref.read(medicationTakenProvider.notifier).markAsTaken(logId);
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_markAsTakenErrorMessage(error))));
    }
  }

  static String _markAsTakenErrorMessage(Object error) {
    if (error is FormatException) {
      return '복약 처리 결과 형식을 확인할 수 없습니다.';
    }

    if (error is ApiException) {
      if (error.statusCode == 401) {
        return '인증 정보가 만료됐거나 유효하지 않습니다.';
      }
      if (error.statusCode == 403) {
        return '복약 완료 처리 권한이 없습니다.';
      }
      if (error.statusCode == 404) {
        return '해당 복약 기록을 찾을 수 없습니다.';
      }
      if (error.code == 'TIMEOUT') {
        return '서버 응답 시간이 초과되었습니다.';
      }
      if (error.code == 'CONNECTION_ERROR') {
        return '네트워크 연결을 확인해주세요.';
      }
    }

    return '복약 완료 처리에 실패했습니다.';
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
        Expanded(child: Text(title, style: AppTextStyles.headlineMedium)),
        TextButton(onPressed: onPressed, child: Text(actionText)),
      ],
    );
  }
}

class _MedicationCard extends StatelessWidget {
  const _MedicationCard({
    required this.medication,
    required this.isProcessing,
    required this.onTaken,
  });

  final MedicationLog medication;
  final bool isProcessing;
  final VoidCallback onTaken;

  String _formatTime(DateTime dateTime) {
    final String hour = dateTime.hour.toString().padLeft(2, '0');
    final String minute = dateTime.minute.toString().padLeft(2, '0');

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
          color: medication.taken ? AppColors.primary : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              medication.taken
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
                  medication.drugName,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  medication.dosage,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _formatTime(medication.scheduledTime),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (medication.takenAt != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    '복용 완료 ${_formatTime(medication.takenAt!)}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (isProcessing)
            const SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Checkbox(
              value: medication.taken,
              onChanged: medication.taken
                  ? null
                  : (value) {
                      if (value == true) {
                        onTaken();
                      }
                    },
            ),
        ],
      ),
    );
  }
}

class _SymptomRecordCard extends StatelessWidget {
  const _SymptomRecordCard({required this.record});

  final SymptomRecord record;

  String _formatDateTime(DateTime dateTime) {
    final String month = dateTime.month.toString().padLeft(2, '0');
    final String day = dateTime.day.toString().padLeft(2, '0');
    final String hour = dateTime.hour.toString().padLeft(2, '0');
    final String minute = dateTime.minute.toString().padLeft(2, '0');

    return '${dateTime.year}.$month.$day $hour:$minute';
  }

  ({String label, Color color, Color background}) _riskStyle(String risk) {
    return switch (risk) {
      'green' => (
        label: '낮은 위험',
        color: AppColors.success,
        background: AppColors.successBackground,
      ),
      'yellow' => (
        label: '주의',
        color: AppColors.warning,
        background: AppColors.warningBackground,
      ),
      'red' => (
        label: '위험',
        color: AppColors.danger,
        background: AppColors.dangerBackground,
      ),
      _ => (
        label: '위험도 확인 필요',
        color: AppColors.textSecondary,
        background: AppColors.surfaceSoft,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final risk = _riskStyle(record.riskLevel);
    final symptomNames = _symptomSummary(record.symptoms);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
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
                  color: AppColors.primary.withValues(alpha: 0.1),
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
                      _formatDateTime(record.checkedAt),
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
                  color: risk.background,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  risk.label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: risk.color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            record.nurseReviewed ? '간호사 확인 완료' : '확인 대기',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _symptomSummary(SymptomAnswers symptoms) {
    final entries = <String>[
      if (symptoms.cough != '없음') '기침 ${symptoms.cough}',
      if (symptoms.dyspnea != '없음') '호흡곤란 ${symptoms.dyspnea}',
      if (symptoms.hemoptysis != '없음') '객혈 ${symptoms.hemoptysis}',
      if (symptoms.chestPain != '없음') '흉통 ${symptoms.chestPain}',
      if (symptoms.fever != '없음') '발열 ${symptoms.fever}',
      if (symptoms.weightLoss != '없음') '체중감소 ${symptoms.weightLoss}',
      if (symptoms.appetite != '평소와 같음') '식욕 ${symptoms.appetite}',
      if (symptoms.fatigue != '없음') '피로 ${symptoms.fatigue}',
    ];
    return entries.isEmpty ? '특이 증상 없음' : entries.take(3).join(', ');
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 120,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 42, color: AppColors.textSecondary),
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
  const _ErrorCard({required this.message, required this.onRetry});

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
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.danger,
            size: 42,
          ),
          const SizedBox(height: 12),
          Text(message, style: AppTextStyles.bodyMedium),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}
