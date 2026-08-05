import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/features/results/data/models/patient_result.dart';

void main() {
  Map<String, dynamic> validJson() => {
    'case_id': 'case-uuid',
    'specimen_id': 'SPEC-001',
    'final_subtype': 'LUAD',
    'final_note': 'confirmed',
    'luad_probability': 0.81,
    'lusc_probability': 0.19,
    'gene_predictions': [
      {'gene_name': 'TP53', 'likelihood': 0.72},
    ],
    'is_released': true,
    'confirmed_at': '2026-08-05T14:30:00+09:00',
    'released_at': '2026-08-05T14:30:00+09:00',
  };

  group('PatientResult.fromJson', () {
    test('parses the patient result response', () {
      final result = PatientResult.fromJson(validJson());
      expect(result.caseId, 'case-uuid');
      expect(result.specimenId, 'SPEC-001');
      expect(result.finalSubtype, 'LUAD');
      expect(result.luadProbability, 0.81);
      expect(result.luscProbability, 0.19);
      expect(result.genePredictions.single.geneName, 'TP53');
      expect(result.genePredictions.single.likelihood, 0.72);
      expect(result.confirmedAt, isNotNull);
      expect(result.releasedAt, isNotNull);
    });

    test('keeps nullable fields null and accepts an empty gene list', () {
      final json = validJson()
        ..['final_note'] = null
        ..['luad_probability'] = null
        ..['lusc_probability'] = null
        ..['gene_predictions'] = <dynamic>[]
        ..['confirmed_at'] = null
        ..['released_at'] = null;
      final result = PatientResult.fromJson(json);
      expect(result.finalNote, isNull);
      expect(result.luadProbability, isNull);
      expect(result.luscProbability, isNull);
      expect(result.genePredictions, isEmpty);
      expect(result.confirmedAt, isNull);
      expect(result.releasedAt, isNull);
    });

    test('treats a null gene list defensively as empty', () {
      final json = validJson()..['gene_predictions'] = null;
      expect(PatientResult.fromJson(json).genePredictions, isEmpty);
    });

    test('keeps nullable gene likelihood null', () {
      final json = validJson()
        ..['gene_predictions'] = [
          {'gene_name': 'EGFR', 'likelihood': null},
        ];
      expect(
        PatientResult.fromJson(json).genePredictions.single.likelihood,
        isNull,
      );
    });

    test('rejects invalid required types and dates', () {
      expect(
        () => PatientResult.fromJson(validJson()..['case_id'] = 1),
        throwsFormatException,
      );
      expect(
        () => PatientResult.fromJson(validJson()..['confirmed_at'] = 'invalid'),
        throwsFormatException,
      );
    });
  });

  group('patient-facing subtype labels', () {
    test('uses only the confirmed subtype', () {
      expect(patientResultDetailLabel('LUAD'), '폐선암(LUAD)으로 확인되었습니다.');
      expect(patientResultDetailLabel('LUSC'), '편평상피세포암(LUSC)으로 확인되었습니다.');
      expect(patientResultDetailLabel(null), '검사 결과를 확인 중입니다.');
      expect(patientResultDetailLabel('OTHER'), '확정된 검사 결과를 확인해 주세요.');
      expect(patientResultListLabel('LUAD'), '폐선암');
      expect(patientResultListLabel('LUSC'), '편평상피세포암');
    });
  });
}
