import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/repositories/mock_patient_repository.dart';
import '../../../../data/repositories/patient_repository.dart';
import '../../../auth/data/models/patient_profile.dart' as api_model;
import '../../../auth/presentation/providers/auth_dependency_providers.dart';

final patientRepositoryProvider = Provider<PatientRepository>((ref) {
  return MockPatientRepository();
});

final patientProfileProvider = FutureProvider<api_model.PatientProfile>((
  ref,
) async {
  final repository = ref.watch(authRepositoryProvider);
  return repository.getPatientProfile();
});

final patientProfileUpdateProvider =
    AsyncNotifierProvider<
      PatientProfileUpdateNotifier,
      api_model.PatientProfile?
    >(PatientProfileUpdateNotifier.new);

class PatientProfileUpdateNotifier
    extends AsyncNotifier<api_model.PatientProfile?> {
  @override
  Future<api_model.PatientProfile?> build() async => null;

  Future<bool> saveProfile({
    String? name,
    String? gender,
  }) async {
    if (state.isLoading) return false;

    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      final repository = ref.read(authRepositoryProvider);
      return repository.updatePatientProfile(
        name: name,
        gender: gender,
      );
    });
    state = result;

    if (result.hasValue) {
      ref.invalidate(patientProfileProvider);
      return true;
    }
    return false;
  }
}
