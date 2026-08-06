import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_dependency_providers.dart';
import '../../data/guardian_api.dart';
import '../../data/guardian_repository.dart';
import '../../data/models/guardian_appointment.dart';
import '../../data/models/guardian_invite.dart';
import '../../data/models/guardian_medication.dart';
import '../../data/models/guardian_patient.dart';
import '../../data/models/guardian_result.dart';

final guardianApiProvider = Provider<GuardianApi>((ref) {
  return GuardianApi(ref.watch(apiClientProvider));
});

final guardianRepositoryProvider = Provider<GuardianRepository>((ref) {
  return GuardianRepository(
    ref.watch(guardianApiProvider),
    ref.watch(tokenStorageProvider),
  );
});

final guardianInviteProvider =
    AsyncNotifierProvider<GuardianInviteNotifier, GuardianInvite>(
      GuardianInviteNotifier.new,
    );

class GuardianInviteNotifier extends AsyncNotifier<GuardianInvite> {
  @override
  Future<GuardianInvite> build() {
    return ref.watch(guardianRepositoryProvider).createGuardianInvite();
  }

  Future<void> createNewInvite() async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      ref.read(guardianRepositoryProvider).createGuardianInvite,
    );
  }
}

final guardianPatientsProvider = FutureProvider<List<GuardianPatient>>((ref) {
  return ref.watch(guardianRepositoryProvider).getGuardianPatients();
});

final guardianSelectedPatientIdProvider =
    NotifierProvider<GuardianSelectedPatientIdNotifier, String?>(
      GuardianSelectedPatientIdNotifier.new,
    );

class GuardianSelectedPatientIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String patientId) {
    if (patientId.trim().isEmpty) {
      throw ArgumentError('patientId는 비어 있을 수 없습니다.');
    }
    state = patientId;
  }
}

final selectedGuardianPatientProvider = Provider<AsyncValue<GuardianPatient?>>((
  ref,
) {
  final patients = ref.watch(guardianPatientsProvider);
  final selectedId = ref.watch(guardianSelectedPatientIdProvider);
  return patients.whenData((items) {
    if (items.isEmpty) return null;
    if (selectedId == null) return items.first;
    for (final patient in items) {
      if (patient.patientId == selectedId) return patient;
    }
    return items.first;
  });
});

final guardianAppointmentsProvider =
    FutureProvider.family<List<GuardianAppointment>, String>((ref, patientId) {
      return ref
          .watch(guardianRepositoryProvider)
          .getGuardianAppointments(patientId);
    });

final guardianMedicationsProvider =
    FutureProvider.family<List<GuardianMedication>, String>((ref, patientId) {
      return ref
          .watch(guardianRepositoryProvider)
          .getGuardianMedications(patientId);
    });

final guardianResultsProvider =
    FutureProvider.family<List<GuardianResult>, String>((ref, patientId) {
      return ref
          .watch(guardianRepositoryProvider)
          .getGuardianResults(patientId);
    });
