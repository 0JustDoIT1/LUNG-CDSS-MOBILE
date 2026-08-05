import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/features/intake/data/models/intake_form.dart';

void main() {
  test('parses draft questions and nullable answers', () {
    final form = IntakeForm.fromJson(_formJson(status: 'draft'));
    expect(form.content.status, IntakeStatus.draft);
    expect(form.submittedAt, isNull);
    expect(form.questions, hasLength(3));
    expect(form.questions[0].answer, isNull);
    expect(form.questions[1].answer, <String>['기침', '발열']);
    expect(form.questions[2].answer, '메모');
  });

  test('parses submitted dates', () {
    final form = IntakeForm.fromJson(
      _formJson(status: 'submitted', submittedAt: '2026-08-05T16:10:00+09:00'),
    );
    expect(form.content.status, IntakeStatus.submitted);
    expect(form.submittedAt, isNotNull);
    expect(form.updatedAt, DateTime.parse('2026-08-05T16:10:00+09:00'));
  });

  test('supports an empty question array', () {
    final json = _formJson(status: 'draft');
    (json['content'] as Map<String, dynamic>)['questions'] = <dynamic>[];
    expect(IntakeForm.fromJson(json).questions, isEmpty);
  });

  test('rejects unknown status and question type', () {
    expect(
      () => IntakeForm.fromJson(_formJson(status: 'unknown')),
      throwsFormatException,
    );
    final json = _formJson(status: 'draft');
    final questions =
        (json['content'] as Map<String, dynamic>)['questions'] as List<dynamic>;
    (questions.first as Map<String, dynamic>)['question_type'] = 'unknown';
    expect(() => IntakeForm.fromJson(json), throwsFormatException);
  });

  test('rejects answer types that do not match the question type', () {
    final json = _formJson(status: 'draft');
    final questions =
        (json['content'] as Map<String, dynamic>)['questions'] as List<dynamic>;
    (questions.first as Map<String, dynamic>)['answer'] = <String>['비흡연'];
    expect(() => IntakeForm.fromJson(json), throwsFormatException);
  });
}

Map<String, dynamic> _formJson({required String status, String? submittedAt}) =>
    <String, dynamic>{
      'id': 'intake-id',
      'content': <String, dynamic>{
        'status': status,
        'questions': <dynamic>[
          <String, dynamic>{
            'question_id': 'smoking',
            'question_text': '흡연 상태',
            'question_type': 'single_choice',
            'options': <String>['비흡연', '현재 흡연'],
            'required': true,
            'answer': null,
          },
          <String, dynamic>{
            'question_id': 'symptoms',
            'question_text': '증상',
            'question_type': 'multiple_choice',
            'options': <String>['기침', '발열'],
            'required': false,
            'answer': <String>['기침', '발열'],
          },
          <String, dynamic>{
            'question_id': 'memo',
            'question_text': '메모',
            'question_type': 'text',
            'options': <String>[],
            'required': false,
            'answer': '메모',
          },
        ],
      },
      'submitted_at': submittedAt,
      'updated_at': '2026-08-05T16:10:00+09:00',
    };
