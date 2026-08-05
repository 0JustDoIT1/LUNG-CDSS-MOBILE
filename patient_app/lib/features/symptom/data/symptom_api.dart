import '../../../core/network/api_client.dart';
import 'models/symptom_submit_request.dart';

class SymptomApi {
  SymptomApi(this._apiClient);

  final ApiClient _apiClient;

  Future<void> submitSymptoms(SymptomSubmitRequest request) async {
    await _apiClient.post<void>(
      '/api/symptoms/checks/',
      data: request.toJson(),
    );
  }
}
