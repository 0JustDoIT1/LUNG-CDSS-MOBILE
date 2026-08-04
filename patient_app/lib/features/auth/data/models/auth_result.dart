class AuthResult {
  const AuthResult._({
    this.accessToken,
    this.refreshToken,
    this.signupToken,
  });

  final String? accessToken;
  final String? refreshToken;
  final String? signupToken;

  bool get isExistingMember {
    return accessToken != null &&
        accessToken!.isNotEmpty &&
        refreshToken != null &&
        refreshToken!.isNotEmpty;
  }

  bool get isNewMember {
    return signupToken != null && signupToken!.isNotEmpty;
  }

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult._(
      accessToken: json['access']?.toString(),
      refreshToken: json['refresh']?.toString(),
      signupToken: json['signup_token']?.toString(),
    );
  }
}