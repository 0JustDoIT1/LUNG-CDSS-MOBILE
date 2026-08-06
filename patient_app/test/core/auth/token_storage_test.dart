import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/auth/token_storage.dart';
import 'package:patient_app/core/auth/auth_role.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  test('saves and reads access and refresh tokens together', () async {
    final storage = TokenStorage();

    await storage.saveTokens(accessToken: 'access', refreshToken: 'refresh');

    expect(await storage.readAccessToken(), 'access');
    expect(await storage.readRefreshToken(), 'refresh');
  });

  test('rejects empty tokens without storing either token', () async {
    final storage = TokenStorage();

    await expectLater(
      storage.saveTokens(accessToken: '', refreshToken: 'refresh'),
      throwsA(isA<FormatException>()),
    );

    expect(await storage.readAccessToken(), isNull);
    expect(await storage.readRefreshToken(), isNull);
  });

  test('clearAuthTokens removes all authentication tokens', () async {
    final storage = TokenStorage();
    await storage.saveSession(
      accessToken: 'access',
      refreshToken: 'refresh',
      role: AuthRole.guardian,
    );
    await storage.saveSignupToken('signup');

    await storage.clearAuthTokens();

    expect(await storage.readAccessToken(), isNull);
    expect(await storage.readRefreshToken(), isNull);
    expect(await storage.readSignupToken(), isNull);
    expect(await storage.readRole(), isNull);
  });

  test('saves and restores the session role with both tokens', () async {
    final storage = TokenStorage();
    await storage.saveSession(
      accessToken: 'access',
      refreshToken: 'refresh',
      role: AuthRole.guardian,
    );

    expect(await storage.readAccessToken(), 'access');
    expect(await storage.readRefreshToken(), 'refresh');
    expect(await storage.readRole(), AuthRole.guardian);
  });
}
