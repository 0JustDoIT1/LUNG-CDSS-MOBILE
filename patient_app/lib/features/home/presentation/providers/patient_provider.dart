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
