import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/test_result.dart';
import '../../../../data/repositories/mock_test_result_repository.dart';
import '../../../../data/repositories/test_result_repository.dart';

final testResultRepositoryProvider =
    Provider<TestResultRepository>((ref) {
  return MockTestResultRepository();
});

final testResultsProvider =
    FutureProvider<List<TestResult>>((ref) async {
  final repository = ref.read(testResultRepositoryProvider);

  return repository.getTestResults();
});

final testResultDetailProvider =
    FutureProvider.family<TestResult?, String>((ref, id) async {
  final repository = ref.read(testResultRepositoryProvider);

  return repository.getTestResultById(id);
});