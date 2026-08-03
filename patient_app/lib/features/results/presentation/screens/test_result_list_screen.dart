import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../data/models/test_result.dart';
import '../providers/test_result_provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';


class TestResultListScreen extends ConsumerWidget {
  const TestResultListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultState = ref.watch(testResultsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('검사결과'),
      ),
      body: SafeArea(
        child: resultState.when(

          loading: () => const AppLoadingView(
            message: '검사결과를 불러오는 중입니다.',
          ),
          error: (error, stackTrace) => AppErrorView(
            message: '검사결과를 다시 불러와주세요.',
            onRetry: () {
              ref.invalidate(testResultsProvider);
            },
          ),

          data: (results) {
            if (results.isEmpty) {
              return const AppEmptyView(
                icon: Icons.biotech_outlined,
                title: '등록된 검사결과가 없습니다.',
                description: '검사결과가 등록되면 이곳에서 확인할 수 있습니다.',
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(testResultsProvider);
                await ref.read(testResultsProvider.future);
              },
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  120,
                ),
                itemCount: results.length,
                separatorBuilder: (context, index) {
                  return const SizedBox(height: 14);
                },
                itemBuilder: (context, index) {
                  return _TestResultCard(
                    result: results[index],
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

class _TestResultCard extends StatelessWidget {
  const _TestResultCard({
    required this.result,
  });

  final TestResult result;

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.'
        '${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          context.push(
            RouteNames.resultDetail.replaceFirst(
              ':resultId',
              result.id,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.border,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(
                    alpha: 0.1,
                  ),
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
                    const SizedBox(height: 12),
                    Text(
                      '분류 결과: ${result.cancerSubtype}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}



