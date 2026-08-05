import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/network/api_client.dart';
import 'package:patient_app/features/intake/data/intake_api.dart';
import 'package:patient_app/features/intake/data/models/intake_form.dart';

void main() {
  test('uses the exact GET endpoint', () async {
    final client = _FakeApiClient(_response);
    await IntakeApi(client).fetchMyIntake();
    expect(client.method, 'GET');
    expect(client.path, '/api/intake/mine/');
  });

  test('wraps draft and submitted content for PUT', () async {
    for (final status in IntakeStatus.values) {
      final client = _FakeApiClient(_response);
      await IntakeApi(client).saveMyIntake(
        IntakeContent(status: status, questions: const <IntakeQuestion>[]),
      );
      expect(client.method, 'PUT');
      expect(client.path, '/api/intake/mine/');
      expect(client.data, <String, dynamic>{
        'content': <String, dynamic>{
          'status': status.name,
          'questions': <dynamic>[],
        },
      });
    }
  });

  test('rejects a non-object response', () async {
    await expectLater(
      IntakeApi(_FakeApiClient(<dynamic>[])).fetchMyIntake(),
      throwsFormatException,
    );
  });
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient(this.responseData) : super(dio: Dio());

  final Object? responseData;
  String? method;
  String? path;
  Object? data;

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    method = 'GET';
    this.path = path;
    return Response<T>(
      data: responseData as T?,
      requestOptions: RequestOptions(path: path),
    );
  }

  @override
  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    method = 'PUT';
    this.path = path;
    this.data = data;
    return Response<T>(
      data: responseData as T?,
      requestOptions: RequestOptions(path: path),
    );
  }
}

final _response = <String, dynamic>{
  'id': 'intake-id',
  'content': <String, dynamic>{'status': 'draft', 'questions': <dynamic>[]},
  'submitted_at': null,
  'updated_at': '2026-08-05T16:10:00+09:00',
};
