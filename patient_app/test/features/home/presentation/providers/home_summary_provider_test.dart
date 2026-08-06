import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/features/appointment/data/models/patient_appointment.dart';
import 'package:patient_app/features/appointment/presentation/providers/appointment_provider.dart';
import 'package:patient_app/features/home/presentation/providers/home_summary_provider.dart';
import 'package:patient_app/features/results/data/models/patient_result.dart';
import 'package:patient_app/features/results/presentation/providers/test_result_provider.dart';
import 'package:patient_app/features/symptom/data/models/medication_log.dart';
import 'package:patient_app/features/symptom/data/models/symptom_record.dart';
import 'package:patient_app/features/symptom/presentation/providers/symptom_medication_provider.dart';

void main() {
  final now = DateTime(2026, 8, 6, 12);

  group('today medication summary', () {
    test('counts four schedules and two completed schedules as 50 percent', () {
      final counts = summarizeTodayMedications(<MedicationLog>[
        _medication(DateTime(2026, 8, 6, 8), taken: true),
        _medication(DateTime(2026, 8, 6, 12), taken: true),
        _medication(DateTime(2026, 8, 6, 18)),
        _medication(DateTime(2026, 8, 6, 22)),
      ], now);

      expect(counts.total, 4);
      expect(counts.completed, 2);
      expect(counts.completed / counts.total, 0.5);
    });

    test('returns zero counts for no schedules', () {
      final counts = summarizeTodayMedications(const <MedicationLog>[], now);
      expect(counts.total, 0);
      expect(counts.completed, 0);
    });

    test('excludes past and future dates', () {
      final counts = summarizeTodayMedications(<MedicationLog>[
        _medication(DateTime(2026, 8, 5, 22), taken: true),
        _medication(DateTime(2026, 8, 6, 8)),
        _medication(DateTime(2026, 8, 7, 8), taken: true),
      ], now);
      expect(counts.total, 1);
      expect(counts.completed, 0);
    });

    test('counts separate times for the same drug independently', () {
      final counts = summarizeTodayMedications(<MedicationLog>[
        _medication(DateTime(2026, 8, 6, 8), id: 'morning'),
        _medication(DateTime(2026, 8, 6, 20), id: 'evening'),
      ], now);
      expect(counts.total, 2);
    });
  });

  group('today symptom summary', () {
    test('is complete when a local-date record exists', () {
      expect(
        hasSymptomRecordToday(<SymptomRecord>[
          _symptom(DateTime(2026, 8, 6, 9)),
        ], now),
        isTrue,
      );
    });

    test('needs a record when only past records exist', () {
      expect(
        hasSymptomRecordToday(<SymptomRecord>[
          _symptom(DateTime(2026, 8, 5, 23, 59)),
        ], now),
        isFalse,
      );
    });
  });

  group('latest patient result', () {
    test('selects the most recently released result', () {
      final latest = selectLatestReleasedResult(<PatientResult>[
        _result('old', releasedAt: DateTime(2026, 8, 4)),
        _result('latest', releasedAt: DateTime(2026, 8, 6)),
      ]);
      expect(latest?.specimenId, 'latest');
    });

    test('excludes unreleased results', () {
      final latest = selectLatestReleasedResult(<PatientResult>[
        _result('private', releasedAt: DateTime(2026, 8, 7), isReleased: false),
        _result('public', releasedAt: DateTime(2026, 8, 6)),
      ]);
      expect(latest?.specimenId, 'public');
    });

    test(
      'falls back to confirmedAt and returns null without dated results',
      () {
        final confirmed = _result(
          'confirmed',
          confirmedAt: DateTime(2026, 8, 6),
        );
        expect(
          selectLatestReleasedResult(<PatientResult>[confirmed]),
          confirmed,
        );
        expect(selectLatestReleasedResult(const <PatientResult>[]), isNull);
      },
    );
  });

  group('combined home provider', () {
    test('maps real provider values into HomeSummary', () async {
      final container = _container(
        medications: (ref) async => <MedicationLog>[
          _medication(DateTime.now(), taken: true),
        ],
        symptoms: (ref) async => <SymptomRecord>[_symptom(DateTime.now())],
        results: (ref) async => <PatientResult>[
          _result('SPEC-1', releasedAt: DateTime(2026, 8, 6)),
        ],
        appointments: (ref) async => <PatientAppointment>[
          _appointment(DateTime(2099, 1, 1, 9)),
        ],
      );
      addTearDown(container.dispose);

      await Future.wait([
        container.read(todayMedicationLogsProvider.future),
        container.read(symptomRecordsProvider.future),
        container.read(testResultsProvider.future),
        container.read(myAppointmentsProvider.future),
      ]);
      container.invalidate(homeSummaryProvider);
      final summary = container.read(homeSummaryProvider).requireValue;

      expect(summary.todayMedicationCount, 1);
      expect(summary.completedMedicationCount, 1);
      expect(summary.hasSymptomRecordToday, isTrue);
      expect(summary.latestTestTitle, 'SPEC-1');
      expect(summary.nextAppointmentDateTime, DateTime(2099, 1, 1, 9));
    });

    test('keeps independent empty values while dependencies load', () async {
      final pendingMedications = Completer<List<MedicationLog>>();
      final pendingSymptoms = Completer<List<SymptomRecord>>();
      final pendingResults = Completer<List<PatientResult>>();
      final pendingAppointments = Completer<List<PatientAppointment>>();
      final container = _container(
        medications: (ref) => pendingMedications.future,
        symptoms: (ref) => pendingSymptoms.future,
        results: (ref) => pendingResults.future,
        appointments: (ref) => pendingAppointments.future,
      );
      addTearDown(container.dispose);

      final summary = container.read(homeSummaryProvider).requireValue;
      expect(summary.todayMedicationCount, 0);
      expect(summary.hasSymptomRecordToday, isFalse);
      expect(summary.latestTestTitle, isNull);
      expect(summary.nextAppointmentDateTime, isNull);
    });

    test('keeps independent empty values when dependencies fail', () async {
      Future<List<T>> fail<T>(Ref ref) async => throw StateError('failed');
      final container = _container(
        medications: fail,
        symptoms: fail,
        results: fail,
        appointments: fail,
      );
      addTearDown(container.dispose);

      final summary = container.read(homeSummaryProvider).requireValue;
      expect(summary.todayMedicationCount, 0);
      expect(summary.hasSymptomRecordToday, isFalse);
      expect(summary.latestTestTitle, isNull);
      expect(summary.nextAppointmentDateTime, isNull);
    });
  });

  group('next appointment selection', () {
    test('keeps the existing confirmed-slot selection behavior', () {
      final selected = selectNextAppointment(<PatientAppointment>[
        _appointment(
          DateTime(2026, 8, 7, 9),
          confirmedAt: DateTime(2026, 8, 10, 9),
          id: 'confirmed-later',
        ),
        _appointment(DateTime(2026, 8, 8, 9), id: 'requested'),
      ], now);
      expect(selected?.id, 'requested');
    });
  });
}

ProviderContainer _container({
  required Future<List<MedicationLog>> Function(Ref) medications,
  required Future<List<SymptomRecord>> Function(Ref) symptoms,
  required Future<List<PatientResult>> Function(Ref) results,
  required Future<List<PatientAppointment>> Function(Ref) appointments,
}) => ProviderContainer(
  overrides: [
    todayMedicationLogsProvider.overrideWith(medications),
    symptomRecordsProvider.overrideWith(symptoms),
    testResultsProvider.overrideWith(results),
    myAppointmentsProvider.overrideWith(appointments),
  ],
);

MedicationLog _medication(
  DateTime scheduledTime, {
  String id = 'log',
  bool taken = false,
}) => MedicationLog(
  id: id,
  drugName: 'same drug',
  dosage: '1 tablet',
  scheduledTime: scheduledTime,
  taken: taken,
  takenAt: taken ? scheduledTime : null,
);

SymptomRecord _symptom(DateTime checkedAt) => SymptomRecord(
  id: 'record',
  patientName: null,
  checkedAt: checkedAt,
  symptoms: const SymptomAnswers(
    cough: 'none',
    dyspnea: 'none',
    hemoptysis: 'none',
    chestPain: 'none',
    fever: 'none',
    weightLoss: 'none',
    appetite: 'normal',
    fatigue: 'none',
  ),
  riskLevel: 'low',
  memo: null,
);

PatientResult _result(
  String specimenId, {
  bool isReleased = true,
  DateTime? confirmedAt,
  DateTime? releasedAt,
}) => PatientResult(
  caseId: 'case-$specimenId',
  specimenId: specimenId,
  finalSubtype: 'LUAD',
  finalNote: null,
  luadProbability: null,
  luscProbability: null,
  genePredictions: const [],
  isReleased: isReleased,
  confirmedAt: confirmedAt,
  releasedAt: releasedAt,
);

PatientAppointment _appointment(
  DateTime requestedAt, {
  DateTime? confirmedAt,
  String id = 'appointment',
}) => PatientAppointment(
  id: id,
  patientName: 'patient',
  doctorName: 'doctor',
  department: 'department',
  requestedAtSlot: requestedAt,
  confirmedSlot: confirmedAt,
  status: 'requested',
  createdAt: DateTime(2026),
);
