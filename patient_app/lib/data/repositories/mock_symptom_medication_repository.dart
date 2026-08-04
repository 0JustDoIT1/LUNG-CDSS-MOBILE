import '../mock/mock_symptom_medication_data.dart';
import '../models/medication_schedule.dart';
import '../models/symptom_record.dart';
import 'symptom_medication_repository.dart';

class MockSymptomMedicationRepository
    implements SymptomMedicationRepository {
  final List<SymptomRecord> _symptomRecords =
      List<SymptomRecord>.from(
    MockSymptomMedicationData.symptomRecords,
  );

  final List<MedicationSchedule> _medicationSchedules =
      List<MedicationSchedule>.from(
    MockSymptomMedicationData.medicationSchedules,
  );

  @override
  Future<List<SymptomRecord>> getSymptomRecords() async {
    await Future<void>.delayed(
      const Duration(milliseconds: 400),
    );

    final records = List<SymptomRecord>.from(
      _symptomRecords,
    );

    records.sort(
      (a, b) => b.recordedAt.compareTo(a.recordedAt),
    );

    return records;
  }

  @override
  Future<void> addSymptomRecord(
    SymptomRecord record,
  ) async {
    await Future<void>.delayed(
      const Duration(milliseconds: 400),
    );

    _symptomRecords.insert(0, record);
  }

  @override
  Future<List<MedicationSchedule>>
      getMedicationSchedules() async {
    await Future<void>.delayed(
      const Duration(milliseconds: 400),
    );

    final schedules = List<MedicationSchedule>.from(
      _medicationSchedules,
    );

    schedules.sort(
      (a, b) => a.scheduledAt.compareTo(b.scheduledAt),
    );

    return schedules;
  }

  @override
  Future<MedicationSchedule> updateMedicationTakenStatus({
    required String medicationId,
    required bool isTaken,
  }) async {
    await Future<void>.delayed(
      const Duration(milliseconds: 300),
    );

    final index = _medicationSchedules.indexWhere(
      (medication) => medication.id == medicationId,
    );

    if (index == -1) {
      throw Exception('복약 일정을 찾을 수 없습니다.');
    }

    final current = _medicationSchedules[index];

    final updated = current.copyWith(
      isTaken: isTaken,
      takenAt: isTaken ? DateTime.now() : null,
      clearTakenAt: !isTaken,
    );

    _medicationSchedules[index] = updated;

    return updated;
  }
}