import '../../../core/network/api_client.dart';

class MedicationApi {
  MedicationApi(this._apiClient);

  final ApiClient _apiClient;

  Future<List<dynamic>> getTodayMedicationLogs() async {
    final response = await _apiClient.get<dynamic>(
      '/api/medications/logs/today/',
    );
    final data = response.data;

    if (data is! List<dynamic>) {
      throw const FormatException('오늘 복약 목록 응답은 배열이어야 합니다.');
    }

    return data;
  }

  Future<Map<String, dynamic>> markAsTaken(String logId) async {
    if (logId.trim().isEmpty) {
      throw ArgumentError.value(logId, 'logId', 'must not be empty');
    }

    final response = await _apiClient.post<dynamic>(
      '/api/medications/logs/$logId/taken/',
    );
    final data = response.data;

    if (data is! Map<String, dynamic>) {
      throw const FormatException('복약 완료 응답은 객체여야 합니다.');
    }

    return data;
  }
}
