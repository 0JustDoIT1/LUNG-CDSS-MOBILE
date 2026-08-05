import '../../../core/network/api_client.dart';

class AuthApi {
  AuthApi({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> socialLogin({
    required String provider,
    required String token,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/api/auth/patient/social-login/',
      data: {'provider': provider, 'token': token},
    );

    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> registerPatient({
    required String signupToken,
    required String birthDate,
    required String hospitalId,
    required String phoneNumber,
    required String gender,
  }) async {
    if (gender != 'female' && gender != 'male') {
      throw ArgumentError.value(gender, 'gender', 'male 또는 female이어야 합니다.');
    }

    final response = await _apiClient.post<Map<String, dynamic>>(
      '/api/auth/patient/register/',
      data: {
        'signup_token': signupToken,
        'birth_date': birthDate,
        'hospital_id': hospitalId,
        'phone_number': phoneNumber,
        'gender': gender,
      },
    );

    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> getHospital() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/api/auth/hospital/',
    );

    return response.data ?? <String, dynamic>{};
  }

  Future<dynamic> getPatientProfile() async {
    final response = await _apiClient.get<dynamic>(
      '/api/auth/patient/profile/',
    );

    return response.data;
  }

  Future<dynamic> updatePatientProfile({
    String? name,
    String? gender,
  }) async {
    if (gender != null && gender != 'male' && gender != 'female') {
      throw ArgumentError.value(gender, 'gender', 'male 또는 female이어야 합니다.');
    }

    final data = <String, dynamic>{
      'name': ?name,
      'gender': ?gender,
    };

    final response = await _apiClient.patch<dynamic>(
      '/api/auth/patient/profile/',
      data: data,
    );
    return response.data;
  }

  Future<Map<String, dynamic>> refreshToken({
    required String refreshToken,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/api/auth/refresh/',
      data: {'refresh': refreshToken},
    );

    return response.data ?? <String, dynamic>{};
  }

  Future<void> logout({required String refreshToken}) async {
    await _apiClient.post<void>(
      '/api/auth/logout/',
      data: {'refresh': refreshToken},
    );
  }
}
