import '../../../core/network/api_client.dart';

class PatientResultsApi {
  PatientResultsApi({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<dynamic>> getMyResults() async {
    final response = await _apiClient.get<dynamic>('/api/cases/my-results/');
    final data = response.data;

    if (data is! List<dynamic>) {
      throw const FormatException('검사 결과 목록 응답은 배열이어야 합니다.');
    }

    return data;
  }

  Future<Map<String, dynamic>> getMyResultDetail(String caseId) async {
    if (caseId.trim().isEmpty) {
      throw ArgumentError.value(caseId, 'caseId', '비어 있을 수 없습니다.');
    }
    final response = await _apiClient.get<dynamic>(
      '/api/cases/my-results/$caseId/',
    );
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const FormatException('검사 결과 상세 응답은 객체여야 합니다.');
    }
    return data;
  }
}
