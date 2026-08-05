import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../data/models/patient_result.dart';
import '../providers/test_result_provider.dart';

class TestResultDetailScreen extends ConsumerWidget {
  const TestResultDetailScreen({required this.resultId, super.key});

  final String resultId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultState = ref.watch(testResultDetailProvider(resultId));

    return Scaffold(
      appBar: AppBar(title: const Text('검사 결과')),
      body: SafeArea(
        child: resultState.when(
          loading: () => const _DetailSkeleton(),
          error: (error, stackTrace) => AppErrorView(
            title: _errorTitle(error),
            message: _errorMessage(error),
            onRetry: () => ref.invalidate(testResultDetailProvider(resultId)),
          ),
          data: (result) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            children: [
              _FinalResultCard(result: result),
              const SizedBox(height: 20),
              _BasicInformationCard(result: result),
              const SizedBox(height: 20),
              _GenePredictionCard(predictions: result.genePredictions),
              const SizedBox(height: 20),
              const _NoticeCard(),
            ],
          ),
        ),
      ),
    );
  }

  static String _errorTitle(Object error) {
    if (error is ApiException && error.statusCode == 403) {
      return '검사결과를 조회할 권한이 없습니다.';
    }
    if (error is ApiException && error.statusCode == 404) {
      return '공개된 검사결과를 찾을 수 없습니다.';
    }
    return '검사 결과를 불러오지 못했습니다.';
  }

  static String _errorMessage(Object error) {
    if (error is ApiException) {
      if (error.statusCode == 401) return '인증 정보가 만료됐거나 유효하지 않습니다.';
      if (error.statusCode == 403) return '현재 계정으로 이 검사결과를 확인할 수 없습니다.';
      if (error.statusCode == 404) {
        return '결과가 아직 확정되지 않았거나 공개 상태가 아닐 수 있습니다.';
      }
      if (error.code == 'TIMEOUT') return '서버 응답 시간이 초과되었습니다.';
      if (error.code == 'CONNECTION_ERROR') return '네트워크 연결을 확인해주세요.';
    }
    if (error is FormatException) return '검사 결과 형식을 확인할 수 없습니다.';
    return '잠시 후 다시 시도해주세요.';
  }
}

class _FinalResultCard extends StatelessWidget {
  const _FinalResultCard({required this.result});
  final PatientResult result;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: '최종 검사 결과',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            patientResultDetailLabel(result.finalSubtype),
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.primary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '담당 의료진이 확정한 검사 결과입니다.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BasicInformationCard extends StatelessWidget {
  const _BasicInformationCard({required this.result});
  final PatientResult result;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: '기본 정보',
      child: Column(
        children: [
          _InformationRow(label: '검체번호', value: result.specimenId),
          if (result.confirmedAt != null) ...[
            const SizedBox(height: 14),
            _InformationRow(label: '확정일', value: _format(result.confirmedAt!)),
          ],
          if (result.releasedAt != null) ...[
            const SizedBox(height: 14),
            _InformationRow(label: '공개일', value: _format(result.releasedAt!)),
          ],
        ],
      ),
    );
  }

  String _format(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${value.year}.$month.$day $hour:$minute';
  }
}

class _GenePredictionCard extends StatelessWidget {
  const _GenePredictionCard({required this.predictions});
  final List<GenePrediction> predictions;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: '유전자 변이 확률',
      child: predictions.isEmpty
          ? Text('유전자 예측 정보가 없습니다.', style: AppTextStyles.bodyMedium)
          : Column(
              children: predictions
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.biotech_outlined,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.geneName.trim().isEmpty
                                  ? '유전자 정보 확인 필요'
                                  : item.geneName,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            item.likelihood == null
                                ? '확률 정보 없음'
                                : '${(item.likelihood! * 100).round()}%',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
    );
  }
}

class _InformationRow extends StatelessWidget {
  const _InformationRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 84,
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(child: Text(value, style: AppTextStyles.bodyMedium)),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.headlineMedium),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.primary),
          SizedBox(width: 12),
          Expanded(child: Text('상세한 해석과 치료 계획은 담당 의료진과 상담해 주세요.')),
        ],
      ),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: List.generate(
        3,
        (index) => Container(
          height: index == 0 ? 150 : 190,
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFE7F0F6),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}
