import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/network/api_client.dart';
import 'package:patient_app/features/auth/data/auth_api.dart';

void main() {
  group('AuthApi.updatePatientProfile', () {
    test('patches only editable name and gender fields', () async {
      final client = _FakeApiClient();
      final api = AuthApi(apiClient: client);

      await api.updatePatientProfile(name: '홍길동', gender: 'female');

      expect(client.lastPath, '/api/auth/patient/profile/');
      expect(client.lastData, {'name': '홍길동', 'gender': 'female'});
    });

    test('patches only gender when only gender changed', () async {
      final client = _FakeApiClient();
      final api = AuthApi(apiClient: client);

      await api.updatePatientProfile(gender: 'female');

      expect(client.lastData, {'gender': 'female'});
    });

    test('never includes immutable profile fields', () async {
      final client = _FakeApiClient();
      final api = AuthApi(apiClient: client);

      await api.updatePatientProfile(name: '홍길동');

      final body = client.lastData!;
      expect(body, isNot(contains('phone_number')));
      expect(body, isNot(contains('patient_number')));
      expect(body, isNot(contains('hospital')));
      expect(body, isNot(contains('hospital_name')));
      expect(body, isNot(contains('assigned_doctor')));
      expect(body, isNot(contains('birth_date')));
    });
  });
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(dio: Dio());

  String? lastPath;
  Map<String, dynamic>? lastData;

  @override
  Future<Response<T>> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    lastPath = path;
    lastData = Map<String, dynamic>.from(data! as Map);
    return Response<T>(
      data: _validResponse as T,
      requestOptions: RequestOptions(path: path),
    );
  }
}

const _validResponse = <String, dynamic>{
  'patient_number': 'P1234567',
  'birth_date': '1990-01-01',
  'gender': 'female',
  'hospital_name': '서울병원',
  'assigned_doctor': null,
  'name': '홍길동',
};
