import '../../../core/network/api_client.dart';

class PatientQrApi {
  PatientQrApi(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> issue() async {
    final response = await _apiClient.post<dynamic>('/api/intake/qr/issue/');
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const FormatException('QR issue response must be an object');
    }
    return data;
  }
}
