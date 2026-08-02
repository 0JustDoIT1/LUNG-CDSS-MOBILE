class AuthState {
  const AuthState({
    this.isLoggedIn = false,
    this.isNewUser = true,
    this.isPhoneVerified = false,
    this.isAppLockEnabled = false,
    this.isBiometricAuthenticated = false,
  });

  final bool isLoggedIn;
  final bool isNewUser;
  final bool isPhoneVerified;
  final bool isAppLockEnabled;
  final bool isBiometricAuthenticated;

  AuthState copyWith({
    bool? isLoggedIn,
    bool? isNewUser,
    bool? isPhoneVerified,
    bool? isAppLockEnabled,
    bool? isBiometricAuthenticated,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isNewUser: isNewUser ?? this.isNewUser,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      isAppLockEnabled: isAppLockEnabled ?? this.isAppLockEnabled,
      isBiometricAuthenticated:
          isBiometricAuthenticated ?? this.isBiometricAuthenticated,
    );
  }
}