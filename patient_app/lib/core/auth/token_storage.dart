import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth_role.dart';

class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _signupTokenKey = 'signup_token';
  static const String _roleKey = 'auth_role';

  final FlutterSecureStorage _storage;

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    if (accessToken.isEmpty || refreshToken.isEmpty) {
      throw const FormatException(
        'Access and refresh tokens must not be empty.',
      );
    }

    try {
      await _storage.write(key: _accessTokenKey, value: accessToken);
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    } catch (_) {
      await Future.wait([
        _storage.delete(key: _accessTokenKey),
        _storage.delete(key: _refreshTokenKey),
      ]);
      rethrow;
    }
  }

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required AuthRole role,
  }) async {
    if (accessToken.isEmpty || refreshToken.isEmpty) {
      throw const FormatException(
        'Access and refresh tokens must not be empty.',
      );
    }
    try {
      await _storage.write(key: _accessTokenKey, value: accessToken);
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
      await _storage.write(key: _roleKey, value: role.storageValue);
    } catch (_) {
      await clearAuthTokens();
      rethrow;
    }
  }

  Future<void> saveSignupToken(String signupToken) async {
    await _storage.write(key: _signupTokenKey, value: signupToken);
  }

  Future<String?> readAccessToken() {
    return _storage.read(key: _accessTokenKey);
  }

  Future<String?> readRefreshToken() {
    return _storage.read(key: _refreshTokenKey);
  }

  Future<String?> readSignupToken() {
    return _storage.read(key: _signupTokenKey);
  }

  Future<AuthRole?> readRole() async {
    return AuthRole.fromStorage(await _storage.read(key: _roleKey));
  }

  Future<void> deleteSignupToken() {
    return _storage.delete(key: _signupTokenKey);
  }

  Future<void> clearAuthTokens() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _signupTokenKey),
      _storage.delete(key: _roleKey),
    ]);
  }
}
