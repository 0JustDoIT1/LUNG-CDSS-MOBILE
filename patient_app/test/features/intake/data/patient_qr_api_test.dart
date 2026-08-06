import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/network/api_client.dart';
import 'package:patient_app/core/network/auth_interceptor.dart';
import 'package:patient_app/features/intake/data/patient_qr_api.dart';

void main() {
  test('POSTs to the issue endpoint without a request body', () async {
    final client = _FakeApiClient();
    await PatientQrApi(client).issue();
    expect(client.path, '/api/intake/qr/issue/');
    expect(client.data, isNull);
    expect(client.calls, 1);
  });

  test('the shared ApiClient installs AuthInterceptor', () {
    final client = ApiClient(dio: Dio());
    expect(client.dio.interceptors.whereType<AuthInterceptor>(), hasLength(1));
  });
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(dio: Dio());
  String? path;
  Object? data;
  int calls = 0;

  @override
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    calls++;
    this.path = path;
    this.data = data;
    return Response<T>(
      data: <String, dynamic>{'token': 'server-token', 'expires_in': 300} as T,
      requestOptions: RequestOptions(path: path),
      statusCode: 201,
    );
  }
}
