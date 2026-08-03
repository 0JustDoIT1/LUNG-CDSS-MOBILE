import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../data/models/test_result.dart';
import '../providers/test_result_provider.dart';

class TestResultDetailScreen extends ConsumerWidget {
  const TestResultDetailScreen({
    required this.resultId,
    super.key,
  });

  final String resultId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultState = ref.watch(
      testResultDetailProvider(resultId),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('검사결과 상세'),
      ),
      body: SafeArea(
        child: resultState.when(
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stackTrace) => _ErrorView(
            onRetry: () {
              ref.invalidate(
                testResultDetailProvider(resultId),
              );
            },
          ),
          data: (result) {
            if (result == null) {
              return const _NotFoundView();
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                20,
                20,
                20,
                40,
              ),
              children: [
                _ResultHeader(result: result),
                const SizedBox(height: 24),
                _SubtypeSection(result: result),
                const SizedBox(height: 24),
                _GenePredictionSection(result: result),
                const SizedBox(height: 24),
                _DoctorOpinionSection(result: result),
                const SizedBox(height: 24),
                const _NoticeSection(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ResultHeader extends StatelessWidget {
  const _ResultHeader({
    required this.result,
  });

  final TestResult result;

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.'
        '${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(
                alpha: 0.1,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.biotech_outlined,
              color: AppColors.primary,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.testName,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatDate(result.testDate),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
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
                    result.resultStatus,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubtypeSection extends StatelessWidget {
  const _SubtypeSection({
    required this.result,
  });

  final TestResult result;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: '폐암 아형 분류',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '예측 결과',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            result.cancerSubtype,
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          _ProbabilityRow(
            label: 'LUAD',
            value: result.luadProbability,
          ),
          const SizedBox(height: 16),
          _ProbabilityRow(
            label: 'LUSC',
            value: result.luscProbability,
          ),
        ],
      ),
    );
  }
}

class _GenePredictionSection extends StatelessWidget {
  const _GenePredictionSection({
    required this.result,
  });

  final TestResult result;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: '유전자 변이 가능성',
      child: Column(
        children: result.genePredictions.map((gene) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _ProbabilityRow(
              label: gene.geneName,
              value: gene.probability,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DoctorOpinionSection extends StatelessWidget {
  const _DoctorOpinionSection({
    required this.result,
  });

  final TestResult result;

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

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: '의료진 소견',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result.doctorOpinion,
            style: AppTextStyles.bodyMedium.copyWith(
              height: 1.6,
            ),
          ),
          const SizedBox(height: 18),
          const Divider(
            color: AppColors.border,
          ),
          const SizedBox(height: 12),
          Text(
            '${result.reviewedBy} 의료진',
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatDateTime(result.reviewedAt),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoticeSection extends StatelessWidget {
  const _NoticeSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(
          alpha: 0.08,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'AI 분석 결과와 유전자 변이 가능성은 참고 정보이며, '
              '확진 검사와 담당 의료진의 판단을 대체하지 않습니다.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.headlineMedium,
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _ProbabilityRow extends StatelessWidget {
  const _ProbabilityRow({
    required this.label,
    required this.value,
  });

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final int percent = (value * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '$percent%',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: AppColors.primary.withValues(
              alpha: 0.12,
            ),
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _NotFoundView extends StatelessWidget {
  const _NotFoundView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '검사결과를 찾을 수 없습니다.',
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
              '검사 상세정보를 불러오지 못했습니다.',
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