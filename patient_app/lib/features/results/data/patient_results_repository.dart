import 'models/patient_result_summary.dart';
import 'patient_results_api.dart';

class PatientResultsRepository {
  PatientResultsRepository({required PatientResultsApi patientResultsApi})
    : _patientResultsApi = patientResultsApi;

  final PatientResultsApi _patientResultsApi;

  Future<List<PatientResultSummary>> getMyResults() async {
    final results = await _patientResultsApi.getMyResults();
    return parseResults(results);
  }

  static List<PatientResultSummary> parseResults(List<dynamic> results) {
    return results
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const FormatException('검사 결과 목록의 각 항목은 객체여야 합니다.');
          }

          return PatientResultSummary.fromJson(item);
        })
        .toList(growable: false);
  }
}
