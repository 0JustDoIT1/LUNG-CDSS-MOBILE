import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/auth/auth_role.dart';
import 'package:patient_app/core/auth/token_storage.dart';
import 'package:patient_app/core/network/api_client.dart';
import 'package:patient_app/features/auth/data/auth_api.dart';
import 'package:patient_app/features/auth/data/auth_repository.dart';
import 'package:patient_app/features/auth/data/device_identity_storage.dart';
import 'package:patient_app/features/auth/data/device_token_api.dart';
import 'package:patient_app/features/auth/data/device_token_repository.dart';
import 'package:patient_app/features/auth/data/device_token_service.dart';
import 'package:patient_app/features/auth/data/fcm_token_source.dart';
import 'package:patient_app/features/auth/data/kakao_sign_in_service.dart';
import 'package:patient_app/features/auth/data/models/auth_result.dart';
import 'package:patient_app/features/auth/presentation/providers/auth_dependency_providers.dart';
import 'package:patient_app/features/auth/presentation/providers/auth_provider.dart';

void main() {
  test(
    'passes Kakao OAuth access token to repository for existing user',
    () async {
      final repository = _KakaoAuthRepository(
        AuthResult.fromJson(<String, dynamic>{
          'access': 'patient-access',
          'refresh': 'patient-refresh',
        }),
      );
      final container = _container(repository);
      addTearDown(container.dispose);
      await container.read(authProvider.future);

      await container
          .read(authProvider.notifier)
          .signInWithSocial(provider: 'kakao');

      expect(repository.provider, 'kakao');
      expect(repository.token, 'kakao-oauth-access-token');
      expect(container.read(authProvider).requireValue.isLoggedIn, isTrue);
      expect(container.read(authProvider).requireValue.role, AuthRole.patient);
    },
  );

  test('keeps the existing new-user flow for Kakao', () async {
    final repository = _KakaoAuthRepository(
      AuthResult.fromJson(<String, dynamic>{'signup_token': 'signup-token'}),
    );
    final container = _container(repository);
    addTearDown(container.dispose);
    await container.read(authProvider.future);

    await container
        .read(authProvider.notifier)
        .signInWithSocial(provider: 'kakao');

    final state = container.read(authProvider).requireValue;
    expect(state.isLoggedIn, isFalse);
    expect(state.isNewUser, isTrue);
    expect(state.isPhoneVerified, isFalse);
  });
}

ProviderContainer _container(_KakaoAuthRepository repository) {
  return ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(repository),
      kakaoSignInServiceProvider.overrideWithValue(_FakeKakaoService()),
      deviceTokenServiceProvider.overrideWithValue(_NoopDeviceTokenService()),
    ],
  );
}

class _KakaoAuthRepository extends AuthRepository {
  _KakaoAuthRepository(this.result)
    : super(
        authApi: AuthApi(apiClient: ApiClient(dio: Dio())),
        tokenStorage: TokenStorage(),
      );

  final AuthResult result;
  String? provider;
  String? token;

  @override
  Future<AuthRole?> restoreSessionRole() async => null;

  @override
  Future<AuthResult> socialLogin({
    required String provider,
    required String token,
  }) async {
    this.provider = provider;
    this.token = token;
    return result;
  }
}

class _FakeKakaoService extends KakaoSignInService {
  @override
  Future<String> signInAndGetAccessToken() async => 'kakao-oauth-access-token';
}

class _NoopDeviceTokenService extends DeviceTokenService {
  _NoopDeviceTokenService()
    : super(
        DeviceTokenRepository(DeviceTokenApi(ApiClient(dio: Dio()))),
        DeviceIdentityStorage(),
        TokenStorage(),
        _EmptyTokenSource(),
        null,
      );

  @override
  void start() {}

  @override
  Future<bool> tryRegisterCurrentDevice() async => true;
}

class _EmptyTokenSource implements FcmTokenSource {
  @override
  Future<String?> getToken() async => null;

  @override
  Stream<String> get onTokenRefresh => const Stream<String>.empty();
}
