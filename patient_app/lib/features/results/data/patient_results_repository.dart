import 'models/patient_result.dart';
import 'patient_results_api.dart';

class PatientResultsRepository {
  PatientResultsRepository({required PatientResultsApi patientResultsApi})
    : _patientResultsApi = patientResultsApi;

  final PatientResultsApi _patientResultsApi;

  Future<List<PatientResult>> fetchMyResults() async {
    final results = await _patientResultsApi.getMyResults();
    return parseResults(results);
  }

  Future<PatientResult> fetchMyResultDetail(String caseId) async {
    final result = await _patientResultsApi.getMyResultDetail(caseId);
    return PatientResult.fromJson(result);
  }

  static List<PatientResult> parseResults(List<dynamic> results) {
    return results
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const FormatException('검사 결과 목록의 각 항목은 객체여야 합니다.');
          }

          return PatientResult.fromJson(item);
        })
        .toList(growable: false);
  }
}
