import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 로그인 토큰(access/refresh) 암호화 저장소.
/// 기존엔 SharedPreferences(평문)에 저장했는데, 의료데이터 다루는 앱이라
/// flutter_secure_storage(iOS Keychain / Android Keystore)로 옮김.
class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  static const _keyAccessToken = 'session.accessToken';
  static const _keyRefreshToken = 'session.refreshToken';

  final FlutterSecureStorage _storage;

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
    await _storage.write(key: _keyRefreshToken, value: refreshToken);
  }

  Future<void> saveAccessToken(String accessToken) {
    return _storage.write(key: _keyAccessToken, value: accessToken);
  }

  Future<String?> readAccessToken() => _storage.read(key: _keyAccessToken);

  Future<String?> readRefreshToken() => _storage.read(key: _keyRefreshToken);

  Future<void> clear() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
  }
}
