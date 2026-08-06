import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_role.dart';
import '../../../../data/models/auth_state.dart';
import '../../../../data/repositories/mock_auth_repository.dart';
import '../../../guardian/presentation/providers/guardian_data_provider.dart';
import 'auth_dependency_providers.dart';

final appLockRepositoryProvider = Provider<MockAuthRepository>((ref) {
  return MockAuthRepository();
});

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<AuthState> {
  StreamSubscription<void>? _sessionExpirationSubscription;

  @override
  Future<AuthState> build() async {
    final repository = ref.read(authRepositoryProvider);
    final deviceTokenService = ref.read(deviceTokenServiceProvider);
    final sessionCoordinator = ref.read(authSessionCoordinatorProvider);
    _sessionExpirationSubscription ??= sessionCoordinator.onExpired.listen((_) {
      state = const AsyncData(AuthState());
    });
    ref.onDispose(() => _sessionExpirationSubscription?.cancel());
    deviceTokenService.start();
    final role = await repository.restoreSessionRole();

    if (role != null) {
      sessionCoordinator.markAuthenticated();
      if (role == AuthRole.patient) {
        unawaited(deviceTokenService.tryRegisterCurrentDevice());
      }
      return const AuthState(
        isLoggedIn: true,
        isNewUser: false,
        isPhoneVerified: true,
      ).copyWith(role: role);
    }

    return const AuthState();
  }

  Future<void> signInWithSocial({required String provider}) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final socialToken = switch (provider) {
        'google' => ref.read(googleSignInServiceProvider).signInAndGetIdToken(),
        'kakao' =>
          ref.read(kakaoSignInServiceProvider).signInAndGetAccessToken(),
        _ => throw UnsupportedError('$provider 로그인은 아직 연결되지 않았습니다.'),
      };

      final repository = ref.read(authRepositoryProvider);

      final result = await repository.socialLogin(
        provider: provider,
        token: await socialToken,
      );

      if (result.isExistingMember) {
        ref.read(authSessionCoordinatorProvider).markAuthenticated();
        final deviceTokenService = ref.read(deviceTokenServiceProvider);
        deviceTokenService.start();
        unawaited(deviceTokenService.tryRegisterCurrentDevice());
        return const AuthState(
          isLoggedIn: true,
          isNewUser: false,
          isPhoneVerified: true,
          role: AuthRole.patient,
        );
      }

      if (result.isNewMember) {
        return const AuthState(
          isLoggedIn: false,
          isNewUser: true,
          isPhoneVerified: false,
        );
      }

      throw const FormatException('로그인 결과를 확인할 수 없습니다.');
    });
  }

  Future<bool> registerPatient({
    required DateTime birthDate,
    required String hospitalId,
    required String phoneNumber,
    required String gender,
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
        gender: gender,
      );

      ref.read(authSessionCoordinatorProvider).markAuthenticated();

      final deviceTokenService = ref.read(deviceTokenServiceProvider);
      deviceTokenService.start();
      unawaited(deviceTokenService.tryRegisterCurrentDevice());

      return const AuthState(
        isLoggedIn: true,
        isNewUser: false,
        isPhoneVerified: true,
        role: AuthRole.patient,
      );
    });

    state = result;

    return result.hasValue;
  }

  Future<bool> registerGuardian({
    required String inviteCode,
    required String name,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      await ref
          .read(guardianRepositoryProvider)
          .registerGuardian(inviteCode: inviteCode, name: name);
      ref.read(authSessionCoordinatorProvider).markAuthenticated();
      return const AuthState(
        isLoggedIn: true,
        isNewUser: false,
        isPhoneVerified: true,
        role: AuthRole.guardian,
      );
    });
    state = result;
    return result.hasValue;
  }

  Future<void> sendVerificationCode({required String phoneNumber}) async {
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

  Future<bool> verifyPin({required String pin}) async {
    final repository = ref.read(appLockRepositoryProvider);

    return repository.verifyPin(pin: pin);
  }

  Future<void> signOut() async {
    final repository = ref.read(authRepositoryProvider);
    final googleSignInService = ref.read(googleSignInServiceProvider);
    final deviceTokenService = ref.read(deviceTokenServiceProvider);
    final sessionCoordinator = ref.read(authSessionCoordinatorProvider);
    sessionCoordinator.beginLogout();

    try {
      try {
        await deviceTokenService.tryUnregisterCurrentDevice();
      } finally {
        try {
          await repository.logout();
        } finally {
          await googleSignInService.signOut();
        }
      }
    } finally {
      sessionCoordinator.finishLogout();
      state = const AsyncData(AuthState());
    }
  }
}
