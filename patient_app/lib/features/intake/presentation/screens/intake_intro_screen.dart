import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/intake_form_provider.dart';

class IntakeIntroScreen extends ConsumerWidget {
  const IntakeIntroScreen({
    super.key,
    required this.onStart,
    required this.onCompleted,
  });

  final VoidCallback onStart;
  final VoidCallback onCompleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intakeState = ref.watch(intakeFormProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('진료 전 문진'),
      ),
      body: SafeArea(
        child: intakeState.when(
          loading: () {
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
          error: (error, stackTrace) {
            return _ErrorView(
              onRetry: () {
                ref
                    .read(intakeFormProvider.notifier)
                    .reloadForm();
              },
            );
          },
          data: (form) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.assignment_outlined,
                      color: Theme.of(context)
                          .colorScheme
                          .primary,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    form.isCompleted
                        ? '문진 작성이 완료되었습니다'
                        : '진료 전 문진을 작성해주세요',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    form.isCompleted
                        ? '작성한 문진 내용은 의료진에게 전달됩니다.'
                        : '진료 전 현재 증상과 복약 상태를 미리 확인합니다.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                  ),
                  const SizedBox(height: 32),
                  const _InfoItem(
                    icon: Icons.schedule_outlined,
                    title: '예상 소요시간',
                    description: '약 3분',
                  ),
                  const SizedBox(height: 16),
                  const _InfoItem(
                    icon: Icons.check_circle_outline,
                    title: '필수 문항 확인',
                    description:
                        '필수 문항을 모두 작성해야 제출할 수 있습니다.',
                  ),
                  const SizedBox(height: 16),
                  const _InfoItem(
                    icon: Icons.medical_information_outlined,
                    title: '의료진에게 전달',
                    description:
                        '작성한 내용은 진료 준비에 활용됩니다.',
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: form.isCompleted
                          ? onCompleted
                          : onStart,
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        child: Text(
                          form.isCompleted
                              ? '작성 내용 확인'
                              : '문진 시작하기',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 24,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
              ),
            ],
          ),
        ),
      ],
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
              Icons.error_outline,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              '문진표를 불러오지 못했습니다.',
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