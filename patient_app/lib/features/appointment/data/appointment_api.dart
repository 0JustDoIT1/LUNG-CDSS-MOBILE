import '../../../core/network/api_client.dart';

class AppointmentApi {
  AppointmentApi(this._apiClient);

  final ApiClient _apiClient;

  Future<List<dynamic>> getMyAppointments() async {
    final response = await _apiClient.get<dynamic>('/api/appointments/mine/');
    final data = response.data;

    if (data is! List<dynamic>) {
      throw const FormatException('예약 목록 응답은 배열이어야 합니다.');
    }

    return data;
  }
}
