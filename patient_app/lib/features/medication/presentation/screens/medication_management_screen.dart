import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../symptom/data/models/medication_log.dart';
import '../../../symptom/presentation/providers/symptom_medication_provider.dart';

class MedicationManagementScreen extends ConsumerStatefulWidget {
  const MedicationManagementScreen({super.key});

  @override
  ConsumerState<MedicationManagementScreen> createState() =>
      _MedicationManagementScreenState();
}

class _MedicationManagementScreenState
    extends ConsumerState<MedicationManagementScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() {
      if (mounted) {
        ref.invalidate(todayMedicationLogsProvider);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final medicationState = ref.watch(todayMedicationLogsProvider);
    final processingMedicationIds = ref.watch(medicationTakenProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('복약관리')),
      body: SafeArea(
        child: medicationState.when(
          loading: () => const AppLoadingView(message: '오늘의 복약 정보를 불러오는 중입니다.'),
          error: (error, stackTrace) => AppErrorView(
            title: '복약 정보를 불러오지 못했습니다.',
            message: _medicationErrorMessage(error),
            onRetry: () {
              ref.invalidate(todayMedicationLogsProvider);
            },
          ),
          data: (medications) {
            if (medications.isEmpty) {
              return const AppEmptyView(
                icon: Icons.medication_outlined,
                title: '오늘 예정된 복약이 없습니다.',
                description: '오늘의 복약 일정이 등록되면 이곳에서 확인할 수 있습니다.',
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(todayMedicationLogsProvider);
                await ref.read(todayMedicationLogsProvider.future);
              },
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                itemCount: medications.length + 1,
                separatorBuilder: (context, index) {
                  return const SizedBox(height: 14);
                },
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '오늘의 복약',
                        style: AppTextStyles.headlineMedium,
                      ),
                    );
                  }

                  final medication = medications[index - 1];
                  return _MedicationManagementCard(
                    medication: medication,
                    isProcessing: processingMedicationIds.contains(
                      medication.id,
                    ),
                    onTaken: () => _markAsTaken(context, ref, medication.id),
                  );
                },
              ),
            );
          },
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

class _MedicationManagementCard extends StatelessWidget {
  const _MedicationManagementCard({
    required this.medication,
    required this.isProcessing,
    required this.onTaken,
  });

  final MedicationLog medication;
  final bool isProcessing;
  final VoidCallback onTaken;

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
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
