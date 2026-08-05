import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/auth/token_storage.dart';
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

  test('authentication restoration accepts a complete token pair', () async {
    final storage = _MemoryTokenStorage(access: 'access', refresh: 'refresh');
    final repository = AuthRepository(
      authApi: _FakeAuthApi(),
      tokenStorage: storage,
    );

    expect(await repository.hasAccessToken(), isTrue);
    expect(storage.clearCount, 0);
  });

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
  _MemoryTokenStorage({this.access, this.refresh, this.events});

  String? access;
  String? refresh;
  final List<String>? events;
  int clearCount = 0;

  @override
  Future<String?> readAccessToken() async => access;

  @override
  Future<String?> readRefreshToken() async => refresh;

  @override
  Future<void> clearAuthTokens() async {
    events?.add('local-clear');
    clearCount++;
    access = null;
    refresh = null;
  }
}

class _FakeAuthApi extends AuthApi {
  _FakeAuthApi({this.events, this.logoutFails = false})
    : super(apiClient: ApiClient(dio: Dio()));

  final List<String>? events;
  final bool logoutFails;
  String? logoutRefreshToken;

  @override
  Future<void> logout({required String refreshToken}) async {
    events?.add('server-logout');
    logoutRefreshToken = refreshToken;
    if (logoutFails) throw StateError('server logout failed');
  }
}
