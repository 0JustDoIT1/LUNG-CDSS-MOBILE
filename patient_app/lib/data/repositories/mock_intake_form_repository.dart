import '../mock/mock_intake_form_data.dart';
import '../models/intake_form.dart';
import 'intake_form_repository.dart';

class MockIntakeFormRepository
    implements IntakeFormRepository {
  IntakeForm _form = MockIntakeFormData.form;

  @override
  Future<IntakeForm> getIntakeForm() async {
    await Future<void>.delayed(
      const Duration(milliseconds: 400),
    );

    return _form;
  }

  @override
  Future<IntakeForm> saveAnswer({
    required String questionId,
    required IntakeAnswer answer,
  }) async {
    await Future<void>.delayed(
      const Duration(milliseconds: 250),
    );

    final updatedAnswers =
        Map<String, IntakeAnswer>.from(
      _form.answers,
    );

    updatedAnswers[questionId] = answer;

    _form = _form.copyWith(
      answers: updatedAnswers,
      isCompleted: false,
    );

    return _form;
  }

  @override
  Future<IntakeForm> submitIntakeForm() async {
    await Future<void>.delayed(
      const Duration(milliseconds: 500),
    );

    for (final question in _form.questions) {
      if (!question.isRequired) {
        continue;
      }

      final answer = _form.answers[question.id];

      if (answer == null || !answer.hasAnswer) {
        throw Exception(
          '필수 문항에 답변하지 않았습니다.',
        );
      }
    }

    _form = _form.copyWith(
      isCompleted: true,
      completedAt: DateTime.now(),
    );

    return _form;
  }
}