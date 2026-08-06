import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/features/guardian/data/models/guardian_result.dart';

void main() {
  test('parses subtype, ordered gene predictions, and released dates', () {
    final result = GuardianResult.fromJson(<String, dynamic>{
      'final_subtype': 'LUAD',
      'gene_predictions': <dynamic>[
        <String, dynamic>{'gene_name': 'EGFR', 'likelihood': 0.64},
        <String, dynamic>{'gene_name': 'TP53', 'likelihood': null},
      ],
      'confirmed_at': '2026-08-06T10:30:00+09:00',
      'released_at': '2026-08-06T10:30:00+09:00',
      'final_note': '화면에 노출하면 안 되는 값',
      'luad_probability': 0.8,
      'lusc_probability': 0.2,
    });

    expect(result.finalSubtype, 'LUAD');
    expect(
      result.genePredictions.map((prediction) => prediction.geneName),
      <String>['EGFR', 'TP53'],
    );
    expect(result.genePredictions.first.likelihood, 0.64);
    expect(result.genePredictions.last.likelihood, isNull);
    expect(result.confirmedAt, isNotNull);
    expect(result.releasedAt, isNotNull);
  });

  test('rejects a string likelihood instead of guessing its value', () {
    expect(
      () => GuardianResult.fromJson(<String, dynamic>{
        'final_subtype': 'LUSC',
        'gene_predictions': <dynamic>[
          <String, dynamic>{'gene_name': 'TP53', 'likelihood': '0.31'},
        ],
        'confirmed_at': null,
        'released_at': null,
      }),
      throwsFormatException,
    );
  });
}
