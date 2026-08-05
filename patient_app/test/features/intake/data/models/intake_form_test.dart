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

  test('parses all 15 template questions without changing their order', () {
    final form = IntakeForm.fromJson(_fifteenQuestionFormJson());

    expect(form.questions, hasLength(15));
    expect(
      form.questions.map((question) => question.questionId),
      orderedEquals(_questionIds),
    );
    expect(form.questions.first.answer, isEmpty);
    expect(form.questions[1].answer, isNull);
    expect(form.questions.last.answer, '');

    final serialized = form.content.toJson();
    final questions = serialized['questions']! as List<dynamic>;
    expect(
      questions.map((item) => (item as Map<String, dynamic>)['question_id']),
      orderedEquals(_questionIds),
    );
  });

  test('requires typed empty answers for multiple choice and text', () {
    final multipleJson = _fifteenQuestionFormJson();
    final multipleQuestions =
        (multipleJson['content'] as Map<String, dynamic>)['questions']
            as List<dynamic>;
    (multipleQuestions.first as Map<String, dynamic>)['answer'] = null;
    expect(
      () => IntakeForm.fromJson(multipleJson),
      throwsFormatException,
    );

    final textJson = _fifteenQuestionFormJson();
    final textQuestions =
        (textJson['content'] as Map<String, dynamic>)['questions']
            as List<dynamic>;
    (textQuestions.last as Map<String, dynamic>)['answer'] = null;
    expect(() => IntakeForm.fromJson(textJson), throwsFormatException);
  });
}

const _questionIds = <String>[
  'current_symptoms',
  'symptom_onset',
  'symptom_change',
  'dyspnea_level',
  'hemoptysis',
  'pain_level',
  'pain_description',
  'fever',
  'food_intake',
  'weight_change',
  'medication_adherence',
  'medication_nonadherence_reason',
  'medication_side_effects',
  'daily_activity',
  'questions_for_medical_staff',
];

Map<String, dynamic> _fifteenQuestionFormJson() => <String, dynamic>{
  'id': 'intake-id',
  'content': <String, dynamic>{
    'status': 'draft',
    'questions': List<dynamic>.generate(_questionIds.length, (index) {
      final isFirst = index == 0;
      final isLast = index == _questionIds.length - 1;
      return <String, dynamic>{
        'question_id': _questionIds[index],
        'question_text': '서버 질문 ${index + 1}',
        'question_type': isFirst
            ? 'multiple_choice'
            : isLast
            ? 'text'
            : 'single_choice',
        'options': isLast ? <String>[] : <String>['선택 1', '선택 2'],
        'required': isFirst,
        'answer': isFirst
            ? <String>[]
            : isLast
            ? ''
            : null,
      };
    }),
  },
  'submitted_at': null,
  'updated_at': '2026-08-05T16:10:00+09:00',
};

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
