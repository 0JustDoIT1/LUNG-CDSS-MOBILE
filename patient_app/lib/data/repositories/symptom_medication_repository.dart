import '../models/medication_schedule.dart';
import '../models/symptom_record.dart';

abstract class SymptomMedicationRepository {
  Future<List<SymptomRecord>> getSymptomRecords();

  Future<void> addSymptomRecord(
    SymptomRecord record,
  );

  Future<List<MedicationSchedule>> getMedicationSchedules();

  Future<MedicationSchedule> updateMedicationTakenStatus({
    required String medicationId,
    required bool isTaken,
  });
}