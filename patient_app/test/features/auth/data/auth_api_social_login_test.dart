import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/network/api_client.dart';
import 'package:patient_app/features/auth/data/auth_api.dart';

void main() {
  test('sends Kakao OAuth access token in the common social body', () async {
    final client = _RecordingApiClient();

    await AuthApi(
      apiClient: client,
    ).socialLogin(provider: 'kakao', token: 'oauth-access-token');

    expect(client.path, '/api/auth/patient/social-login/');
    expect(client.data, <String, dynamic>{
      'provider': 'kakao',
      'token': 'oauth-access-token',
    });
    expect(client.data, isNot(contains('id_token')));
  });
}

class _RecordingApiClient extends ApiClient {
  _RecordingApiClient() : super(dio: Dio());

  String? path;
  Object? data;

  @override
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    this.path = path;
    this.data = data;
    return Response<T>(
      data: <String, dynamic>{'signup_token': 'signup-token'} as T,
      requestOptions: RequestOptions(path: path),
    );
  }
}
