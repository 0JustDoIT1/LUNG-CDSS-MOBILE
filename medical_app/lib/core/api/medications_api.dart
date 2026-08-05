import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_api.dart';

/// GET /api/medications/pending-setup/ 항목 하나 (치료계획 확정 · 복약설정 대기 환자).
class PendingMedicationSetupPatient {
  final String id;
  final String name;

  PendingMedicationSetupPatient({required this.id, required this.name});

  factory PendingMedicationSetupPatient.fromJson(Map<String, dynamic> json) {
    return PendingMedicationSetupPatient(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
    );
  }
}

/// GET /api/medications/pending-setup/ — 치료계획 확정 · 복약설정 대기 환자 목록.
Future<List<PendingMedicationSetupPatient>> fetchPendingMedicationSetupPatients(
    String accessToken) async {
  final uri = Uri.parse('$apiBaseUrl/api/medications/pending-setup/');

  http.Response response;
  try {
    response = await http.get(uri, headers: {'Authorization': 'Bearer $accessToken'});
  } catch (_) {
    throw ApiException('서버에 연결할 수 없어요. 네트워크 상태를 확인해주세요.');
  }

  if (response.statusCode != 200) {
    throw ApiException('복약설정 대기 목록을 불러오지 못했어요. (${response.statusCode})');
  }

  final list = jsonDecode(utf8.decode(response.bodyBytes)) as List;
  return list.cast<Map<String, dynamic>>().map(PendingMedicationSetupPatient.fromJson).toList();
}

/// POST /api/medications/schedules/ — 복약스케줄 생성.
Future<void> createMedicationSchedule({
  required String patientId,
  required String drugName,
  required String dosage,
  required int timesPerDay,
  required DateTime startDate,
  required String accessToken,
}) async {
  final uri = Uri.parse('$apiBaseUrl/api/medications/schedules/');
  String two(int n) => n.toString().padLeft(2, '0');
  final startDateStr = '${startDate.year}-${two(startDate.month)}-${two(startDate.day)}';

  http.Response response;
  try {
    response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'patient': patientId,
        'drug_name': drugName,
        'dosage': dosage,
        'times_per_day': timesPerDay,
        'start_date': startDateStr,
      }),
    );
  } catch (_) {
    throw ApiException('서버에 연결할 수 없어요. 네트워크 상태를 확인해주세요.');
  }

  if (response.statusCode != 200 && response.statusCode != 201) {
    throw ApiException('복약스케줄 저장에 실패했어요. (${response.statusCode})');
  }
}