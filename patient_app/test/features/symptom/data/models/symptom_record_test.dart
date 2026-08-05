import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/features/symptom/data/models/symptom_record.dart';

void main() {
  group('SymptomRecord.fromJson', () {
    test('parses all symptom, risk, and review fields', () {
      final record = SymptomRecord.fromJson(_json());

      expect(record.id, 'record-id');
      expect(record.patientName, '홍길동');
      expect(record.checkedAt, DateTime.parse('2026-08-05T15:30:00+09:00'));
      expect(record.symptoms.cough, '약간');
      expect(record.symptoms.dyspnea, '활동시만');
      expect(record.symptoms.hemoptysis, '없음');
      expect(record.symptoms.chestPain, '없음');
      expect(record.symptoms.fever, '없음');
      expect(record.symptoms.weightLoss, '없음');
      expect(record.symptoms.appetite, '평소와 같음');
      expect(record.symptoms.fatigue, '약간');
      expect(record.riskLevel, 'green');
      expect(record.visibleToNurse, isTrue);
      expect(record.nurseReviewed, isFalse);
      expect(record.nurseReviewedAt, isNull);
    });

    for (final risk in ['green', 'yellow', 'red', 'unknown']) {
      test('preserves risk level $risk', () {
        expect(SymptomRecord.fromJson(_json(risk: risk)).riskLevel, risk);
      });
    }

    test('parses a reviewed timestamp', () {
      final record = SymptomRecord.fromJson(
        _json(reviewed: true, reviewedAt: '2026-08-05T16:00:00+09:00'),
      );
      expect(record.nurseReviewed, isTrue);
      expect(
        record.nurseReviewedAt,
        DateTime.parse('2026-08-05T16:00:00+09:00'),
      );
    });

    test('rejects invalid required fields and dates', () {
      expect(
        () => SymptomRecord.fromJson(_json()..['checked_at'] = 'invalid'),
        throwsFormatException,
      );
      expect(
        () => SymptomRecord.fromJson(_json()..['symptoms'] = null),
        throwsFormatException,
      );
    });
  });
}

Map<String, dynamic> _json({
  String risk = 'green',
  bool reviewed = false,
  String? reviewedAt,
}) => <String, dynamic>{
  'id': 'record-id',
  'patient_name': '홍길동',
  'checked_at': '2026-08-05T15:30:00+09:00',
  'symptoms': <String, dynamic>{
    'cough': '약간',
    'dyspnea': '활동시만',
    'hemoptysis': '없음',
    'chest_pain': '없음',
    'fever': '없음',
    'weight_loss': '없음',
    'appetite': '평소와 같음',
    'fatigue': '약간',
  },
  'risk_level': risk,
  'visible_to_nurse': true,
  'nurse_reviewed': reviewed,
  'nurse_reviewed_at': reviewedAt,
};
