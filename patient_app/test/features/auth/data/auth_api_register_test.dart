import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/network/api_client.dart';
import 'package:patient_app/core/network/api_exception.dart';
import 'package:patient_app/features/auth/data/auth_api.dart';

void main() {
  group('AuthApi.registerPatient', () {
    test('posts gender with all existing registration fields', () async {
      final client = _FakeApiClient(responseData: <String, dynamic>{});
      final api = AuthApi(apiClient: client);

      await api.registerPatient(
        signupToken: 'signup-token',
        birthDate: '1990-01-01',
        hospitalId: 'hospital-uuid',
        phoneNumber: '010-1234-5678',
        gender: 'female',
      );

      expect(client.lastPath, '/api/auth/patient/register/');
      expect(client.lastData, {
        'signup_token': 'signup-token',
        'birth_date': '1990-01-01',
        'hospital_id': 'hospital-uuid',
        'phone_number': '010-1234-5678',
        'gender': 'female',
      });
    });

    test('accepts the male API value', () async {
      final client = _FakeApiClient(responseData: <String, dynamic>{});
      final api = AuthApi(apiClient: client);

      await api.registerPatient(
        signupToken: 'signup-token',
        birthDate: '1990-01-01',
        hospitalId: 'hospital-uuid',
        phoneNumber: '010-1234-5678',
        gender: 'male',
      );

      expect((client.lastData as Map<String, dynamic>)['gender'], 'male');
    });

    test('blocks an unsupported gender before a request', () async {
      final client = _FakeApiClient(responseData: <String, dynamic>{});
      final api = AuthApi(apiClient: client);

      await expectLater(
        api.registerPatient(
          signupToken: 'signup-token',
          birthDate: '1990-01-01',
          hospitalId: 'hospital-uuid',
          phoneNumber: '010-1234-5678',
          gender: 'unknown',
        ),
        throwsArgumentError,
      );
      expect(client.callCount, 0);
    });

    test('preserves a 400 validation error', () async {
      const exception = ApiException(message: 'validation', statusCode: 400);
      final api = AuthApi(apiClient: _FakeApiClient(error: exception));

      await expectLater(
        api.registerPatient(
          signupToken: 'signup-token',
          birthDate: '1990-01-01',
          hospitalId: 'hospital-uuid',
          phoneNumber: '010-1234-5678',
          gender: 'female',
        ),
        throwsA(same(exception)),
      );
    });
  });
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient({this.responseData, this.error}) : super(dio: Dio());

  final Object? responseData;
  final Object? error;
  String? lastPath;
  Object? lastData;
  int callCount = 0;

  @override
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    lastPath = path;
    lastData = data;
    callCount++;
    if (error != null) throw error!;
    return Response<T>(
      data: responseData as T?,
      requestOptions: RequestOptions(path: path),
    );
  }
}
