import '../../../core/network/api_client.dart';

class AppointmentApi {
  AppointmentApi(this._apiClient);

  final ApiClient _apiClient;

  Future<List<dynamic>> fetchDepartments() async {
    final response = await _apiClient.get<dynamic>(
      '/api/appointments/departments/',
    );
    if (response.data is! List<dynamic>) {
      throw const FormatException('진료과 응답은 배열이어야 합니다.');
    }
    return response.data! as List<dynamic>;
  }

  Future<List<dynamic>> fetchDoctors(String department) async {
    if (department.trim().isEmpty) throw ArgumentError('department는 필수입니다.');
    final response = await _apiClient.get<dynamic>(
      '/api/appointments/doctors/',
      queryParameters: <String, dynamic>{'department': department},
    );
    if (response.data is! List<dynamic>) {
      throw const FormatException('의료진 응답은 배열이어야 합니다.');
    }
    return response.data! as List<dynamic>;
  }

  Future<Map<String, dynamic>> fetchDoctorSlots({
    required String doctorId,
    required String date,
  }) async {
    if (doctorId.trim().isEmpty || date.trim().isEmpty) {
      throw ArgumentError('doctorId와 date는 필수입니다.');
    }
    final response = await _apiClient.get<dynamic>(
      '/api/appointments/doctors/$doctorId/slots/',
      queryParameters: <String, dynamic>{'date': date},
    );
    if (response.data is! Map<String, dynamic>) {
      throw const FormatException('예약 슬롯 응답은 객체여야 합니다.');
    }
    return response.data! as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createAppointment({
    required String doctorId,
    required String department,
    required String requestedAtSlot,
  }) async {
    final response = await _apiClient.post<dynamic>(
      '/api/appointments/',
      data: <String, dynamic>{
        'doctor_id': doctorId,
        'department': department,
        'requested_at_slot': requestedAtSlot,
      },
    );
    if (response.data is! Map<String, dynamic>) {
      throw const FormatException('예약 신청 응답은 객체여야 합니다.');
    }
    return response.data! as Map<String, dynamic>;
  }

  Future<List<dynamic>> getMyAppointments() async {
    final response = await _apiClient.get<dynamic>('/api/appointments/mine/');
    final data = response.data;

    if (data is! List<dynamic>) {
      throw const FormatException('예약 목록 응답은 배열이어야 합니다.');
    }

    return data;
  }

  Future<void> cancelAppointment(String appointmentId) async {
    if (appointmentId.trim().isEmpty) {
      throw ArgumentError.value(
        appointmentId,
        'appointmentId',
        'must not be empty',
      );
    }

    await _apiClient.post<void>('/api/appointments/$appointmentId/cancel/');
  }
}
