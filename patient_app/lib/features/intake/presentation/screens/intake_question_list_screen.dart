import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../data/models/intake_form.dart';
import '../providers/intake_form_provider.dart';

class IntakeQuestionListScreen extends ConsumerWidget {
  const IntakeQuestionListScreen({
    super.key,
    required this.onEdit,
  });

  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intakeState = ref.watch(intakeFormProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('작성 내용 확인'),
      ),
      body: intakeState.when(
        loading: () {
          return const AppLoadingView(
            message: '문진 내용을 불러오는 중입니다.',
          );
        },
        error: (error, stackTrace) {
          return AppErrorView(
            message: '문진 내용을 다시 불러와주세요.',
            onRetry: () {
              ref.invalidate(intakeFormProvider);
            },
          );
        },
        data: (form) {
          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    20,
                    20,
                    12,
                  ),
                  itemCount: form.questions.length,
                  separatorBuilder: (context, index) {
                    return const SizedBox(height: 14);
                  },
                  itemBuilder: (context, index) {
                    final question = form.questions[index];
                    final answer = form.answers[question.id];

                    return _AnswerCard(
                      number: index + 1,
                      question: question,
                      answer: answer,
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    12,
                    20,
                    20,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(
                        Icons.edit_outlined,
                      ),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        child: Text('작성 내용 수정하기'),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AnswerCard extends StatelessWidget {
  const _AnswerCard({
    required this.number,
    required this.question,
    required this.answer,
  });

  final int number;
  final IntakeQuestion question;
  final IntakeAnswer? answer;

  String get _answerText {
    if (answer == null || !answer!.hasAnswer) {
      return '작성하지 않음';
    }

    if (answer!.selectedOptions.isNotEmpty) {
      return answer!.selectedOptions.join(', ');
    }

    return answer!.textAnswer;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '질문 $number',
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            question.title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _answerText,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(
                    color: answer == null || !answer!.hasAnswer
                        ? Colors.grey
                        : Colors.black87,
                    height: 1.5,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}