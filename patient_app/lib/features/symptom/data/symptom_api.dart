import '../../../core/network/api_client.dart';
import 'models/symptom_submit_request.dart';

class SymptomApi {
  SymptomApi(this._apiClient);

  final ApiClient _apiClient;

  Future<List<dynamic>> fetchMySymptomRecords() async {
    final response = await _apiClient.get<dynamic>(
      '/api/symptoms/checks/mine/',
    );
    final data = response.data;
    if (data is! List<dynamic>) {
      throw const FormatException('증상 기록 목록 응답은 배열이어야 합니다.');
    }
    return data;
  }

  Future<void> submitSymptoms(SymptomSubmitRequest request) async {
    await _apiClient.post<void>(
      '/api/symptoms/checks/',
      data: request.toJson(),
    );
  }
}
