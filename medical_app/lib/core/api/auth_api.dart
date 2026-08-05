import 'dart:convert';

import 'package:http/http.dart' as http;

/// LUNG-CDSS 백엔드 주소.
const String apiBaseUrl = 'https://lung-cdss.kro.kr';

/// 로그인 실패(잘못된 이메일/비밀번호 등) 시 던지는 예외.
/// message는 사용자에게 그대로 보여줄 수 있는 문구.
class ApiException implements Exception {
  final String message;
  ApiException(this.message);
}

/// 로그인 성공 결과. role은 'doctor'/'nurse'/'pathologist' 등 서버 원문 그대로.
class StaffLoginResult {
  final String access;
  final String refresh;
  final String role;
  final String name;

  StaffLoginResult({
    required this.access,
    required this.refresh,
    required this.role,
    required this.name,
  });
}

/// POST /api/auth/staff/login/ 호출.
/// 실패 시(401 등) ApiException을 던진다.
Future<StaffLoginResult> staffLogin({
  required String email,
  required String password,
}) async {
  final uri = Uri.parse('$apiBaseUrl/api/auth/staff/login/');

  http.Response response;
  try {
    response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
  } catch (_) {
    throw ApiException('서버에 연결할 수 없어요. 네트워크 상태를 확인해주세요.');
  }

  if (response.statusCode == 200) {
    final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return StaffLoginResult(
      access: body['access'] as String,
      refresh: body['refresh'] as String,
      role: body['role'] as String,
      name: body['name'] as String? ?? '',
    );
  }

  if (response.statusCode == 401 || response.statusCode == 400) {
    throw ApiException('이메일 또는 비밀번호가 올바르지 않아요.');
  }

  throw ApiException('로그인에 실패했어요. (${response.statusCode})');
}