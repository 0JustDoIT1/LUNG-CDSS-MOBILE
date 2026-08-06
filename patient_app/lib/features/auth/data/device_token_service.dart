import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/auth/token_storage.dart';
import 'device_identity_storage.dart';
import 'device_token_repository.dart';
import 'fcm_token_source.dart';
import 'models/device_token_registration.dart';

class DeviceTokenService {
  DeviceTokenService(
    this._repository,
    this._identityStorage,
    this._tokenStorage,
    this._tokenSource,
    this._platform,
  );

  final DeviceTokenRepository _repository;
  final DeviceIdentityStorage _identityStorage;
  final TokenStorage _tokenStorage;
  final FcmTokenSource _tokenSource;
  final String? _platform;

  StreamSubscription<String>? _refreshSubscription;
  Future<bool>? _registrationInFlight;

  void start() {
    if (_refreshSubscription != null || _platform == null) return;
    _refreshSubscription = _tokenSource.onTokenRefresh.listen(
      (token) {
        debugPrint('[DeviceToken] FCM token refreshed; registering device');
        unawaited(tryRegisterToken(token));
      },
      onError: (Object error) {
        debugPrint('[DeviceToken] FCM token refresh stream failed: $error');
      },
    );
  }

  Future<bool> tryRegisterCurrentDevice() async {
    try {
      return await registerCurrentDevice();
    } catch (error) {
      debugPrint('[DeviceToken] Current device registration failed: $error');
      return false;
    }
  }

  Future<bool> registerCurrentDevice() async {
    if (_platform == null || !await _hasAccessToken()) return false;
    final token = await _tokenSource.getToken();
    if (token == null || token.trim().isEmpty) return false;
    return registerToken(token);
  }

  Future<bool> tryRegisterToken(String token) async {
    try {
      if (_platform == null || !await _hasAccessToken()) return false;
      return await registerToken(token);
    } catch (error) {
      debugPrint('[DeviceToken] Refreshed token registration failed: $error');
      return false;
    }
  }

  Future<bool> registerToken(String token) async {
    if (_platform == null || token.trim().isEmpty) return false;
    final pending = _registrationInFlight;
    if (pending != null) await pending;

    final operation = _performRegistration(token);
    _registrationInFlight = operation;
    try {
      return await operation;
    } finally {
      if (identical(_registrationInFlight, operation)) {
        _registrationInFlight = null;
      }
    }
  }

  Future<bool> _performRegistration(String token) async {
    final previousToken = await _identityStorage.readRegisteredFcmToken();
    if (previousToken == token) return false;

    final deviceId = await _identityStorage.getOrCreateDeviceId();
    await _repository.registerDeviceToken(
      DeviceTokenRegistration(
        fcmToken: token,
        platform: _platform!,
        deviceId: deviceId,
      ),
    );
    await _identityStorage.saveRegisteredFcmToken(token);
    return true;
  }

  Future<bool> tryUnregisterCurrentDevice() async {
    try {
      final deviceId = await _identityStorage.readDeviceId();
      if (deviceId == null || deviceId.isEmpty) return false;
      await _repository.unregisterDeviceToken(deviceId);
      return true;
    } catch (_) {
      return false;
    } finally {
      await _identityStorage.clearRegisteredFcmToken();
    }
  }

  Future<bool> _hasAccessToken() async {
    final accessToken = await _tokenStorage.readAccessToken();
    return accessToken != null && accessToken.isNotEmpty;
  }

  Future<void> dispose() async {
    await _refreshSubscription?.cancel();
    _refreshSubscription = null;
  }
}
