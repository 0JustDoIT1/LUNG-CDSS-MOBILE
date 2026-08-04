import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/auth_state.dart';
import '../../../../data/repositories/mock_auth_repository.dart';
import 'auth_dependency_providers.dart';

final appLockRepositoryProvider = Provider<MockAuthRepository>((ref) {
  return MockAuthRepository();
});

final authProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final repository = ref.read(authRepositoryProvider);
    final hasAccessToken = await repository.hasAccessToken();

    if (hasAccessToken) {
      return const AuthState(
        isLoggedIn: true,
        isNewUser: false,
        isPhoneVerified: true,
      );
    }

    return const AuthState();
  }

  Future<void> signInWithSocial({
    required String provider,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      if (provider != 'google') {
        throw UnsupportedError(
          '$provider 로그인은 아직 연결되지 않았습니다.',
        );
      }

      final googleSignInService = ref.read(
        googleSignInServiceProvider,
      );

      final idToken =
          await googleSignInService.signInAndGetIdToken();

      final repository = ref.read(authRepositoryProvider);

      final result = await repository.socialLogin(
        provider: provider,
        token: idToken,
      );

      if (result.isExistingMember) {
        return const AuthState(
          isLoggedIn: true,
          isNewUser: false,
          isPhoneVerified: true,
        );
      }

      if (result.isNewMember) {
        return const AuthState(
          isLoggedIn: false,
          isNewUser: true,
          isPhoneVerified: false,
        );
      }

      throw const FormatException(
        '로그인 결과를 확인할 수 없습니다.',
      );
    });
  }

  Future<bool> registerPatient({
    required DateTime birthDate,
    required String hospitalId,
    required String phoneNumber,
  }) async {
    state = const AsyncLoading();

    final result = await AsyncValue.guard(() async {
      final repository = ref.read(authRepositoryProvider);

      final formattedBirthDate =
          '${birthDate.year.toString().padLeft(4, '0')}-'
          '${birthDate.month.toString().padLeft(2, '0')}-'
          '${birthDate.day.toString().padLeft(2, '0')}';

      await repository.registerPatient(
        birthDate: formattedBirthDate,
        hospitalId: hospitalId,
        phoneNumber: phoneNumber,
      );

      return const AuthState(
        isLoggedIn: true,
        isNewUser: false,
        isPhoneVerified: true,
      );
    });

    state = result;

    return result.hasValue;
  }

  Future<void> sendVerificationCode({
    required String phoneNumber,
  }) async {
    // SMS 인증 기능은 사용하지 않습니다.
  }

  Future<bool> verifyPhoneCode({
    required String phoneNumber,
    required String verificationCode,
  }) async {
    return false;
  }

  Future<bool> authenticateWithBiometrics() async {
    final repository = ref.read(appLockRepositoryProvider);
    return repository.authenticateWithBiometrics();
  }

  Future<bool> verifyPin({
    required String pin,
  }) async {
    final repository = ref.read(appLockRepositoryProvider);

    return repository.verifyPin(
      pin: pin,
    );
  }

  Future<void> signOut() async {
    final repository = ref.read(authRepositoryProvider);
    final googleSignInService = ref.read(
      googleSignInServiceProvider,
    );

    try {
      await repository.logout();
      await googleSignInService.signOut();
    } finally {
      state = const AsyncData(AuthState());
    }
  }
}