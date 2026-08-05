import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_dependency_providers.dart';
import '../../data/models/patient_result.dart';
import '../../data/patient_results_api.dart';
import '../../data/patient_results_repository.dart';

final patientResultsApiProvider = Provider<PatientResultsApi>((ref) {
  final apiClient = ref.watch(apiClientProvider);

  return PatientResultsApi(apiClient: apiClient);
});

final patientResultsRepositoryProvider = Provider<PatientResultsRepository>((
  ref,
) {
  final patientResultsApi = ref.watch(patientResultsApiProvider);

  return PatientResultsRepository(patientResultsApi: patientResultsApi);
});

final testResultsProvider = FutureProvider<List<PatientResult>>((ref) async {
  final repository = ref.read(patientResultsRepositoryProvider);

  return repository.fetchMyResults();
});

final testResultDetailProvider = FutureProvider.family<PatientResult, String>((
  ref,
  caseId,
) async {
  final repository = ref.read(patientResultsRepositoryProvider);
  return repository.fetchMyResultDetail(caseId);
});
