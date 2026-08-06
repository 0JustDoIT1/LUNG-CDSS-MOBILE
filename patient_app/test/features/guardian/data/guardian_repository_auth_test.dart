import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/auth/auth_role.dart';
import 'package:patient_app/core/auth/token_storage.dart';
import 'package:patient_app/core/network/api_client.dart';
import 'package:patient_app/features/guardian/data/guardian_api.dart';
import 'package:patient_app/features/guardian/data/guardian_repository.dart';

void main() {
  test(
    'stores guardian tokens and role before registration completes',
    () async {
      final storage = _MemoryTokenStorage();
      final repository = GuardianRepository(_FakeGuardianApi(), storage);

      await repository.registerGuardian(inviteCode: 'ABC123', name: '보호자');

      expect(storage.access, 'access');
      expect(storage.refresh, 'refresh');
      expect(storage.role, AuthRole.guardian);
    },
  );

  test('propagates storage failure to prevent successful navigation', () async {
    final repository = GuardianRepository(
      _FakeGuardianApi(),
      _MemoryTokenStorage(shouldFail: true),
    );

    await expectLater(
      repository.registerGuardian(inviteCode: 'ABC123', name: '보호자'),
      throwsStateError,
    );
  });

  test('rejects a non-guardian role response', () async {
    final repository = GuardianRepository(
      _FakeGuardianApi(role: 'patient'),
      _MemoryTokenStorage(),
    );

    await expectLater(
      repository.registerGuardian(inviteCode: 'ABC123', name: '보호자'),
      throwsFormatException,
    );
  });
}

class _FakeGuardianApi extends GuardianApi {
  _FakeGuardianApi({this.role = 'guardian'}) : super(ApiClient(dio: Dio()));
  final String role;

  @override
  Future<Map<String, dynamic>> registerGuardian({
    required String inviteCode,
    required String name,
  }) async => <String, dynamic>{
    'access': 'access',
    'refresh': 'refresh',
    'role': role,
  };
}

class _MemoryTokenStorage extends TokenStorage {
  _MemoryTokenStorage({this.shouldFail = false});
  final bool shouldFail;
  String? access;
  String? refresh;
  AuthRole? role;

  @override
  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required AuthRole role,
  }) async {
    if (shouldFail) throw StateError('storage failed');
    access = accessToken;
    refresh = refreshToken;
    this.role = role;
  }
}
