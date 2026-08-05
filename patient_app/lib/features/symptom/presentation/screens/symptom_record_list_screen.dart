import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../data/models/symptom_record.dart';
import '../providers/symptom_medication_provider.dart';

class SymptomRecordListScreen extends ConsumerWidget {
  const SymptomRecordListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final symptomState = ref.watch(symptomRecordsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('증상 기록 전체보기')),
      body: SafeArea(
        child: symptomState.when(
          loading: () => const AppLoadingView(message: '증상 기록을 불러오는 중입니다.'),
          error: (error, stackTrace) => AppErrorView(
            message: _symptomErrorMessage(error),
            onRetry: () {
              ref.invalidate(symptomRecordsProvider);
            },
          ),
          data: (records) {
            if (records.isEmpty) {
              return const AppEmptyView(
                icon: Icons.monitor_heart_outlined,
                title: '작성된 증상 기록이 없습니다.',
                description: '아직 기록된 증상이 없습니다.',
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(symptomRecordsProvider);
                await ref.read(symptomRecordsProvider.future);
              },
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                itemCount: records.length,
                separatorBuilder: (context, index) {
                  return const SizedBox(height: 14);
                },
                itemBuilder: (context, index) {
                  return _SymptomRecordCard(record: records[index]);
                },
              ),
            );
          },
        ),
      ),
    );
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
    final symptomSummary = _symptomSummary(record.symptoms);

    return Container(
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
                child: Text(
                  symptomSummary,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
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
          const SizedBox(height: 12),
          Text(
            _formatDateTime(record.checkedAt),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
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
