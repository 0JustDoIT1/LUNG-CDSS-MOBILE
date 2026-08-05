import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../data/models/patient_result.dart';
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
          loading: () => const _ResultListSkeleton(),
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
                  return _ApiPatientResultCard(result: results[index]);
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
        return '검사결과를 조회할 권한이 없습니다.';
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

class _ResultListSkeleton extends StatefulWidget {
  const _ResultListSkeleton();

  @override
  State<_ResultListSkeleton> createState() => _ResultListSkeletonState();
}

class _ResultListSkeletonState extends State<_ResultListSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          children: [
            _ShimmerBone(
              width: 140,
              height: 22,
              borderRadius: 8,
              progress: _animation.value,
            ),
            const SizedBox(height: 20),
            _ResultSkeletonCard(progress: _animation.value),
            const SizedBox(height: 14),
            _ResultSkeletonCard(progress: _animation.value),
            const SizedBox(height: 18),
            Text(
              '검사 결과를 불러오는 중입니다.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ResultSkeletonCard extends StatelessWidget {
  const _ResultSkeletonCard({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 154,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ShimmerBone(
            width: 52,
            height: 52,
            borderRadius: 16,
            progress: progress,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FractionallySizedBox(
                  widthFactor: 0.9,
                  alignment: Alignment.centerLeft,
                  child: _ShimmerBone(
                    width: double.infinity,
                    height: 18,
                    borderRadius: 7,
                    progress: progress,
                  ),
                ),
                const SizedBox(height: 12),
                FractionallySizedBox(
                  widthFactor: 0.62,
                  alignment: Alignment.centerLeft,
                  child: _ShimmerBone(
                    width: double.infinity,
                    height: 14,
                    borderRadius: 6,
                    progress: progress,
                  ),
                ),
                const Spacer(),
                _ShimmerBone(
                  width: 74,
                  height: 28,
                  borderRadius: 14,
                  progress: progress,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: _ShimmerBone(
              width: 20,
              height: 20,
              borderRadius: 6,
              progress: progress,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerBone extends StatelessWidget {
  const _ShimmerBone({
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.progress,
  });

  final double width;
  final double height;
  final double borderRadius;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final offset = -1.5 + (progress * 3);

    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (bounds) {
        return LinearGradient(
          begin: Alignment(offset - 1, 0),
          end: Alignment(offset + 1, 0),
          colors: const [
            Color(0xFFE7F0F6),
            Color(0xFFF8FCFF),
            Color(0xFFE7F0F6),
          ],
          stops: const [0.25, 0.5, 0.75],
        ).createShader(bounds);
      },
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFE7F0F6),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class _ApiPatientResultCard extends StatelessWidget {
  const _ApiPatientResultCard({required this.result});

  final PatientResult result;

  @override
  Widget build(BuildContext context) {
    final displayDate = result.releasedAt ?? result.confirmedAt;
    final detailPath = RouteNames.resultDetail.replaceFirst(
      ':resultId',
      Uri.encodeComponent(result.caseId),
    );

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(detailPath),
        child: Padding(
          padding: const EdgeInsets.all(20),
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
                    _ResultField(
                      label: '검체번호',
                      value: result.specimenId,
                      emphasize: true,
                    ),
                    const SizedBox(height: 12),
                    _ResultField(
                      label: '최종 결과',
                      value: patientResultListLabel(result.finalSubtype),
                      emphasize: true,
                    ),
                    if (displayDate != null) ...[
                      const SizedBox(height: 12),
                      _ResultField(
                        label: result.releasedAt != null ? '공개일' : '확정일',
                        value: _formatResultDateTime(displayDate),
                      ),
                    ],
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 14),
                child: Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatResultDateTime(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${value.year}.$month.$day $hour:$minute';
  }
}

class _ResultField extends StatelessWidget {
  const _ResultField({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

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
