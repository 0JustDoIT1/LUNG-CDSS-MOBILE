import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_api.dart';
import '../utils/datetime_utils.dart';

/// 증상체크 위험도 판정 결과 한 건.
/// 실제 API(GET /api/symptoms/checks/nurse-visible/) 응답 구조.
///
/// 판정 규칙(서버 룰엔진):
/// - RED: 객혈=다량 OR (호흡곤란=안정시에도 AND 발열=38도이상)
/// - YELLOW: 객혈=소량 OR 흉통=심함 OR 발열=37.5~38도
/// - GREEN: 그 외
/// RED는 간호사 열람설정 무시하고 무조건 노출됨.
class SymptomCheck {
  final String id;
  final String patientName;
  final DateTime checkedAt;
  final String riskLevel; // 'red' | 'yellow' | 'green'
  final bool visibleToNurse;
  final bool nurseReviewed;
  final DateTime? nurseReviewedAt;

  SymptomCheck({
    required this.id,
    required this.patientName,
    required this.checkedAt,
    required this.riskLevel,
    required this.visibleToNurse,
    required this.nurseReviewed,
    this.nurseReviewedAt,
  });

  bool get isRed => riskLevel == 'red';
  bool get isYellow => riskLevel == 'yellow';

  factory SymptomCheck.fromJson(Map<String, dynamic> json) {
    return SymptomCheck(
      id: json['id'] as String,
      patientName: json['patient_name'] as String? ?? '',
      checkedAt: parseServerDateTime(json['checked_at'] as String),
      riskLevel: json['risk_level'] as String? ?? 'green',
      visibleToNurse: json['visible_to_nurse'] as bool? ?? false,
      nurseReviewed: json['nurse_reviewed'] as bool? ?? false,
      nurseReviewedAt: json['nurse_reviewed_at'] != null
          ? parseServerDateTime(json['nurse_reviewed_at'] as String)
          : null,
    );
  }
}

/// GET /api/symptoms/checks/nurse-visible/
Future<List<SymptomCheck>> fetchNurseVisibleSymptomChecks(String accessToken) async {
  http.Response response;
  try {
    response = await http.get(
      Uri.parse('$apiBaseUrl/api/symptoms/checks/nurse-visible/'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
  } catch (_) {
    throw ApiException('서버에 연결할 수 없어요. 네트워크 상태를 확인해주세요.');
  }

  if (response.statusCode != 200) {
    throw ApiException('불러오지 못했어요. (${response.statusCode})');
  }

  final list = jsonDecode(utf8.decode(response.bodyBytes)) as List;
  return list.cast<Map<String, dynamic>>().map(SymptomCheck.fromJson).toList();
}

/// POST /api/symptoms/checks/{check_id}/review/ — 간호사 확인처리.
Future<void> reviewSymptomCheck(String checkId, String accessToken) async {
  final response = await http.post(
    Uri.parse('$apiBaseUrl/api/symptoms/checks/$checkId/review/'),
    headers: {'Authorization': 'Bearer $accessToken'},
  );
  if (response.statusCode != 200 && response.statusCode != 201) {
    throw ApiException('확인처리에 실패했어요.');
  }
}