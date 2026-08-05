import '../../../core/network/api_client.dart';
import 'models/intake_form.dart';

class IntakeApi {
  IntakeApi(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> fetchMyIntake() async {
    final response = await _apiClient.get<dynamic>('/api/intake/mine/');
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const FormatException('문진 조회 응답은 객체여야 합니다.');
    }
    return data;
  }

  Future<Map<String, dynamic>> saveMyIntake(IntakeContent content) async {
    final response = await _apiClient.put<dynamic>(
      '/api/intake/mine/',
      data: <String, dynamic>{'content': content.toJson()},
    );
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const FormatException('문진 저장 응답은 객체여야 합니다.');
    }
    return data;
  }
}
