import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/token_storage.dart';
import '../../../../core/network/api_client.dart';
import '../../data/auth_api.dart';
import '../../data/auth_repository.dart';
import '../../data/device_identity_storage.dart';
import '../../data/device_token_api.dart';
import '../../data/device_token_repository.dart';
import '../../data/device_token_service.dart';
import '../../data/fcm_token_source.dart';
import '../../data/google_sign_in_service.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);

  return ApiClient(tokenStorage: tokenStorage);
});

final authApiProvider = Provider<AuthApi>((ref) {
  final apiClient = ref.watch(apiClientProvider);

  return AuthApi(apiClient: apiClient);
});

final googleSignInServiceProvider = Provider<GoogleSignInService>((ref) {
  return GoogleSignInService();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final authApi = ref.watch(authApiProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);

  return AuthRepository(authApi: authApi, tokenStorage: tokenStorage);
});

final deviceIdentityStorageProvider = Provider<DeviceIdentityStorage>((ref) {
  return DeviceIdentityStorage();
});

final fcmTokenSourceProvider = Provider<FcmTokenSource>((ref) {
  return FirebaseMessagingTokenSource();
});

final deviceTokenApiProvider = Provider<DeviceTokenApi>((ref) {
  return DeviceTokenApi(ref.watch(apiClientProvider));
});

final deviceTokenRepositoryProvider = Provider<DeviceTokenRepository>((ref) {
  return DeviceTokenRepository(ref.watch(deviceTokenApiProvider));
});

final deviceRegistrationPlatformProvider = Provider<String?>((ref) {
  if (kIsWeb) return null;
  return switch (defaultTargetPlatform) {
    TargetPlatform.android => 'android',
    TargetPlatform.iOS => 'ios',
    _ => null,
  };
});

final deviceTokenServiceProvider = Provider<DeviceTokenService>((ref) {
  final service = DeviceTokenService(
    ref.watch(deviceTokenRepositoryProvider),
    ref.watch(deviceIdentityStorageProvider),
    ref.watch(tokenStorageProvider),
    ref.watch(fcmTokenSourceProvider),
    ref.watch(deviceRegistrationPlatformProvider),
  );
  ref.onDispose(() => unawaited(service.dispose()));
  return service;
});
