import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/features/results/data/models/patient_result_summary.dart';

void main() {
  group('PatientResultSummary.fromJson', () {
    test('parses valid JSON', () {
      final result = PatientResultSummary.fromJson({
        'id': 'case-uuid',
        'specimen_id': 'TCGA-002',
        'final_subtype': 'LUAD',
        'final_note': 'Patient guidance confirmed by a doctor',
        'confirmed_at': '2026-08-04T12:00:00+09:00',
        'released_at': '2026-08-04T12:10:00+09:00',
      });

      expect(result.id, 'case-uuid');
      expect(result.specimenId, 'TCGA-002');
      expect(result.finalSubtype, 'LUAD');
      expect(result.finalNote, 'Patient guidance confirmed by a doctor');
      expect(result.confirmedAt, isNotNull);
      expect(result.releasedAt, isNotNull);
    });

    test('parses nullable fields', () {
      final result = PatientResultSummary.fromJson({
        'id': null,
        'specimen_id': null,
        'final_subtype': null,
        'final_note': null,
        'confirmed_at': null,
        'released_at': null,
      });

      expect(result.id, isNull);
      expect(result.specimenId, isNull);
      expect(result.finalSubtype, isNull);
      expect(result.finalNote, isNull);
      expect(result.confirmedAt, isNull);
      expect(result.releasedAt, isNull);
    });

    test('rejects a non-string value for a string field', () {
      expect(
        () => PatientResultSummary.fromJson({'specimen_id': 123}),
        throwsFormatException,
      );
    });

    test('rejects an invalid date', () {
      expect(
        () => PatientResultSummary.fromJson({'confirmed_at': 'not-a-date'}),
        throwsFormatException,
      );
    });
  });
}
