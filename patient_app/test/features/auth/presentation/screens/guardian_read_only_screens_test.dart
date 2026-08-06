import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/network/api_exception.dart';
import 'package:patient_app/features/auth/presentation/screens/guardian_appointments_screen.dart';
import 'package:patient_app/features/auth/presentation/screens/guardian_home_screen.dart';
import 'package:patient_app/features/auth/presentation/screens/guardian_medications_screen.dart';
import 'package:patient_app/features/auth/presentation/screens/guardian_results_screen.dart';
import 'package:patient_app/features/guardian/data/models/guardian_appointment.dart';
import 'package:patient_app/features/guardian/data/models/guardian_medication.dart';
import 'package:patient_app/features/guardian/data/models/guardian_patient.dart';
import 'package:patient_app/features/guardian/data/models/guardian_result.dart';
import 'package:patient_app/features/guardian/presentation/providers/guardian_data_provider.dart';

const patient = GuardianPatient(patientId: 'patient-id', patientName: '환자');

void main() {
  testWidgets(
    'guardian home exposes only results appointments and medication',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            guardianPatientsProvider.overrideWith((ref) async => [patient]),
            guardianResultsProvider(
              patient.patientId,
            ).overrideWith((ref) async => <GuardianResult>[]),
            guardianAppointmentsProvider(
              patient.patientId,
            ).overrideWith((ref) async => <GuardianAppointment>[]),
            guardianMedicationsProvider(
              patient.patientId,
            ).overrideWith((ref) async => <GuardianMedication>[]),
          ],
          child: const MaterialApp(home: GuardianHomeScreen()),
        ),
      );
      await tester.pump();

      expect(find.text('검사결과'), findsOneWidget);
      expect(find.text('다음 진료 예약'), findsOneWidget);
      expect(find.text('오늘의 복약 정보'), findsOneWidget);
      expect(find.text('최근 증상 체크'), findsNothing);
    },
  );

  testWidgets('guardian appointment screen is read-only', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedGuardianPatientProvider.overrideWithValue(
            const AsyncData(patient),
          ),
          guardianAppointmentsProvider(
            patient.patientId,
          ).overrideWith((ref) async => <GuardianAppointment>[]),
        ],
        child: const MaterialApp(home: GuardianAppointmentsScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('예정된 예약이 없습니다.'), findsOneWidget);
    expect(find.text('예약 신청'), findsNothing);
    expect(find.text('변경'), findsNothing);
    expect(find.text('취소'), findsNothing);
  });

  testWidgets('guardian medication state cannot be changed', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedGuardianPatientProvider.overrideWithValue(
            const AsyncData(patient),
          ),
          guardianMedicationsProvider(
            patient.patientId,
          ).overrideWith((ref) async => <GuardianMedication>[]),
        ],
        child: const MaterialApp(home: GuardianMedicationsScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('오늘 등록된 복약 정보가 없습니다.'), findsOneWidget);
    expect(find.byType(Checkbox), findsNothing);
    expect(find.byType(Switch), findsNothing);
  });

  testWidgets('guardian appointment screen shows the 403 policy message', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedGuardianPatientProvider.overrideWithValue(
            const AsyncData(patient),
          ),
          guardianAppointmentsProvider(patient.patientId).overrideWith(
            (ref) => Future<List<GuardianAppointment>>.error(
              const ApiException(message: 'forbidden', statusCode: 403),
            ),
          ),
        ],
        child: const MaterialApp(home: GuardianAppointmentsScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('연결된 환자 정보를 조회할 권한이 없습니다.'), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);
  });

  testWidgets('guardian result screen does not expose AI information', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedGuardianPatientProvider.overrideWithValue(
            const AsyncData(patient),
          ),
          guardianResultsProvider(
            patient.patientId,
          ).overrideWith((ref) async => <GuardianResult>[]),
        ],
        child: const MaterialApp(home: GuardianResultsScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('등록된 결과가 없습니다.'), findsOneWidget);
    expect(find.textContaining('LUAD'), findsNothing);
    expect(find.textContaining('LUSC'), findsNothing);
    expect(find.textContaining('AI'), findsNothing);
    expect(find.textContaining('유전자'), findsNothing);
  });

  testWidgets('guardian result shows subtype and gene likelihood read-only', (
    tester,
  ) async {
    final result = GuardianResult.fromJson(<String, dynamic>{
      'final_subtype': 'LUAD',
      'gene_predictions': <dynamic>[
        <String, dynamic>{'gene_name': 'EGFR', 'likelihood': 0.64},
        <String, dynamic>{'gene_name': 'TP53', 'likelihood': null},
      ],
      'confirmed_at': '2026-08-06T10:30:00+09:00',
      'released_at': '2026-08-06T10:30:00+09:00',
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedGuardianPatientProvider.overrideWithValue(
            const AsyncData(patient),
          ),
          guardianResultsProvider(
            patient.patientId,
          ).overrideWith((ref) async => <GuardianResult>[result]),
        ],
        child: const MaterialApp(home: GuardianResultsScreen()),
      ),
    );
    await tester.pump();

    expect(find.textContaining('LUAD'), findsOneWidget);
    expect(find.text('EGFR'), findsOneWidget);
    expect(find.text('64.0%'), findsOneWidget);
    expect(find.text('TP53'), findsOneWidget);
    expect(find.text('정보 없음'), findsOneWidget);
    expect(find.textContaining('확정일'), findsOneWidget);
    expect(find.textContaining('공개일'), findsOneWidget);
    expect(find.textContaining('final_note'), findsNothing);
    expect(find.textContaining('luad_probability'), findsNothing);
    expect(find.byType(Checkbox), findsNothing);
    expect(find.byType(Switch), findsNothing);
  });

  testWidgets('guardian result displays LUSC subtype', (tester) async {
    final result = GuardianResult.fromJson(<String, dynamic>{
      'final_subtype': 'LUSC',
      'gene_predictions': <dynamic>[],
      'confirmed_at': null,
      'released_at': null,
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedGuardianPatientProvider.overrideWithValue(
            const AsyncData(patient),
          ),
          guardianResultsProvider(
            patient.patientId,
          ).overrideWith((ref) async => <GuardianResult>[result]),
        ],
        child: const MaterialApp(home: GuardianResultsScreen()),
      ),
    );
    await tester.pump();

    expect(find.textContaining('LUSC'), findsOneWidget);
  });
}
