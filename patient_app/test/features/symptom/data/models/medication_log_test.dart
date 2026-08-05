import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/features/symptom/data/models/medication_log.dart';

void main() {
  group('MedicationLog.fromJson', () {
    test('parses valid JSON', () {
      final log = MedicationLog.fromJson({
        'id': 'medication-log-uuid',
        'drug_name': 'Medication',
        'dosage': 'One tablet',
        'scheduled_time': '2026-08-05T09:00:00+09:00',
        'taken': false,
        'taken_at': null,
      });

      expect(log.id, 'medication-log-uuid');
      expect(log.drugName, 'Medication');
      expect(log.dosage, 'One tablet');
      expect(log.scheduledTime, DateTime.parse('2026-08-05T09:00:00+09:00'));
      expect(log.taken, isFalse);
      expect(log.takenAt, isNull);
    });

    test('keeps a null taken_at as null', () {
      final log = MedicationLog.fromJson(_validJson());

      expect(log.takenAt, isNull);
    });

    test('parses a valid taken_at date', () {
      final json = _validJson();
      json['taken_at'] = '2026-08-05T09:05:00+09:00';

      final log = MedicationLog.fromJson(json);

      expect(log.takenAt, DateTime.parse('2026-08-05T09:05:00+09:00'));
    });

    test('rejects an invalid required field type', () {
      final json = _validJson();
      json['taken'] = 'false';

      expect(() => MedicationLog.fromJson(json), throwsFormatException);
    });

    test('rejects an invalid scheduled_time', () {
      final json = _validJson();
      json['scheduled_time'] = 'not-a-date';

      expect(() => MedicationLog.fromJson(json), throwsFormatException);
    });

    test('rejects an invalid taken_at', () {
      final json = _validJson();
      json['taken_at'] = 'not-a-date';

      expect(() => MedicationLog.fromJson(json), throwsFormatException);
    });
  });
}

Map<String, dynamic> _validJson() {
  return <String, dynamic>{
    'id': 'medication-log-uuid',
    'drug_name': 'Medication',
    'dosage': 'One tablet',
    'scheduled_time': '2026-08-05T09:00:00+09:00',
    'taken': false,
    'taken_at': null,
  };
}
