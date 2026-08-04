import '../models/test_result.dart';

abstract class TestResultRepository {
  Future<List<TestResult>> getTestResults();

  Future<TestResult?> getTestResultById(String id);
}
