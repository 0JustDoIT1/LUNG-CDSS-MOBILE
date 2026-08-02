import '../models/auth_state.dart';

abstract interface class AuthRepository {
  Future<AuthState> getInitialAuthState();

  Future<AuthState> signInWithSocial({
    required String provider,
  });

  Future<void> sendVerificationCode({
    required String phoneNumber,
  });

  Future<AuthState> verifyPhoneCode({
    required String phoneNumber,
    required String verificationCode,
  });

  Future<bool> authenticateWithBiometrics();

  Future<bool> verifyPin({
    required String pin,
  });

  Future<void> signOut();
}