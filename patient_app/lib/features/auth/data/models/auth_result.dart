class AuthResult {
  const AuthResult._({
    this.accessToken,
    this.refreshToken,
    this.signupToken,
    this.gender,
  });

  final String? accessToken;
  final String? refreshToken;
  final String? signupToken;
  final String? gender;

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
    final gender = json['gender'];
    if (gender != null && gender is! String) {
      throw const FormatException('gender 필드는 문자열 또는 null이어야 합니다.');
    }

    return AuthResult._(
      accessToken: json['access']?.toString(),
      refreshToken: json['refresh']?.toString(),
      signupToken: json['signup_token']?.toString(),
      gender: gender as String?,
    );
  }
}
