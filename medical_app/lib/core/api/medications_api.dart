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
/// times는 "HH:MM" 형식 복용시각 목록(예: ["09:00", "18:00"]) — times_per_day 필드로 전송됨.
Future<void> createMedicationSchedule({
  required String patientId,
  required String drugName,
  required String dosage,
  required List<String> times,
  required DateTime startDate,
  required DateTime endDate,
  required String accessToken,
}) async {
  final uri = Uri.parse('$apiBaseUrl/api/medications/schedules/');
  String two(int n) => n.toString().padLeft(2, '0');
  String dateStr(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';

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
        'times_per_day': times,
        'start_date': dateStr(startDate),
        'end_date': dateStr(endDate),
      }),
    );
  } catch (_) {
    throw ApiException('서버에 연결할 수 없어요. 네트워크 상태를 확인해주세요.');
  }

  if (response.statusCode != 200 && response.statusCode != 201) {
    final body = utf8.decode(response.bodyBytes);
    final match = RegExp(r'<pre class="exception_value">(.*?)</pre>', dotAll: true).firstMatch(body);
    // ignore: avoid_print
    print('❗ createMedicationSchedule ${response.statusCode} exception: ${match?.group(1) ?? body}');
    throw ApiException('복약스케줄 저장에 실패했어요. (${response.statusCode})');
  }
}

/// GET /api/medications/logs/today/ 항목 하나 — 오늘 복약기록(예약시간 + 복용여부).
class MedicationLog {
  final String id;
  final String drugName;
  final String dosage;
  final DateTime scheduledTime;
  final bool taken;
  final DateTime? takenAt;

  MedicationLog({
    required this.id,
    required this.drugName,
    required this.dosage,
    required this.scheduledTime,
    required this.taken,
    this.takenAt,
  });

  factory MedicationLog.fromJson(Map<String, dynamic> json) {
    return MedicationLog(
      id: json['id'] as String,
      drugName: json['drug_name'] as String? ?? '',
      dosage: json['dosage'] as String? ?? '',
      scheduledTime: DateTime.parse(json['scheduled_time'] as String),
      taken: json['taken'] as bool? ?? false,
      takenAt: json['taken_at'] != null ? DateTime.parse(json['taken_at'] as String) : null,
    );
  }
}

/// GET /api/medications/logs/today/[?patient_id=...] — 오늘 복약현황.
/// patientId를 넘기면 간호사가 담당(같은 병원 소속) 환자를 조회, 생략하면 본인(환자) 기록.
Future<List<MedicationLog>> fetchTodayMedicationLogs({
  required String accessToken,
  String? patientId,
}) async {
  final uri = Uri.parse('$apiBaseUrl/api/medications/logs/today/').replace(
    queryParameters: patientId != null ? {'patient_id': patientId} : null,
  );

  http.Response response;
  try {
    response = await http.get(uri, headers: {'Authorization': 'Bearer $accessToken'});
  } catch (_) {
    throw ApiException('서버에 연결할 수 없어요. 네트워크 상태를 확인해주세요.');
  }

  if (response.statusCode != 200) {
    throw ApiException('오늘 복약현황을 불러오지 못했어요. (${response.statusCode})');
  }

  final list = jsonDecode(utf8.decode(response.bodyBytes)) as List;
  return list.cast<Map<String, dynamic>>().map(MedicationLog.fromJson).toList();
}

/// POST /api/medications/reminders/ — 간호사가 환자에게 복약 알림(FCM) 수동 전송.
/// message 생략 시 서버 기본 안내 문구가 사용됨.
Future<void> sendMedicationReminder({
  required String patientId,
  String? message,
  required String accessToken,
}) async {
  final uri = Uri.parse('$apiBaseUrl/api/medications/reminders/');
  final body = <String, dynamic>{'patient_id': patientId};
  if (message != null && message.isNotEmpty) body['message'] = message;

  http.Response response;
  try {
    response = await http.post(
      uri,
      headers: {'Authorization': 'Bearer $accessToken', 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
  } catch (_) {
    throw ApiException('서버에 연결할 수 없어요. 네트워크 상태를 확인해주세요.');
  }

  if (response.statusCode != 200 && response.statusCode != 201 && response.statusCode != 202) {
    throw ApiException('복약 알림 전송에 실패했어요. (${response.statusCode})');
  }
}