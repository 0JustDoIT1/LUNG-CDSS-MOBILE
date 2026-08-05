import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/models/intake_form.dart';
import '../providers/intake_form_provider.dart';

class IntakeFormScreen extends ConsumerStatefulWidget {
  const IntakeFormScreen({super.key, required this.onCompleted});

  final VoidCallback onCompleted;

  @override
  ConsumerState<IntakeFormScreen> createState() => _IntakeFormScreenState();
}

class _IntakeFormScreenState extends ConsumerState<IntakeFormScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _isSaving = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _next(IntakeQuestion question, Object? answer, int total) async {
    ref.read(intakeFormProvider.notifier).updateAnswer(question.id, answer);
    if (_currentIndex < total - 1) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
      return;
    }
    await _submit();
  }

  Future<void> _saveDraft(IntakeQuestion question, Object? answer) async {
    if (_isSaving) return;
    ref.read(intakeFormProvider.notifier).updateAnswer(question.id, answer);
    setState(() => _isSaving = true);
    final saved = await ref.read(intakeFormProvider.notifier).saveDraft();
    if (!mounted) return;
    setState(() => _isSaving = false);
    _message(saved ? '임시 저장되었습니다.' : _actionErrorMessage('문진을 저장하지 못했습니다.'));
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    final submitted = await ref.read(intakeFormProvider.notifier).submitForm();
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (!submitted) {
      final error = ref.read(intakeFormProvider.notifier).lastError;
      _message(
        error is FormatException
            ? '필수 문항에 모두 답변해 주세요.'
            : _actionErrorMessage('문진을 제출하지 못했습니다.'),
      );
      return;
    }
    _message('문진이 제출되었습니다.');
    widget.onCompleted();
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String _actionErrorMessage(String fallback) {
    final error = ref.read(intakeFormProvider.notifier).lastError;
    if (error is ApiException) {
      if (error.statusCode == 400) return '문진 내용을 확인해 주세요.';
      if (error.statusCode == 403) return '문진을 조회하거나 수정할 권한이 없습니다.';
      if (error.code == 'TIMEOUT') return '요청 시간이 초과되었습니다.';
      if (error.code == 'CONNECTION_ERROR') return '네트워크 연결을 확인해 주세요.';
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final intakeState = ref.watch(intakeFormProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('진료 전 문진')),
      body: intakeState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('문진표를 불러오지 못했습니다.'),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () =>
                    ref.read(intakeFormProvider.notifier).reloadForm(),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
        data: (form) {
          if (form.questions.isEmpty) {
            return const Center(child: Text('등록된 문진 문항이 없습니다.'));
          }
          return Column(
            children: [
              LinearProgressIndicator(
                value: (_currentIndex + 1) / form.questions.length,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
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
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: form.questions.length,
                  onPageChanged: (index) =>
                      setState(() => _currentIndex = index),
                  itemBuilder: (context, index) {
                    final question = form.questions[index];
                    return _QuestionPage(
                      key: ValueKey(question.id),
                      question: question,
                      isSaving: _isSaving,
                      isLast: index == form.questions.length - 1,
                      onSaveDraft: (answer) => _saveDraft(question, answer),
                      onNext: (answer) =>
                          _next(question, answer, form.questions.length),
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
    super.key,
    required this.question,
    required this.isSaving,
    required this.isLast,
    required this.onSaveDraft,
    required this.onNext,
  });

  final IntakeQuestion question;
  final bool isSaving;
  final bool isLast;
  final ValueChanged<Object?> onSaveDraft;
  final ValueChanged<Object?> onNext;

  @override
  State<_QuestionPage> createState() => _QuestionPageState();
}

class _QuestionPageState extends State<_QuestionPage> {
  late final TextEditingController _textController;
  late List<String> _selectedOptions;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text:
          widget.question.questionType == IntakeQuestionType.text &&
              widget.question.answer is String
          ? widget.question.answer! as String
          : '',
    );
    final answer = widget.question.answer;
    _selectedOptions = answer is List<String>
        ? List<String>.from(answer)
        : answer is String &&
              widget.question.questionType == IntakeQuestionType.singleChoice
        ? <String>[answer]
        : <String>[];
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Object? get _answer => switch (widget.question.questionType) {
    IntakeQuestionType.singleChoice =>
      _selectedOptions.isEmpty ? null : _selectedOptions.first,
    IntakeQuestionType.multipleChoice => List<String>.from(_selectedOptions),
    IntakeQuestionType.text => _textController.text.trim(),
  };

  bool get _hasRequiredAnswer {
    if (!widget.question.required) return true;
    final answer = _answer;
    return answer != null &&
        (answer is! String || answer.trim().isNotEmpty) &&
        (answer is! List<String> || answer.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.question.questionText,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (widget.question.required)
                Text(
                  '필수',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(child: SingleChildScrollView(child: _answerField())),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.isSaving
                      ? null
                      : () => widget.onSaveDraft(_answer),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('임시저장'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: widget.isSaving || !_hasRequiredAnswer
                      ? null
                      : () => widget.onNext(_answer),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: widget.isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(widget.isLast ? '제출' : '다음'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _answerField() {
    switch (widget.question.questionType) {
      case IntakeQuestionType.singleChoice:
        return Column(
          children: widget.question.options
              .map((option) {
                return RadioListTile<String>(
                  value: option,
                  groupValue: _selectedOptions.firstOrNull,
                  title: Text(option),
                  onChanged: (value) => setState(
                    () => _selectedOptions = value == null ? [] : [value],
                  ),
                );
              })
              .toList(growable: false),
        );
      case IntakeQuestionType.multipleChoice:
        return Column(
          children: widget.question.options
              .map((option) {
                return CheckboxListTile(
                  value: _selectedOptions.contains(option),
                  title: Text(option),
                  onChanged: (selected) => setState(() {
                    selected == true
                        ? _selectedOptions.add(option)
                        : _selectedOptions.remove(option);
                  }),
                );
              })
              .toList(growable: false),
        );
      case IntakeQuestionType.text:
        return TextField(
          controller: _textController,
          minLines: 1,
          maxLines: 6,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: '내용을 입력해주세요.',
            border: OutlineInputBorder(),
          ),
        );
    }
  }
}
