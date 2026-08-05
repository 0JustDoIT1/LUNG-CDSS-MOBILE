import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/auth/token_storage.dart';
import 'package:patient_app/core/network/api_client.dart';
import 'package:patient_app/features/auth/data/device_identity_storage.dart';
import 'package:patient_app/features/auth/data/device_token_api.dart';
import 'package:patient_app/features/auth/data/device_token_repository.dart';
import 'package:patient_app/features/auth/data/device_token_service.dart';
import 'package:patient_app/features/auth/data/fcm_token_source.dart';
import 'package:patient_app/features/auth/data/models/device_token_registration.dart';

void main() {
  test(
    'registers a logged-in Android device and skips an identical token',
    () async {
      final repository = _FakeRepository();
      final identity = _FakeIdentityStorage();
      final service = _service(repository: repository, identity: identity);

      expect(await service.registerCurrentDevice(), isTrue);
      expect(await service.registerCurrentDevice(), isFalse);
      expect(repository.registrations, hasLength(1));
      expect(repository.registrations.single.platform, 'android');
      expect(repository.registrations.single.deviceId, 'installation-id');
    },
  );

  test('does not register while logged out', () async {
    final repository = _FakeRepository();
    final source = _FakeTokenSource(token: 'fcm-value');
    final service = _service(
      repository: repository,
      tokenSource: source,
      accessToken: null,
    );

    expect(await service.registerCurrentDevice(), isFalse);
    expect(source.getTokenCalls, 0);
    expect(repository.registrations, isEmpty);
  });

  test('skips Web, desktop, null and empty FCM tokens safely', () async {
    final repository = _FakeRepository();
    expect(
      await _service(
        repository: repository,
        platform: null,
      ).registerCurrentDevice(),
      isFalse,
    );
    expect(
      await _service(
        repository: repository,
        tokenSource: _FakeTokenSource(token: null),
      ).registerCurrentDevice(),
      isFalse,
    );
    expect(
      await _service(
        repository: repository,
        tokenSource: _FakeTokenSource(token: '   '),
      ).registerCurrentDevice(),
      isFalse,
    );
    expect(repository.registrations, isEmpty);
  });

  test('subscribes once and registers a refreshed token', () async {
    final repository = _FakeRepository();
    final source = _FakeTokenSource(token: null);
    final service = _service(repository: repository, tokenSource: source);

    service.start();
    service.start();
    expect(source.streamReads, 1);

    source.add('refreshed-token');
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(repository.registrations.single.fcmToken, 'refreshed-token');
    await service.dispose();
  });

  test(
    'registration failure is reported as false without clearing login',
    () async {
      final repository = _FakeRepository(failRegistration: true);
      final tokenStorage = _FakeTokenStorage('access-value');
      final service = _service(
        repository: repository,
        tokenStorage: tokenStorage,
      );

      expect(await service.tryRegisterCurrentDevice(), isFalse);
      expect(await tokenStorage.readAccessToken(), 'access-value');
    },
  );

  test(
    'unregisters only the stored device and clears only registration cache',
    () async {
      final repository = _FakeRepository();
      final identity = _FakeIdentityStorage(registeredToken: 'fcm-value');
      final service = _service(repository: repository, identity: identity);

      expect(await service.tryUnregisterCurrentDevice(), isTrue);
      expect(repository.unregisteredIds, ['installation-id']);
      expect(identity.deviceId, 'installation-id');
      expect(identity.registeredToken, isNull);
    },
  );
}

DeviceTokenService _service({
  required _FakeRepository repository,
  _FakeIdentityStorage? identity,
  _FakeTokenSource? tokenSource,
  _FakeTokenStorage? tokenStorage,
  String? platform = 'android',
  String? accessToken = 'access-value',
}) {
  return DeviceTokenService(
    repository,
    identity ?? _FakeIdentityStorage(),
    tokenStorage ?? _FakeTokenStorage(accessToken),
    tokenSource ?? _FakeTokenSource(token: 'fcm-value'),
    platform,
  );
}

class _FakeTokenSource implements FcmTokenSource {
  _FakeTokenSource({required this.token});
  final String? token;
  final StreamController<String> _controller = StreamController.broadcast();
  int getTokenCalls = 0;
  int streamReads = 0;

  @override
  Future<String?> getToken() async {
    getTokenCalls++;
    return token;
  }

  @override
  Stream<String> get onTokenRefresh {
    streamReads++;
    return _controller.stream;
  }

  void add(String value) => _controller.add(value);
}

class _FakeTokenStorage extends TokenStorage {
  _FakeTokenStorage(this.accessToken);
  final String? accessToken;

  @override
  Future<String?> readAccessToken() async => accessToken;
}

class _FakeIdentityStorage extends DeviceIdentityStorage {
  _FakeIdentityStorage({this.registeredToken});
  String deviceId = 'installation-id';
  String? registeredToken;

  @override
  Future<String> getOrCreateDeviceId() async => deviceId;

  @override
  Future<String?> readDeviceId() async => deviceId;

  @override
  Future<String?> readRegisteredFcmToken() async => registeredToken;

  @override
  Future<void> saveRegisteredFcmToken(String token) async {
    registeredToken = token;
  }

  @override
  Future<void> clearRegisteredFcmToken() async {
    registeredToken = null;
  }
}

class _FakeRepository extends DeviceTokenRepository {
  _FakeRepository({this.failRegistration = false})
    : super(DeviceTokenApi(ApiClient(dio: Dio())));
  final bool failRegistration;
  final List<DeviceTokenRegistration> registrations = [];
  final List<String> unregisteredIds = [];

  @override
  Future<void> registerDeviceToken(DeviceTokenRegistration registration) async {
    if (failRegistration) throw StateError('failed');
    registrations.add(registration);
  }

  @override
  Future<void> unregisterDeviceToken(String deviceId) async {
    unregisteredIds.add(deviceId);
  }
}
