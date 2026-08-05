import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/auth/token_storage.dart';
import 'package:patient_app/core/network/api_client.dart';
import 'package:patient_app/features/auth/data/auth_api.dart';
import 'package:patient_app/features/auth/data/auth_repository.dart';
import 'package:patient_app/features/auth/data/device_identity_storage.dart';
import 'package:patient_app/features/auth/data/device_token_api.dart';
import 'package:patient_app/features/auth/data/device_token_repository.dart';
import 'package:patient_app/features/auth/data/device_token_service.dart';
import 'package:patient_app/features/auth/data/fcm_token_source.dart';
import 'package:patient_app/features/auth/data/google_sign_in_service.dart';
import 'package:patient_app/features/auth/data/models/auth_result.dart';
import 'package:patient_app/features/auth/presentation/providers/auth_dependency_providers.dart';
import 'package:patient_app/features/auth/presentation/providers/auth_provider.dart';

void main() {
  test('registers the device after existing-member login succeeds', () async {
    final events = <String>[];
    final container = _container(events: events);
    addTearDown(container.dispose);
    await container.read(authProvider.future);

    await container
        .read(authProvider.notifier)
        .signInWithSocial(provider: 'google');

    expect(events, containsAllInOrder(['social-login', 'device-register']));
    expect(container.read(authProvider).requireValue.isLoggedIn, isTrue);
  });

  test(
    'unregisters before logout and continues when unregister fails',
    () async {
      final events = <String>[];
      final container = _container(events: events, unregisterResult: false);
      addTearDown(container.dispose);
      await container.read(authProvider.future);

      await container.read(authProvider.notifier).signOut();

      expect(
        events,
        containsAllInOrder(['device-unregister', 'logout', 'google-sign-out']),
      );
      expect(container.read(authProvider).requireValue.isLoggedIn, isFalse);
    },
  );

  test('logout still runs server and Google cleanup when FCM throws', () async {
    final events = <String>[];
    final container = _container(events: events, unregisterThrows: true);
    addTearDown(container.dispose);
    await container.read(authProvider.future);

    await expectLater(
      container.read(authProvider.notifier).signOut(),
      throwsA(isA<StateError>()),
    );

    expect(
      events,
      containsAllInOrder(['device-unregister', 'logout', 'google-sign-out']),
    );
    expect(container.read(authProvider).requireValue.isLoggedIn, isFalse);
  });
}

ProviderContainer _container({
  required List<String> events,
  bool unregisterResult = true,
  bool unregisterThrows = false,
}) {
  final repository = _FakeAuthRepository(events);
  final deviceService = _FakeDeviceTokenService(
    events,
    unregisterResult: unregisterResult,
    unregisterThrows: unregisterThrows,
  );
  return ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(repository),
      googleSignInServiceProvider.overrideWithValue(_FakeGoogleService(events)),
      deviceTokenServiceProvider.overrideWithValue(deviceService),
    ],
  );
}

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository(this.events)
    : super(
        authApi: AuthApi(apiClient: ApiClient(dio: Dio())),
        tokenStorage: TokenStorage(),
      );
  final List<String> events;

  @override
  Future<bool> hasAccessToken() async => false;

  @override
  Future<AuthResult> socialLogin({
    required String provider,
    required String token,
  }) async {
    events.add('social-login');
    return AuthResult.fromJson({'access': 'access', 'refresh': 'refresh'});
  }

  @override
  Future<void> logout() async {
    events.add('logout');
  }
}

class _FakeGoogleService extends GoogleSignInService {
  _FakeGoogleService(this.events);
  final List<String> events;

  @override
  Future<String> signInAndGetIdToken() async => 'id-token';

  @override
  Future<void> signOut() async {
    events.add('google-sign-out');
  }
}

class _FakeDeviceTokenService extends DeviceTokenService {
  _FakeDeviceTokenService(
    this.events, {
    required this.unregisterResult,
    this.unregisterThrows = false,
  }) : super(
         DeviceTokenRepository(DeviceTokenApi(ApiClient(dio: Dio()))),
         DeviceIdentityStorage(),
         TokenStorage(),
         _EmptyTokenSource(),
         null,
       );
  final List<String> events;
  final bool unregisterResult;
  final bool unregisterThrows;

  @override
  void start() {}

  @override
  Future<bool> tryRegisterCurrentDevice() async {
    events.add('device-register');
    return true;
  }

  @override
  Future<bool> tryUnregisterCurrentDevice() async {
    events.add('device-unregister');
    if (unregisterThrows) throw StateError('FCM unregister failed');
    return unregisterResult;
  }
}

class _EmptyTokenSource implements FcmTokenSource {
  @override
  Future<String?> getToken() async => null;

  @override
  Stream<String> get onTokenRefresh => const Stream<String>.empty();
}
