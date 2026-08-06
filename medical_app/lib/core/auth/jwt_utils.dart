import 'dart:convert';

Map<String, dynamic>? _decodeJwtPayload(String token) {
  final parts = token.split('.');
  if (parts.length != 3) return null;
  try {
    return jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))))
        as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}

/// JWT access 토큰(payload)에서 user_id 클레임을 꺼냄 (Django SimpleJWT 기본 클레임명).
/// 로그인 응답에 사용자 id가 따로 없어서, 채팅 등에서 "내 계정인지" 판단할 때 사용.
String? decodeJwtUserId(String accessToken) {
  return _decodeJwtPayload(accessToken)?['user_id'] as String?;
}

/// JWT의 exp 클레임(만료 시각, unix seconds)을 DateTime으로 꺼냄.
/// access 토큰 자동갱신 타이머를 걸 때, "언제 만료되는지" 알기 위해 사용.
DateTime? decodeJwtExpiry(String accessToken) {
  final exp = _decodeJwtPayload(accessToken)?['exp'];
  if (exp is! int) return null;
  return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
}
