class GuardianAuthResult {
  const GuardianAuthResult({
    required this.accessToken,
    required this.refreshToken,
    required this.role,
  });

  factory GuardianAuthResult.fromJson(Map<String, dynamic> json) {
    final access = json['access'];
    final refresh = json['refresh'];
    final role = json['role'];
    if (access is! String || access.isEmpty) {
      throw const FormatException('access 필드가 올바르지 않습니다.');
    }
    if (refresh is! String || refresh.isEmpty) {
      throw const FormatException('refresh 필드가 올바르지 않습니다.');
    }
    if (role != 'guardian') {
      throw const FormatException('보호자 역할 응답이 올바르지 않습니다.');
    }
    return GuardianAuthResult(
      accessToken: access,
      refreshToken: refresh,
      role: role as String,
    );
  }

  final String accessToken;
  final String refreshToken;
  final String role;
}
