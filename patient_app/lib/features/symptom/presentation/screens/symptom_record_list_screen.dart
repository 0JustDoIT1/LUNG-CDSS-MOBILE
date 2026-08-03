import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../data/models/symptom_record.dart';
import '../providers/symptom_medication_provider.dart';

class SymptomRecordListScreen extends ConsumerWidget {
  const SymptomRecordListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final symptomState = ref.watch(symptomRecordsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('증상 기록 전체보기'),
      ),
      body: SafeArea(
        child: symptomState.when(
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stackTrace) => _ErrorView(
            onRetry: () {
              ref.invalidate(symptomRecordsProvider);
            },
          ),
          data: (records) {
            if (records.isEmpty) {
              return const _EmptyView();
            }

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(symptomRecordsProvider);
                await ref.read(symptomRecordsProvider.future);
              },
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  40,
                ),
                itemCount: records.length,
                separatorBuilder: (context, index) {
                  return const SizedBox(height: 14);
                },
                itemBuilder: (context, index) {
                  return _SymptomRecordCard(
                    record: records[index],
                  );
                },
              ),
            );
          },
        ),
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
    final symptomNames = record.symptoms
        .map((symptom) => symptom.name)
        .join(', ');

    return Container(
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
                child: Text(
                  symptomNames,
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
          const SizedBox(height: 12),
          Text(
            _formatDateTime(record.recordedAt),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (record.memo.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              record.memo,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
          if (record.symptoms.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: record.symptoms.map((symptom) {
                return Chip(
                  label: Text(
                    '${symptom.name} · '
                    '${_severityText(symptom.severity)}',
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '작성된 증상 기록이 없습니다.',
        style: AppTextStyles.bodyMedium,
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.onRetry,
  });

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 52,
              color: AppColors.danger,
            ),
            const SizedBox(height: 16),
            const Text(
              '증상 기록을 불러오지 못했습니다.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}