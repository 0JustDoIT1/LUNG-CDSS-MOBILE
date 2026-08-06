import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/home_summary.dart';
import '../../../appointment/data/models/patient_appointment.dart';
import '../../../appointment/presentation/providers/appointment_provider.dart';
import '../../../results/data/models/patient_result.dart';
import '../../../results/presentation/providers/test_result_provider.dart';
import '../../../symptom/data/models/medication_log.dart';
import '../../../symptom/data/models/symptom_record.dart';
import '../../../symptom/presentation/providers/symptom_medication_provider.dart';

final homeSummaryProvider = Provider<AsyncValue<HomeSummary>>((ref) {
  final appointmentsState = ref.watch(myAppointmentsProvider);
  final medicationsState = ref.watch(todayMedicationLogsProvider);
  final recordsState = ref.watch(symptomRecordsProvider);
  final resultsState = ref.watch(testResultsProvider);

  final now = DateTime.now();
  final medicationCounts = summarizeTodayMedications(
    medicationsState.asData?.value ?? const <MedicationLog>[],
    now,
  );
  final latestResult = selectLatestReleasedResult(
    resultsState.asData?.value ?? const <PatientResult>[],
  );
  final nextAppointment = selectNextAppointment(
    appointmentsState.asData?.value ?? const <PatientAppointment>[],
    now,
  );

  return AsyncData(
    HomeSummary(
      latestTestTitle: latestResult?.specimenId,
      latestTestDate: latestResult?.displayDate,
      latestTestStatus: latestResult == null
          ? null
          : patientResultListLabel(latestResult.finalSubtype),
      todayMedicationCount: medicationCounts.total,
      completedMedicationCount: medicationCounts.completed,
      hasSymptomRecordToday: hasSymptomRecordToday(
        recordsState.asData?.value ?? const <SymptomRecord>[],
        now,
      ),
      nextAppointmentDepartment: nextAppointment?.department,
      nextAppointmentDoctor: _nonEmptyOrNull(nextAppointment?.doctorName),
      nextAppointmentDateTime: nextAppointment?.displayDateTime,
      unreadNotificationCount: 0,
    ),
  );
});

class MedicationCounts {
  const MedicationCounts({required this.total, required this.completed});

  final int total;
  final int completed;
}

MedicationCounts summarizeTodayMedications(
  List<MedicationLog> logs,
  DateTime now,
) {
  var total = 0;
  var completed = 0;
  for (final log in logs) {
    if (!isSameLocalDate(log.scheduledTime, now)) continue;
    total++;
    if (log.taken) completed++;
  }
  return MedicationCounts(total: total, completed: completed);
}

bool hasSymptomRecordToday(List<SymptomRecord> records, DateTime now) {
  return records.any((record) => isSameLocalDate(record.recordedAt, now));
}

PatientResult? selectLatestReleasedResult(List<PatientResult> results) {
  PatientResult? latest;
  for (final result in results) {
    if (!result.isReleased || result.displayDate == null) continue;
    if (latest == null || result.displayDate!.isAfter(latest.displayDate!)) {
      latest = result;
    }
  }
  return latest;
}

bool isSameLocalDate(DateTime left, DateTime right) {
  final localLeft = left.toLocal();
  final localRight = right.toLocal();
  return localLeft.year == localRight.year &&
      localLeft.month == localRight.month &&
      localLeft.day == localRight.day;
}

PatientAppointment? selectNextAppointment(
  List<PatientAppointment> appointments,
  DateTime now,
) {
  PatientAppointment? next;

  for (final appointment in appointments) {
    if (appointment.status == 'cancelled' ||
        !appointment.displayDateTime.isAfter(now)) {
      continue;
    }
    if (next == null ||
        appointment.displayDateTime.isBefore(next.displayDateTime)) {
      next = appointment;
    }
  }

  return next;
}

String? _nonEmptyOrNull(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

extension on PatientAppointment {
  DateTime get displayDateTime => confirmedSlot ?? requestedAtSlot;
}

extension on PatientResult {
  DateTime? get displayDate => releasedAt ?? confirmedAt;
}
