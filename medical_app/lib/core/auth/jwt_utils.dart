import 'dart:convert';

/// JWT access 토큰(payload)에서 user_id 클레임을 꺼냄 (Django SimpleJWT 기본 클레임명).
/// 로그인 응답에 사용자 id가 따로 없어서, 채팅 등에서 "내 계정인지" 판단할 때 사용.
String? decodeJwtUserId(String accessToken) {
  final parts = accessToken.split('.');
  if (parts.length != 3) return null;

  try {
    final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))))
        as Map<String, dynamic>;
    return payload['user_id'] as String?;
  } catch (_) {
    return null;
  }
}
