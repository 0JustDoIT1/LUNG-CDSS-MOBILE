import '../../core/auth/auth_role.dart';

class AuthState {
  const AuthState({
    this.isLoggedIn = false,
    this.isNewUser = true,
    this.isPhoneVerified = false,
    this.isAppLockEnabled = false,
    this.isBiometricAuthenticated = false,
    this.role,
  });

  final bool isLoggedIn;
  final bool isNewUser;
  final bool isPhoneVerified;
  final bool isAppLockEnabled;
  final bool isBiometricAuthenticated;
  final AuthRole? role;

  AuthState copyWith({
    bool? isLoggedIn,
    bool? isNewUser,
    bool? isPhoneVerified,
    bool? isAppLockEnabled,
    bool? isBiometricAuthenticated,
    AuthRole? role,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isNewUser: isNewUser ?? this.isNewUser,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      isAppLockEnabled: isAppLockEnabled ?? this.isAppLockEnabled,
      isBiometricAuthenticated:
          isBiometricAuthenticated ?? this.isBiometricAuthenticated,
      role: role ?? this.role,
    );
  }
}
