import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/auth/token_storage.dart';
import 'package:patient_app/core/network/api_client.dart';
import 'package:patient_app/features/guardian/data/guardian_api.dart';

void main() {
  test('guardian invite attaches the patient authorization', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    final adapter = _GuardianRegisterAdapter();
    dio.httpClientAdapter = adapter;
    final api = GuardianApi(
      ApiClient(dio: dio, tokenStorage: _TokenStorageWithPatientToken()),
    );

    await api.createGuardianInvite();

    expect(adapter.path, '/api/auth/guardian/invite/');
    expect(adapter.authorization, 'Bearer existing-patient-token');
  });

  test(
    'guardian registration does not attach an existing authorization',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      final adapter = _GuardianRegisterAdapter();
      dio.httpClientAdapter = adapter;
      final api = GuardianApi(
        ApiClient(dio: dio, tokenStorage: _TokenStorageWithPatientToken()),
      );

      await api.registerGuardian(inviteCode: 'ABC123', name: '보호자');

      expect(adapter.path, '/api/auth/guardian/register/');
      expect(adapter.authorization, isNull);
    },
  );
}

class _TokenStorageWithPatientToken extends TokenStorage {
  @override
  Future<String?> readAccessToken() async => 'existing-patient-token';
}

class _GuardianRegisterAdapter implements HttpClientAdapter {
  String? path;
  String? authorization;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    path = options.path;
    authorization = options.headers['Authorization'] as String?;
    final data = options.path == '/api/auth/guardian/invite/'
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
    return ResponseBody.fromString(
      jsonEncode(data),
      201,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
