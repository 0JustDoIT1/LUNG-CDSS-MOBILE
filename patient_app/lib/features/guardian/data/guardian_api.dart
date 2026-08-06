import '../../../core/network/api_client.dart';

class GuardianApi {
  GuardianApi(this._apiClient);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> createGuardianInvite() async {
    final response = await _apiClient.post<dynamic>(
      '/api/auth/guardian/invite/',
    );
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const FormatException('보호자 초대 응답은 객체여야 합니다.');
    }
    return data;
  }

  Future<Map<String, dynamic>> registerGuardian({
    required String inviteCode,
    required String name,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/api/auth/guardian/register/',
      data: <String, dynamic>{'invite_code': inviteCode, 'name': name},
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<List<dynamic>> getGuardianPatients() =>
      _getList('/api/auth/guardian/patients/');

  Future<List<dynamic>> getGuardianAppointments(String patientId) {
    _validatePatientId(patientId);
    return _getList('/api/auth/guardian/patients/$patientId/appointments/');
  }

  Future<List<dynamic>> getGuardianMedications(String patientId) {
    _validatePatientId(patientId);
    return _getList('/api/auth/guardian/patients/$patientId/medications/');
  }

  Future<List<dynamic>> getGuardianResults(String patientId) {
    _validatePatientId(patientId);
    return _getList('/api/auth/guardian/patients/$patientId/results/');
  }

  Future<List<dynamic>> _getList(String path) async {
    final response = await _apiClient.get<dynamic>(path);
    final data = response.data;
    if (data is! List<dynamic>) {
      throw const FormatException('보호자 조회 응답은 배열이어야 합니다.');
    }
    return data;
  }

  static void _validatePatientId(String patientId) {
    if (patientId.trim().isEmpty) {
      throw ArgumentError('patientId는 비어 있을 수 없습니다.');
    }
  }
}
