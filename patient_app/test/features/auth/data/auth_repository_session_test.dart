import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/auth/token_storage.dart';
import 'package:patient_app/core/auth/auth_role.dart';
import 'package:patient_app/core/network/api_client.dart';
import 'package:patient_app/features/auth/data/auth_api.dart';
import 'package:patient_app/features/auth/data/auth_repository.dart';

void main() {
  test(
    'authentication restoration requires both access and refresh tokens',
    () async {
      final storage = _MemoryTokenStorage(access: 'access');
      final repository = AuthRepository(
        authApi: _FakeAuthApi(),
        tokenStorage: storage,
      );

      expect(await repository.hasAccessToken(), isFalse);
      expect(storage.clearCount, 1);
      expect(storage.access, isNull);
      expect(storage.refresh, isNull);
    },
  );

  test('patient social login stores the patient role', () async {
    final storage = _MemoryTokenStorage();
    final repository = AuthRepository(
      authApi: _FakeAuthApi(
        socialLoginResponse: <String, dynamic>{
          'access': 'access',
          'refresh': 'refresh',
        },
      ),
      tokenStorage: storage,
    );

    await repository.socialLogin(provider: 'google', token: 'id-token');

    expect(storage.access, 'access');
    expect(storage.refresh, 'refresh');
    expect(storage.role, AuthRole.patient);
  });

  test('authentication restoration rejects tokens without a role', () async {
    final storage = _MemoryTokenStorage(access: 'access', refresh: 'refresh');
    final repository = AuthRepository(
      authApi: _FakeAuthApi(),
      tokenStorage: storage,
    );

    expect(await repository.hasAccessToken(), isFalse);
    expect(storage.clearCount, 1);
  });

  test(
    'authentication restoration returns a complete guardian session',
    () async {
      final storage = _MemoryTokenStorage(
        access: 'access',
        refresh: 'refresh',
        role: AuthRole.guardian,
      );
      final repository = AuthRepository(
        authApi: _FakeAuthApi(),
        tokenStorage: storage,
      );

      expect(await repository.restoreSessionRole(), AuthRole.guardian);
      expect(storage.clearCount, 0);
    },
  );

  test(
    'logout sends the current refresh token then always clears locally',
    () async {
      final events = <String>[];
      final storage = _MemoryTokenStorage(
        access: 'access',
        refresh: 'refresh',
        events: events,
      );
      final api = _FakeAuthApi(events: events, logoutFails: true);
      final repository = AuthRepository(authApi: api, tokenStorage: storage);

      await expectLater(repository.logout(), throwsA(isA<StateError>()));

      expect(api.logoutRefreshToken, 'refresh');
      expect(events, <String>['server-logout', 'local-clear']);
      expect(storage.access, isNull);
      expect(storage.refresh, isNull);
    },
  );
}

class _MemoryTokenStorage extends TokenStorage {
  _MemoryTokenStorage({this.access, this.refresh, this.role, this.events});

  String? access;
  String? refresh;
  AuthRole? role;
  final List<String>? events;
  int clearCount = 0;

  @override
  Future<String?> readAccessToken() async => access;

  @override
  Future<String?> readRefreshToken() async => refresh;

  @override
  Future<AuthRole?> readRole() async => role;

  @override
  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required AuthRole role,
  }) async {
    access = accessToken;
    refresh = refreshToken;
    this.role = role;
  }

  @override
  Future<void> clearAuthTokens() async {
    events?.add('local-clear');
    clearCount++;
    access = null;
    refresh = null;
    role = null;
  }
}

class _FakeAuthApi extends AuthApi {
  _FakeAuthApi({
    this.events,
    this.logoutFails = false,
    this.socialLoginResponse,
  }) : super(apiClient: ApiClient(dio: Dio()));

  final List<String>? events;
  final bool logoutFails;
  final Map<String, dynamic>? socialLoginResponse;
  String? logoutRefreshToken;

  @override
  Future<Map<String, dynamic>> socialLogin({
    required String provider,
    required String token,
  }) async => socialLoginResponse ?? <String, dynamic>{};

  @override
  Future<void> logout({required String refreshToken}) async {
    events?.add('server-logout');
    logoutRefreshToken = refreshToken;
    if (logoutFails) throw StateError('server logout failed');
  }
}
