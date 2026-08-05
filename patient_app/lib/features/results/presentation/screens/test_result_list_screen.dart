import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../data/models/patient_result_summary.dart';
import '../providers/test_result_provider.dart';

class TestResultListScreen extends ConsumerWidget {
  const TestResultListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultState = ref.watch(testResultsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('검사 결과')),
      body: SafeArea(
        child: resultState.when(
          loading: () => const AppLoadingView(message: '검사 결과를 불러오는 중입니다.'),
          error: (error, stackTrace) => AppErrorView(
            message: _errorMessage(error),
            onRetry: () {
              ref.invalidate(testResultsProvider);
            },
          ),
          data: (results) {
            if (results.isEmpty) {
              return const AppEmptyView(
                icon: Icons.biotech_outlined,
                title: '공개된 검사 결과가 없습니다.',
                description: '의사가 공개한 검사 결과를 이곳에서 확인할 수 있습니다.',
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(testResultsProvider);
                await ref.read(testResultsProvider.future);
              },
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                itemCount: results.length,
                separatorBuilder: (context, index) {
                  return const SizedBox(height: 14);
                },
                itemBuilder: (context, index) {
                  return _PatientResultCard(result: results[index]);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  static String _errorMessage(Object error) {
    if (error is FormatException) {
      return '검사 결과 형식을 확인할 수 없습니다.';
    }

    if (error is ApiException) {
      if (error.statusCode == 401) {
        return '인증 정보가 만료됐거나 유효하지 않습니다.';
      }

      if (error.statusCode == 403) {
        return '검사 결과를 조회할 권한이 없거나 아직 공개되지 않았습니다.';
      }

      if (error.code == 'TIMEOUT') {
        return '서버 응답 시간이 초과되었습니다. 다시 시도해 주세요.';
      }

      if (error.code == 'CONNECTION_ERROR') {
        return '네트워크 연결을 확인한 후 다시 시도해 주세요.';
      }
    }

    return '검사 결과를 불러오지 못했습니다. 다시 시도해 주세요.';
  }
}

class _PatientResultCard extends StatelessWidget {
  const _PatientResultCard({required this.result});

  final PatientResultSummary result;

  String _formatDateTime(DateTime dateTime) {
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '${dateTime.year}.$month.$day $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.biotech_outlined,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (result.specimenId != null) ...[
                  _ResultField(
                    label: '검체 ID',
                    value: result.specimenId!,
                    emphasize: true,
                  ),
                ],
                if (result.finalSubtype != null) ...[
                  if (result.specimenId != null) const SizedBox(height: 12),
                  _ResultField(
                    label: '최종 결과',
                    value: result.finalSubtype!,
                    emphasize: true,
                  ),
                ],
                if (result.finalNote != null) ...[
                  if (result.specimenId != null || result.finalSubtype != null)
                    const SizedBox(height: 12),
                  _ResultField(
                    label: '환자 안내문',
                    value: result.finalNote!,
                    maxLines: 3,
                  ),
                ],
                if (result.confirmedAt != null) ...[
                  const SizedBox(height: 12),
                  _ResultField(
                    label: '확정일',
                    value: _formatDateTime(result.confirmedAt!),
                  ),
                ],
                if (result.releasedAt != null) ...[
                  const SizedBox(height: 8),
                  _ResultField(
                    label: '공개일',
                    value: _formatDateTime(result.releasedAt!),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultField extends StatelessWidget {
  const _ResultField({
    required this.label,
    required this.value,
    this.emphasize = false,
    this.maxLines,
  });

  final String label;
  final String value;
  final bool emphasize;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: maxLines,
          overflow: maxLines == null ? null : TextOverflow.ellipsis,
          style: AppTextStyles.bodyMedium.copyWith(
            color: emphasize ? AppColors.primary : null,
            fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
