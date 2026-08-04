import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/patient_profile.dart';
import '../../../../data/repositories/mock_patient_repository.dart';
import '../../../../data/repositories/patient_repository.dart';

final patientRepositoryProvider = Provider<PatientRepository>((ref) {
  return MockPatientRepository();
});

final patientProfileProvider = FutureProvider<PatientProfile>((ref) async {
  final PatientRepository repository = ref.watch(
    patientRepositoryProvider,
  );

  return repository.getPatientProfile();
});