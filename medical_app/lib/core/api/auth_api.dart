import 'dart:convert';

import 'package:http/http.dart' as http;
import '../../features/nurse/models/staff_patient.dart';

/// LUNG-CDSS 백엔드 주소.
const String apiBaseUrl = 'https://lung-cdss.kro.kr';

/// GET /api/auth/notifications/preferences/ — 카테고리별 on/off 목록.
/// PATCH /api/auth/notifications/preferences/update/ — 카테고리 하나씩 변경.
class NotificationPreference {
  final String category; // 'medication'|'appointment'|'chat'|'triage'|'case_review'
  final bool enabled;

  NotificationPreference({required this.category, required this.enabled});

  factory NotificationPreference.fromJson(Map<String, dynamic> json) {
    return NotificationPreference(
      category: json['category'] as String,
      enabled: json['enabled'] as bool,
    );
  }
}

Future<List<NotificationPreference>> fetchNotificationPreferences(String accessToken) async {
  final uri = Uri.parse('$apiBaseUrl/api/auth/notifications/preferences/');

  http.Response response;
  try {
    response = await http.get(uri, headers: {'Authorization': 'Bearer $accessToken'});
  } catch (_) {
    throw ApiException('서버에 연결할 수 없어요.');
  }

  if (response.statusCode != 200) {
    throw ApiException('알림설정을 불러오지 못했어요.');
  }

  final list = jsonDecode(utf8.decode(response.bodyBytes)) as List;
  return list.cast<Map<String, dynamic>>().map(NotificationPreference.fromJson).toList();
}

Future<void> updateNotificationPreference({
  required String accessToken,
  required String category,
  required bool enabled,
}) async {
  final uri = Uri.parse('$apiBaseUrl/api/auth/notifications/preferences/update/');

  final response = await http.patch(
    uri,
    headers: {'Authorization': 'Bearer $accessToken', 'Content-Type': 'application/json'},
    body: jsonEncode({'category': category, 'enabled': enabled}),
  );

  if (response.statusCode != 200) {
    throw ApiException('알림설정 저장에 실패했어요.');
  }
}

/// GET/PUT /api/auth/doctor/profile/ — 사진URL + 전문분야태그 + 진료과/면허번호.
/// 참고: department/licenseNumber는 조회만 가능하고 PUT으로 수정 불가.
/// 이름/소속병원은 이 API에 없음 (로그인응답의 name, GET /hospital/로 대체).
class DoctorProfileData {
  final String? photoUrl;
  final List<String> specialtyTags;
  final String department;
  final String licenseNumber;

  DoctorProfileData({
    required this.photoUrl,
    required this.specialtyTags,
    required this.department,
    required this.licenseNumber,
  });

  factory DoctorProfileData.fromJson(Map<String, dynamic> json) {
    return DoctorProfileData(
      photoUrl: json['photo_url'] as String?,
      specialtyTags: (json['specialty_tags'] as List?)?.cast<String>() ?? [],
      department: json['department'] as String? ?? '',
      licenseNumber: json['license_number'] as String? ?? '',
    );
  }
}

Future<DoctorProfileData> fetchDoctorProfile(String accessToken) async {
  final uri = Uri.parse('$apiBaseUrl/api/auth/doctor/profile/');

  http.Response response;
  try {
    response = await http.get(uri, headers: {'Authorization': 'Bearer $accessToken'});
  } catch (_) {
    throw ApiException('서버에 연결할 수 없어요. 네트워크 상태를 확인해주세요.');
  }

  if (response.statusCode != 200) {
    throw ApiException('프로필을 불러오지 못했어요. (${response.statusCode})');
  }

  final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  return DoctorProfileData.fromJson(body);
}

Future<void> updateDoctorProfile({
  required String accessToken,
  required List<String> specialtyTags,
  String? photoUrl,
}) async {
  final uri = Uri.parse('$apiBaseUrl/api/auth/doctor/profile/');

  http.Response response;
  try {
    response = await http.put(
      uri,
      headers: {'Authorization': 'Bearer $accessToken', 'Content-Type': 'application/json'},
      body: jsonEncode({'photo_url': photoUrl, 'specialty_tags': specialtyTags}),
    );
  } catch (_) {
    throw ApiException('서버에 연결할 수 없어요. 네트워크 상태를 확인해주세요.');
  }

  if (response.statusCode != 200) {
    throw ApiException('저장에 실패했어요. (${response.statusCode})');
  }
}

/// GET /api/auth/hospital/ — 로그인 없이도 조회 가능(현재는 병원 1곳만 존재).
class Hospital {
  final String id;
  final String name;

  Hospital({required this.id, required this.name});
}

/// accessToken을 넘기면 Authorization 헤더를 같이 보냄(로그인된 화면에서 호출할 때 사용).
/// 회원가입 화면처럼 아직 토큰이 없는 상태에서는 생략 가능.
Future<Hospital> fetchHospital([String? accessToken]) async {
  final uri = Uri.parse('$apiBaseUrl/api/auth/hospital/');

  http.Response response;
  try {
    response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      },
    );
  } catch (_) {
    throw ApiException('서버에 연결할 수 없어요. 네트워크 상태를 확인해주세요.');
  }

  if (response.statusCode != 200) {
    throw ApiException('병원 정보를 불러오지 못했어요. (${response.statusCode})');
  }

  try {
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    // 응답이 단일 객체가 아니라 배열이거나 { results: [...] } 형태로 올 수도 있어 방어적으로 처리.
    Map<String, dynamic> body;
    if (decoded is Map<String, dynamic> && decoded['results'] is List) {
      final results = decoded['results'] as List;
      if (results.isEmpty) throw const FormatException('병원 목록이 비어있어요.');
      body = results.first as Map<String, dynamic>;
    } else if (decoded is List) {
      if (decoded.isEmpty) throw const FormatException('병원 목록이 비어있어요.');
      body = decoded.first as Map<String, dynamic>;
    } else if (decoded is Map<String, dynamic>) {
      body = decoded;
    } else {
      throw const FormatException('알 수 없는 응답 형식이에요.');
    }
    return Hospital(id: body['id'] as String, name: body['name'] as String);
  } catch (e) {
    // ignore: avoid_print
    print('❗ fetchHospital parse error: $e / raw: ${utf8.decode(response.bodyBytes)}');
    throw ApiException('병원 정보를 불러오지 못했어요. (응답 형식 오류)');
  }
}

/// POST /api/auth/staff/signup/ — 성공 시 로그인과 동일하게 JWT 발급됨.
Future<StaffLoginResult> staffSignup({
  required String role, // 'doctor' | 'nurse'
  required String name,
  required String email,
  required String phoneNumber,
  required String password,
  required String passwordConfirm,
  required String hospitalId,
  required String department,
  String? licenseNumber,
}) async {
  final uri = Uri.parse('$apiBaseUrl/api/auth/staff/signup/');

  final body = <String, dynamic>{
    'role': role,
    'name': name,
    'email': email,
    'phone_number': phoneNumber,
    'password': password,
    'password_confirm': passwordConfirm,
    'hospital_id': hospitalId,
    'department': department,
  };
  if (licenseNumber != null && licenseNumber.isNotEmpty) {
    body['license_number'] = licenseNumber;
  }

  http.Response response;
  try {
    response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
  } catch (_) {
    throw ApiException('서버에 연결할 수 없어요. 네트워크 상태를 확인해주세요.');
  }

  if (response.statusCode == 201) {
    final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return StaffLoginResult(
      access: data['access'] as String,
      refresh: data['refresh'] as String,
      role: data['role'] as String? ?? role,
      name: data['name'] as String? ?? name,
    );
  }

  // 서버 에러 메시지 최대한 살려서 보여주기
  try {
    final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final error = data['error'] as Map<String, dynamic>?;
    if (error != null) {
      final details = error['details'] as Map<String, dynamic>?;
      if (details != null && details.isNotEmpty) {
        final firstKey = details.keys.first;
        final firstMsg = (details[firstKey] as List).first;
        throw ApiException('$firstMsg');
      }
      throw ApiException(error['message'] as String? ?? '가입에 실패했어요.');
    }
  } catch (e) {
    if (e is ApiException) rethrow;
  }
  throw ApiException('가입에 실패했어요. (${response.statusCode})');
}
/// POST /api/auth/refresh/ — refresh 토큰으로 새 access 토큰 발급받음.
/// 응답에 refresh가 새로 오면(로테이션) 그것도 같이 갱신, 없으면 기존 refresh 토큰 계속 사용.
class RefreshTokenResult {
  final String access;
  final String? refresh;

  RefreshTokenResult({required this.access, this.refresh});
}

Future<RefreshTokenResult> refreshAccessToken(String refreshToken) async {
  final uri = Uri.parse('$apiBaseUrl/api/auth/refresh/');

  http.Response response;
  try {
    response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh': refreshToken}),
    );
  } catch (_) {
    throw ApiException('서버에 연결할 수 없어요. 네트워크 상태를 확인해주세요.');
  }

  if (response.statusCode != 200) {
    throw ApiException('세션 갱신에 실패했어요. (${response.statusCode})');
  }

  final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  return RefreshTokenResult(
    access: data['access'] as String,
    refresh: data['refresh'] as String?,
  );
}

/// 로그인/가입 실패(잘못된 이메일/비밀번호, 검증오류 등) 시 던지는 예외.
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

/// GET /api/auth/staff/patients/ — 담당환자 목록(id/name/patient_number/birth_date).
Future<List<StaffPatient>> fetchStaffPatients(String accessToken) async {
  final uri = Uri.parse('$apiBaseUrl/api/auth/staff/patients/');

  http.Response response;
  try {
    response = await http.get(uri, headers: {'Authorization': 'Bearer $accessToken'});
  } catch (_) {
    throw ApiException('서버에 연결할 수 없어요. 네트워크 상태를 확인해주세요.');
  }

  if (response.statusCode != 200) {
    throw ApiException('환자 목록을 불러오지 못했어요. (${response.statusCode})');
  }

  final list = jsonDecode(utf8.decode(response.bodyBytes)) as List;
  return list.cast<Map<String, dynamic>>().map(StaffPatient.fromJson).toList();
}