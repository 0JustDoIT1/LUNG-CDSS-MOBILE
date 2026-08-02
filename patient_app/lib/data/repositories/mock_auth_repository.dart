import '../models/auth_state.dart';
import 'auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  AuthState _state = const AuthState();

  @override
  Future<AuthState> getInitialAuthState() async {
    await Future<void>.delayed(
      const Duration(milliseconds: 500),
    );

    return _state;
  }

  @override
  Future<AuthState> signInWithSocial({
    required String provider,
  }) async {
    await Future<void>.delayed(
      const Duration(milliseconds: 700),
    );

    _state = _state.copyWith(
      isLoggedIn: true,
      isNewUser: true,
    );

    return _state;
  }

  @override
  Future<void> sendVerificationCode({
    required String phoneNumber,
  }) async {
    await Future<void>.delayed(
      const Duration(milliseconds: 700),
    );
  }

  @override
  Future<AuthState> verifyPhoneCode({
    required String phoneNumber,
    required String verificationCode,
  }) async {
    await Future<void>.delayed(
      const Duration(milliseconds: 700),
    );

    if (verificationCode != '123456') {
      throw Exception('인증번호가 일치하지 않습니다.');
    }

    _state = _state.copyWith(
      isPhoneVerified: true,
      isNewUser: false,
    );

    return _state;
  }

  @override
  Future<bool> authenticateWithBiometrics() async {
    await Future<void>.delayed(
      const Duration(milliseconds: 500),
    );

    return true;
  }

  @override
  Future<bool> verifyPin({
    required String pin,
  }) async {
    await Future<void>.delayed(
      const Duration(milliseconds: 500),
    );

    return pin == '1234';
  }

  @override
  Future<void> signOut() async {
    await Future<void>.delayed(
      const Duration(milliseconds: 300),
    );

    _state = const AuthState();
  }
}