import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/intake_form.dart';
import '../providers/intake_form_provider.dart';

class IntakeFormScreen extends ConsumerStatefulWidget {
  const IntakeFormScreen({
    super.key,
    required this.onCompleted,
  });

  final VoidCallback onCompleted;

  @override
  ConsumerState<IntakeFormScreen> createState() =>
      _IntakeFormScreenState();
}

class _IntakeFormScreenState
    extends ConsumerState<IntakeFormScreen> {
  final PageController _pageController = PageController();

  int _currentIndex = 0;
  bool _isSaving = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _saveAndMoveNext({
    required IntakeQuestion question,
    required IntakeAnswer answer,
    required int totalQuestions,
  }) async {
    setState(() {
      _isSaving = true;
    });

    final saved = await ref
        .read(intakeFormProvider.notifier)
        .saveAnswer(
          questionId: question.id,
          answer: answer,
        );

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (!saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('답변을 저장하지 못했습니다.'),
        ),
      );
      return;
    }

    if (_currentIndex < totalQuestions - 1) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    } else {
      await _submitForm();
    }
  }

  Future<void> _submitForm() async {
    setState(() {
      _isSaving = true;
    });

    final submitted = await ref
        .read(intakeFormProvider.notifier)
        .submitForm();

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (submitted) {
      widget.onCompleted();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('필수 문항을 모두 작성해주세요.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final intakeState = ref.watch(intakeFormProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('진료 전 문진'),
      ),
      body: intakeState.when(
        loading: () {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
        error: (error, stackTrace) {
          return const Center(
            child: Text('문진표를 불러오지 못했습니다.'),
          );
        },
        data: (form) {
          return Column(
            children: [
              LinearProgressIndicator(
                value:
                    (_currentIndex + 1) / form.questions.length,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  8,
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${_currentIndex + 1} / ${form.questions.length}',
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics:
                      const NeverScrollableScrollPhysics(),
                  itemCount: form.questions.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final question = form.questions[index];
                    final answer =
                        form.answers[question.id];

                    return _QuestionPage(
                      question: question,
                      initialAnswer: answer,
                      isSaving: _isSaving,
                      onNext: (newAnswer) {
                        _saveAndMoveNext(
                          question: question,
                          answer: newAnswer,
                          totalQuestions:
                              form.questions.length,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _QuestionPage extends StatefulWidget {
  const _QuestionPage({
    required this.question,
    required this.initialAnswer,
    required this.isSaving,
    required this.onNext,
  });

  final IntakeQuestion question;
  final IntakeAnswer? initialAnswer;
  final bool isSaving;
  final ValueChanged<IntakeAnswer> onNext;

  @override
  State<_QuestionPage> createState() =>
      _QuestionPageState();
}

class _QuestionPageState extends State<_QuestionPage> {
  late final TextEditingController _textController;
  late List<String> _selectedOptions;

  @override
  void initState() {
    super.initState();

    _textController = TextEditingController(
      text: widget.initialAnswer?.textAnswer ?? '',
    );

    _selectedOptions = List<String>.from(
      widget.initialAnswer?.selectedOptions ?? const [],
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  bool get _hasAnswer {
    if (!widget.question.isRequired) {
      return true;
    }

    if (widget.question.type ==
            IntakeQuestionType.shortText ||
        widget.question.type ==
            IntakeQuestionType.longText) {
      return _textController.text.trim().isNotEmpty;
    }

    return _selectedOptions.isNotEmpty;
  }

  void _submitAnswer() {
    final answer = IntakeAnswer(
      questionId: widget.question.id,
      selectedOptions: _selectedOptions,
      textAnswer: _textController.text.trim(),
    );

    widget.onNext(answer);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        16,
        20,
        24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.question.title,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          if (widget.question.description != null) ...[
            const SizedBox(height: 10),
            Text(
              widget.question.description!,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium,
            ),
          ],
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: _buildAnswerField(),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed:
                  widget.isSaving || !_hasAnswer
                      ? null
                      : _submitAnswer,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 14),
                child: widget.isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('다음'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerField() {
    switch (widget.question.type) {
      case IntakeQuestionType.singleChoice:
        return Column(
          children: widget.question.options.map((option) {
            return RadioListTile<String>(
              value: option,
              groupValue: _selectedOptions.isEmpty
                  ? null
                  : _selectedOptions.first,
              title: Text(option),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _selectedOptions = [value];
                });
              },
            );
          }).toList(),
        );

      case IntakeQuestionType.multipleChoice:
        return Column(
          children: widget.question.options.map((option) {
            final selected =
                _selectedOptions.contains(option);

            return CheckboxListTile(
              value: selected,
              title: Text(option),
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedOptions.add(option);
                  } else {
                    _selectedOptions.remove(option);
                  }
                });
              },
            );
          }).toList(),
        );

      case IntakeQuestionType.shortText:
        return TextField(
          controller: _textController,
          onChanged: (_) {
            setState(() {});
          },
          decoration: const InputDecoration(
            hintText: '내용을 입력해주세요.',
            border: OutlineInputBorder(),
          ),
        );

      case IntakeQuestionType.longText:
        return TextField(
          controller: _textController,
          maxLines: 6,
          onChanged: (_) {
            setState(() {});
          },
          decoration: const InputDecoration(
            hintText: '내용을 입력해주세요.',
            border: OutlineInputBorder(),
          ),
        );
    }
  }
}