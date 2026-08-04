import '../mock/mock_test_result_data.dart';
import '../models/test_result.dart';
import 'test_result_repository.dart';

class MockTestResultRepository implements TestResultRepository {
  @override
  Future<List<TestResult>> getTestResults() async {
    await Future<void>.delayed(
      const Duration(milliseconds: 500),
    );

    return MockTestResultData.results;
  }

  @override
  Future<TestResult?> getTestResultById(String id) async {
    await Future<void>.delayed(
      const Duration(milliseconds: 400),
    );

    for (final result in MockTestResultData.results) {
      if (result.id == id) {
        return result;
      }
    }

    return null;
  }
}