import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/test_result.dart';
import '../../../../data/repositories/mock_test_result_repository.dart';
import '../../../../data/repositories/test_result_repository.dart';
import '../../../auth/presentation/providers/auth_dependency_providers.dart';
import '../../data/models/patient_result_summary.dart';
import '../../data/patient_results_api.dart';
import '../../data/patient_results_repository.dart';

final testResultRepositoryProvider = Provider<TestResultRepository>((ref) {
  return MockTestResultRepository();
});

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

final testResultsProvider = FutureProvider<List<PatientResultSummary>>((
  ref,
) async {
  final repository = ref.read(patientResultsRepositoryProvider);

  return repository.getMyResults();
});

final testResultDetailProvider = FutureProvider.family<TestResult?, String>((
  ref,
  id,
) async {
  final repository = ref.read(testResultRepositoryProvider);

  return repository.getTestResultById(id);
});
