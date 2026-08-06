import 'package:flutter_test/flutter_test.dart';
import 'package:medical_app/core/api/intake_api.dart';

void main() {
  test('parses submitted intake_form from the QR response', () {
    final summary = QrPatientSummary.fromJson(<String, dynamic>{
      'name': 'Patient',
      'patient_number': 'P-1',
      'birth_date': '1990-01-01',
      'intake_form': <String, dynamic>{
        'status': 'submitted',
        'questions': <Map<String, dynamic>>[
          <String, dynamic>{'question_text': 'Question', 'answer': 'Answer'},
        ],
      },
    });

    expect(summary.intakeStatus, 'submitted');
    expect(summary.intakeAnswers.single.questionText, 'Question');
    expect(summary.intakeAnswers.single.answerText, 'Answer');
  });

  test('distinguishes draft and missing intake_form', () {
    final draft = QrPatientSummary.fromJson(<String, dynamic>{
      'name': 'Patient',
      'intake_form': <String, dynamic>{
        'status': 'draft',
        'questions': <dynamic>[],
      },
    });
    final missing = QrPatientSummary.fromJson(<String, dynamic>{
      'name': 'Patient',
      'intake_form': null,
    });

    expect(draft.intakeStatus, 'draft');
    expect(missing.intakeStatus, isNull);
  });
}
