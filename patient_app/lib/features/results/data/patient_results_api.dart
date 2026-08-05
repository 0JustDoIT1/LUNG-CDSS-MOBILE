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
}
