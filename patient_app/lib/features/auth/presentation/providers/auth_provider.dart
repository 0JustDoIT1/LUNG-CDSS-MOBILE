import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/auth_state.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/mock_auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return MockAuthRepository();
});

final authProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<AuthState> {
  AuthRepository get _repository {
    return ref.read(authRepositoryProvider);
  }

  @override
  Future<AuthState> build() async {
    return _repository.getInitialAuthState();
  }

  Future<void> signInWithSocial({
    required String provider,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() {
      return _repository.signInWithSocial(
        provider: provider,
      );
    });
  }

  Future<void> sendVerificationCode({
    required String phoneNumber,
  }) async {
    await _repository.sendVerificationCode(
      phoneNumber: phoneNumber,
    );
  }

  Future<bool> verifyPhoneCode({
    required String phoneNumber,
    required String verificationCode,
  }) async {
    state = const AsyncLoading();

    final result = await AsyncValue.guard(() {
      return _repository.verifyPhoneCode(
        phoneNumber: phoneNumber,
        verificationCode: verificationCode,
      );
    });

    state = result;

    return result.hasValue;
  }

  Future<bool> authenticateWithBiometrics() async {
    return _repository.authenticateWithBiometrics();
  }

  Future<bool> verifyPin({
    required String pin,
  }) async {
    return _repository.verifyPin(
      pin: pin,
    );
  }

  Future<void> signOut() async {
    await _repository.signOut();
    state = const AsyncData(AuthState());
  }
}