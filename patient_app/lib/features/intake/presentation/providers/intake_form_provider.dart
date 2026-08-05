import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_dependency_providers.dart';
import '../../data/intake_api.dart';
import '../../data/intake_repository.dart';
import '../../data/models/intake_form.dart';

final intakeApiProvider = Provider<IntakeApi>((ref) {
  return IntakeApi(ref.watch(apiClientProvider));
});

final intakeRepositoryProvider = Provider<IntakeRepository>((ref) {
  return IntakeRepository(ref.watch(intakeApiProvider));
});

final intakeFormProvider =
    AsyncNotifierProvider<IntakeFormNotifier, IntakeForm>(
      IntakeFormNotifier.new,
    );

class IntakeFormNotifier extends AsyncNotifier<IntakeForm> {
  bool _isMutating = false;
  Object? _lastError;

  Object? get lastError => _lastError;

  @override
  Future<IntakeForm> build() {
    return ref.read(intakeRepositoryProvider).fetchMyIntake();
  }

  bool updateAnswer(String questionId, Object? answer) {
    final form = state.asData?.value;
    if (form == null) return false;
    final questions = form.questions
        .map((question) {
          if (question.questionId != questionId) return question;
          return question.copyWith(answer: answer, clearAnswer: answer == null);
        })
        .toList(growable: false);
    state = AsyncData(form.copyWithQuestions(questions));
    return true;
  }

  Future<bool> saveDraft() => _save(IntakeStatus.draft);

  Future<bool> submitForm() async {
    final form = state.asData?.value;
    if (form == null || !_isValidForSubmission(form.questions)) {
      _lastError = const FormatException('필수 문항 미응답');
      return false;
    }
    return _save(IntakeStatus.submitted);
  }

  Future<bool> _save(IntakeStatus status) async {
    if (_isMutating) return false;
    final current = state.asData?.value;
    if (current == null) return false;
    _isMutating = true;
    _lastError = null;
    try {
      final saved = await ref
          .read(intakeRepositoryProvider)
          .saveMyIntake(
            IntakeContent(status: status, questions: current.questions),
          );
      state = AsyncData(saved);
      return true;
    } catch (error) {
      _lastError = error;
      return false;
    } finally {
      _isMutating = false;
    }
  }

  Future<void> reloadForm() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(intakeRepositoryProvider).fetchMyIntake(),
    );
  }

  static bool _isValidForSubmission(List<IntakeQuestion> questions) {
    for (final question in questions) {
      final answer = question.answer;
      if (question.required) {
        if (answer == null ||
            (answer is String && answer.trim().isEmpty) ||
            (answer is List<String> && answer.isEmpty)) {
          return false;
        }
      }
      if (answer == null) continue;
      switch (question.questionType) {
        case IntakeQuestionType.singleChoice:
          if (answer is! String || !question.options.contains(answer)) {
            return false;
          }
        case IntakeQuestionType.multipleChoice:
          if (answer is! List<String> ||
              answer.any((value) => !question.options.contains(value))) {
            return false;
          }
        case IntakeQuestionType.text:
          if (answer is! String) return false;
      }
    }
    return true;
  }
}
