import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/features/guardian/data/models/guardian_patient.dart';
import 'package:patient_app/features/guardian/presentation/providers/guardian_data_provider.dart';

void main() {
  test('automatically selects the only linked patient', () async {
    const patient = GuardianPatient(patientId: 'one', patientName: '환자');
    final container = ProviderContainer(
      overrides: [
        guardianPatientsProvider.overrideWith((ref) async => [patient]),
      ],
    );
    addTearDown(container.dispose);

    await container.read(guardianPatientsProvider.future);
    final selected = container
        .read(selectedGuardianPatientProvider)
        .requireValue;
    expect(selected?.patientId, 'one');
  });

  test('returns null when there are no linked patients', () async {
    final container = ProviderContainer(
      overrides: [guardianPatientsProvider.overrideWith((ref) async => [])],
    );
    addTearDown(container.dispose);

    await container.read(guardianPatientsProvider.future);
    expect(
      container.read(selectedGuardianPatientProvider).requireValue,
      isNull,
    );
  });

  test(
    'uses an explicitly selected patient when multiple are linked',
    () async {
      const patients = [
        GuardianPatient(patientId: 'one', patientName: '첫 환자'),
        GuardianPatient(patientId: 'two', patientName: '둘째 환자'),
      ];
      final container = ProviderContainer(
        overrides: [
          guardianPatientsProvider.overrideWith((ref) async => patients),
        ],
      );
      addTearDown(container.dispose);

      await container.read(guardianPatientsProvider.future);
      container.read(guardianSelectedPatientIdProvider.notifier).select('two');
      expect(
        container.read(selectedGuardianPatientProvider).requireValue?.patientId,
        'two',
      );
    },
  );
}
