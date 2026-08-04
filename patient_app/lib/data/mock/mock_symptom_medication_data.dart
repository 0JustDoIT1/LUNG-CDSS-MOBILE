import '../models/medication_schedule.dart';
import '../models/symptom_record.dart';
class MockSymptomMedicationData {
  const MockSymptomMedicationData._();

  static final List<SymptomRecord> symptomRecords = [
    SymptomRecord(
      id: 'symptom-001',
      recordedAt: DateTime(
        2026,
        8,
        2,
        20,
        30,
      ),
      symptoms: const [
        SymptomItem(
          name: '기침',
          severity: 2,
        ),
        SymptomItem(
          name: '호흡곤란',
          severity: 1,
        ),
        SymptomItem(
          name: '피로',
          severity: 2,
        ),
      ],
      overallSeverity: 2,
      memo: '오후부터 기침이 조금 심해졌습니다.',
    ),
    SymptomRecord(
      id: 'symptom-002',
      recordedAt: DateTime(
        2026,
        8,
        1,
        21,
        10,
      ),
      symptoms: const [
        SymptomItem(
          name: '가슴 통증',
          severity: 1,
        ),
        SymptomItem(
          name: '피로',
          severity: 1,
        ),
      ],
      overallSeverity: 1,
      memo: '가벼운 피로감이 있었습니다.',
    ),
  ];

  static final List<MedicationSchedule> medicationSchedules = [
    MedicationSchedule(
      id: 'medication-001',
      medicationName: '호흡기 치료제 A',
      dosage: '1정',
      instructions: '아침 식후 복용',
      scheduledAt: DateTime(
        2026,
        8,
        3,
        8,
      ),
      isTaken: true,
      takenAt: DateTime(
        2026,
        8,
        3,
        8,
        10,
      ),
    ),
    MedicationSchedule(
      id: 'medication-002',
      medicationName: '호흡기 치료제 B',
      dosage: '1정',
      instructions: '점심 식후 복용',
      scheduledAt: DateTime(
        2026,
        8,
        3,
        13,
      ),
      isTaken: true,
      takenAt: DateTime(
        2026,
        8,
        3,
        13,
        15,
      ),
    ),
    MedicationSchedule(
      id: 'medication-003',
      medicationName: '호흡기 치료제 A',
      dosage: '1정',
      instructions: '저녁 식후 복용',
      scheduledAt: DateTime(
        2026,
        8,
        3,
        19,
      ),
      isTaken: false,
    ),
    MedicationSchedule(
      id: 'medication-004',
      medicationName: '보조 치료제',
      dosage: '1캡슐',
      instructions: '취침 전 복용',
      scheduledAt: DateTime(
        2026,
        8,
        3,
        22,
      ),
      isTaken: false,
    ),
  ];
}