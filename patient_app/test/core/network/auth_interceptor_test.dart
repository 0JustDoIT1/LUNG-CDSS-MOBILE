import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/auth/auth_session_coordinator.dart';
import 'package:patient_app/core/auth/token_storage.dart';
import 'package:patient_app/core/network/api_client.dart';
import 'package:patient_app/core/network/api_exception.dart';

void main() {
  test(
    '401 refreshes both tokens and retries with the new access token',
    () async {
      final fixture = _Fixture();

      final response = await fixture.client.get<dynamic>('/protected/');

      expect(response.statusCode, 200);
      expect(fixture.refresh.callCount, 1);
      expect(fixture.storage.accessToken, 'new-access');
      expect(fixture.storage.refreshToken, 'new-refresh');
      expect(fixture.main.retryAuthorization, 'Bearer new-access');
      expect(fixture.main.callCount, 2);
    },
  );

  test(
    'concurrent 401 responses share one refresh and each retry once',
    () async {
      final fixture = _Fixture(refreshDelay: true);
      final requests = <Future<Response<dynamic>>>[
        fixture.client.get<dynamic>('/one/'),
        fixture.client.get<dynamic>('/two/'),
        fixture.client.get<dynamic>('/three/'),
      ];
      await Future<void>.delayed(Duration.zero);
      fixture.refresh.complete();

      await Future.wait(requests);

      expect(fixture.refresh.callCount, 1);
      expect(fixture.main.callCount, 6);
    },
  );

  test('refresh failure clears tokens and emits one expiration', () async {
    final coordinator = AuthSessionCoordinator();
    var expirationCount = 0;
    coordinator.onExpired.listen((_) => expirationCount++);
    final fixture = _Fixture(refreshFails: true, coordinator: coordinator);

    await expectLater(
      fixture.client.get<dynamic>('/protected/'),
      throwsA(isA<ApiException>()),
    );

    expect(fixture.storage.accessToken, isNull);
    expect(fixture.storage.refreshToken, isNull);
    expect(expirationCount, 1);
  });

  test('a retried request that returns 401 does not refresh again', () async {
    final fixture = _Fixture(retryFails: true);

    await expectLater(
      fixture.client.get<dynamic>('/protected/'),
      throwsA(isA<ApiException>()),
    );

    expect(fixture.refresh.callCount, 1);
    expect(fixture.main.callCount, 2);
    expect(fixture.storage.accessToken, isNull);
    expect(fixture.storage.refreshToken, isNull);
  });

  test('403 is forwarded without refreshing', () async {
    final fixture = _Fixture(statusCode: 403);

    await expectLater(
      fixture.client.get<dynamic>('/protected/'),
      throwsA(isA<ApiException>()),
    );

    expect(fixture.refresh.callCount, 0);
  });

  test(
    'logout during refresh prevents refreshed tokens from being stored',
    () async {
      final coordinator = AuthSessionCoordinator();
      final fixture = _Fixture(refreshDelay: true, coordinator: coordinator);
      final request = fixture.client.get<dynamic>('/protected/');
      await Future<void>.delayed(Duration.zero);
      coordinator.beginLogout();
      await fixture.storage.clearAuthTokens();
      fixture.refresh.complete();

      await expectLater(request, throwsA(isA<ApiException>()));

      expect(fixture.storage.accessToken, isNull);
      expect(fixture.storage.refreshToken, isNull);
    },
  );

  test('a 401 during logout does not consume the refresh token', () async {
    final coordinator = AuthSessionCoordinator()..beginLogout();
    final fixture = _Fixture(coordinator: coordinator);

    await expectLater(
      fixture.client.get<dynamic>('/device-token/'),
      throwsA(isA<ApiException>()),
    );

    expect(fixture.refresh.callCount, 0);
    expect(fixture.storage.refreshToken, 'old-refresh');
  });
}

class _Fixture {
  _Fixture({
    bool refreshFails = false,
    bool refreshDelay = false,
    bool retryFails = false,
    int statusCode = 401,
    AuthSessionCoordinator? coordinator,
  }) : storage = _MemoryTokenStorage('old-access', 'old-refresh'),
       main = _ProtectedEndpointAdapter(
         statusCode: statusCode,
         retryFails: retryFails,
       ),
       refresh = _RefreshEndpointAdapter(
         fail: refreshFails,
         delay: refreshDelay,
       ) {
    final mainDio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    final refreshDio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    mainDio.httpClientAdapter = main;
    refreshDio.httpClientAdapter = refresh;
    client = ApiClient(
      dio: mainDio,
      refreshDio: refreshDio,
      tokenStorage: storage,
      sessionCoordinator: coordinator ?? AuthSessionCoordinator(),
    );
  }

  final _MemoryTokenStorage storage;
  final _ProtectedEndpointAdapter main;
  final _RefreshEndpointAdapter refresh;
  late final ApiClient client;
}

class _MemoryTokenStorage extends TokenStorage {
  _MemoryTokenStorage(this.accessToken, this.refreshToken);

  String? accessToken;
  String? refreshToken;

  @override
  Future<String?> readAccessToken() async => accessToken;

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }

  @override
  Future<void> clearAuthTokens() async {
    accessToken = null;
    refreshToken = null;
  }
}

class _ProtectedEndpointAdapter implements HttpClientAdapter {
  _ProtectedEndpointAdapter({this.statusCode = 401, this.retryFails = false});

  final int statusCode;
  final bool retryFails;
  int callCount = 0;
  String? retryAuthorization;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    callCount++;
    final retried = options.extra['authRetryAttempted'] == true;
    if (retried) {
      retryAuthorization = options.headers['Authorization'] as String?;
    }
    if (retried && !retryFails) {
      return _jsonResponse(<String, dynamic>{}, 200);
    }
    return _jsonResponse(<String, dynamic>{}, statusCode);
  }

  @override
  void close({bool force = false}) {}
}

class _RefreshEndpointAdapter implements HttpClientAdapter {
  _RefreshEndpointAdapter({this.fail = false, this.delay = false});

  final bool fail;
  final bool delay;
  final Completer<void> _completer = Completer<void>();
  int callCount = 0;

  void complete() {
    if (!_completer.isCompleted) _completer.complete();
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    callCount++;
    expect(options.path, '/api/auth/refresh/');
    expect(options.data, <String, dynamic>{'refresh': 'old-refresh'});
    expect(options.headers.containsKey('Authorization'), isFalse);
    if (delay) await _completer.future;
    if (fail) return _jsonResponse(<String, dynamic>{}, 401);
    return _jsonResponse(<String, dynamic>{
      'access': 'new-access',
      'refresh': 'new-refresh',
    }, 200);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonResponse(Map<String, dynamic> data, int statusCode) {
  return ResponseBody.fromString(
    jsonEncode(data),
    statusCode,
    headers: <String, List<String>>{
      Headers.contentTypeHeader: <String>[Headers.jsonContentType],
    },
  );
}
