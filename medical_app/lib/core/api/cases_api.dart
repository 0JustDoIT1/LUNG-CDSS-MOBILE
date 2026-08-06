import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_api.dart';
import '../../features/doctor/models/case_review_log.dart';
import '../../features/doctor/models/review_case.dart';

/// GET /api/cases/ — pending_review/confirmed만 남기고 나머지(uploaded/processing/failed)는 제외.
Future<List<ReviewCase>> fetchCases(String accessToken) async {
  final uri = Uri.parse('$apiBaseUrl/api/cases/');

  http.Response response;
  try {
    response = await http.get(uri, headers: {'Authorization': 'Bearer $accessToken'});
  } catch (_) {
    throw ApiException('서버에 연결할 수 없어요. 네트워크 상태를 확인해주세요.');
  }

  if (response.statusCode != 200) {
    throw ApiException('케이스 목록을 불러오지 못했어요. (${response.statusCode})');
  }

  final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  final results = (body['results'] as List).cast<Map<String, dynamic>>();

  return results
      .where((json) => json['status'] == 'pending_review' || json['status'] == 'confirmed')
      .map(ReviewCase.fromJson)
      .toList();
}

/// GET /api/cases/?search=이름 — 환자명으로 검색(status 필터 없이 전체 상태 포함).
/// 환자 상세화면에서 "최근 확정 아형" 조회 용도로 사용.
Future<List<ReviewCase>> fetchCasesByPatientName(String patientName, String accessToken) async {
  final uri = Uri.parse('$apiBaseUrl/api/cases/').replace(queryParameters: {'search': patientName});

  http.Response response;
  try {
    response = await http.get(uri, headers: {'Authorization': 'Bearer $accessToken'});
  } catch (_) {
    throw ApiException('서버에 연결할 수 없어요. 네트워크 상태를 확인해주세요.');
  }

  if (response.statusCode != 200) {
    throw ApiException('케이스 목록을 불러오지 못했어요. (${response.statusCode})');
  }

  final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  final results = (body['results'] as List).cast<Map<String, dynamic>>();
  return results.map(ReviewCase.fromJson).toList();
}

/// GET /api/cases/{id}/ — 상세조회. 목록엔 없는 slide_thumbnail_url/heatmap_url 포함.
Future<ReviewCase> fetchCaseDetail(String caseId, String accessToken) async {
  final uri = Uri.parse('$apiBaseUrl/api/cases/$caseId/');

  http.Response response;
  try {
    response = await http.get(uri, headers: {'Authorization': 'Bearer $accessToken'});
  } catch (_) {
    throw ApiException('서버에 연결할 수 없어요. 네트워크 상태를 확인해주세요.');
  }

  if (response.statusCode != 200) {
    throw ApiException('케이스 상세를 불러오지 못했어요. (${response.statusCode})');
  }

  final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  return ReviewCase.fromJson(body);
}

/// GET /api/cases/{case_id}/review-log/ — 검토 이력(승인/반려 기록) 목록.
Future<List<CaseReviewLog>> fetchCaseReviewLogs(String caseId, String accessToken) async {
  final uri = Uri.parse('$apiBaseUrl/api/cases/$caseId/review-log/');

  http.Response response;
  try {
    response = await http.get(uri, headers: {'Authorization': 'Bearer $accessToken'});
  } catch (_) {
    throw ApiException('서버에 연결할 수 없어요. 네트워크 상태를 확인해주세요.');
  }

  if (response.statusCode != 200) {
    throw ApiException('검토 이력을 불러오지 못했어요. (${response.statusCode})');
  }

  final decoded = jsonDecode(utf8.decode(response.bodyBytes));
  final list = decoded is Map<String, dynamic> ? decoded['results'] as List : decoded as List;
  return list
      .cast<Map<String, dynamic>>()
      .map((json) => CaseReviewLog.fromJson(caseId, json))
      .toList();
}

/// POST /api/cases/{case_id}/favorite/ — 즐겨찾기 토글.
Future<void> toggleCaseFavorite(String caseId, String accessToken) async {
  final uri = Uri.parse('$apiBaseUrl/api/cases/$caseId/favorite/');
  final response = await http.post(uri, headers: {'Authorization': 'Bearer $accessToken'});

  if (response.statusCode != 200) {
    throw ApiException('즐겨찾기 처리에 실패했어요.');
  }
}

/// POST /api/cases/{case_id}/review/ — 승인(action=confirm) 또는 반려/수정(action=edit).
/// edit일 땐 finalSubtype/finalNote 필수.
Future<void> reviewCase({
  required String caseId,
  required String accessToken,
  required String action, // 'confirm' | 'edit'
  String? finalSubtype, // 'LUAD' | 'LUSC'
  String? finalNote,
}) async {
  final uri = Uri.parse('$apiBaseUrl/api/cases/$caseId/review/');
  final body = <String, dynamic>{'action': action};
  if (finalSubtype != null) body['final_subtype'] = finalSubtype;
  if (finalNote != null) body['final_note'] = finalNote;

  final response = await http.post(
    uri,
    headers: {'Authorization': 'Bearer $accessToken', 'Content-Type': 'application/json'},
    body: jsonEncode(body),
  );

  if (response.statusCode != 200) {
    throw ApiException('처리에 실패했어요. (${response.statusCode})');
  }
}