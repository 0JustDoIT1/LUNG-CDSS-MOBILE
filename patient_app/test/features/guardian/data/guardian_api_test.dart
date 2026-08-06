import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/network/api_client.dart';
import 'package:patient_app/features/guardian/data/guardian_api.dart';

void main() {
  test('posts guardian invite path without a request body', () async {
    final client = _FakeApiClient();
    final result = await GuardianApi(client).createGuardianInvite();

    expect(client.postPath, '/api/auth/guardian/invite/');
    expect(client.postData, isNull);
    expect(result['invite_code'], 'SERVER1');
  });

  test('posts the exact guardian registration path and body', () async {
    final client = _FakeApiClient();
    await GuardianApi(
      client,
    ).registerGuardian(inviteCode: 'ABC123', name: '보호자');
    expect(client.postPath, '/api/auth/guardian/register/');
    expect(client.postData, <String, dynamic>{
      'invite_code': 'ABC123',
      'name': '보호자',
    });
  });

  test('uses the guardian patients endpoint', () async {
    final client = _FakeApiClient();
    await GuardianApi(client).getGuardianPatients();
    expect(client.paths, ['/api/auth/guardian/patients/']);
  });

  test('uses selected patient id in all guardian data endpoints', () async {
    final client = _FakeApiClient();
    final api = GuardianApi(client);

    await api.getGuardianAppointments('selected-id');
    await api.getGuardianMedications('selected-id');
    await api.getGuardianResults('selected-id');

    expect(client.paths, [
      '/api/auth/guardian/patients/selected-id/appointments/',
      '/api/auth/guardian/patients/selected-id/medications/',
      '/api/auth/guardian/patients/selected-id/results/',
    ]);
  });

  test('rejects an empty patient id without a request', () async {
    final client = _FakeApiClient();
    final api = GuardianApi(client);

    await expectLater(api.getGuardianAppointments(' '), throwsArgumentError);
    expect(client.paths, isEmpty);
  });
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(dio: Dio());

  final List<String> paths = [];
  String? postPath;
  Object? postData;

  @override
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    postPath = path;
    postData = data;
    final responseData = path == '/api/auth/guardian/invite/'
        ? <String, dynamic>{
            'id': 'link-id',
            'invite_code': 'SERVER1',
            'guardian_name': null,
            'invited_at': '2026-08-06T10:00:00+09:00',
            'accepted_at': null,
          }
        : <String, dynamic>{
            'access': 'access',
            'refresh': 'refresh',
            'role': 'guardian',
          };
    return Response<T>(
      data: responseData as T,
      requestOptions: RequestOptions(path: path),
    );
  }

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    paths.add(path);
    return Response<T>(
      data: <dynamic>[] as T,
      requestOptions: RequestOptions(path: path),
    );
  }
}
