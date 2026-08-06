class PatientQrToken {
  const PatientQrToken({
    required this.token,
    required this.expiresIn,
    required this.expiresAt,
  });

  factory PatientQrToken.fromJson(
    Map<String, dynamic> json, {
    required DateTime now,
  }) {
    final token = json['token'];
    final expiresIn = json['expires_in'];

    if (token is! String || token.trim().isEmpty) {
      throw const FormatException('token must be a non-empty string');
    }
    if (expiresIn is! num || expiresIn <= 0 || expiresIn % 1 != 0) {
      throw const FormatException('expires_in must be a positive integer');
    }

    final seconds = expiresIn.toInt();
    return PatientQrToken(
      token: token,
      expiresIn: seconds,
      expiresAt: now.add(Duration(seconds: seconds)),
    );
  }

  final String token;
  final int expiresIn;
  final DateTime expiresAt;
}
