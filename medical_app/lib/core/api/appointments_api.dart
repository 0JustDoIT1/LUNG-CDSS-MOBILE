import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_api.dart';
import '../../features/nurse/models/reservation.dart';

/// GET /api/appointments/queue/ — 예약요청 목록(주로 status=requested).
Future<List<Appointment>> fetchAppointmentQueue(String accessToken) async {
  return _fetchAppointmentList('$apiBaseUrl/api/appointments/queue/', accessToken);
}

/// GET /api/appointments/today-visits/ — 오늘 진료관리 목록.
Future<List<Appointment>> fetchTodayVisits(String accessToken) async {
  return _fetchAppointmentList('$apiBaseUrl/api/appointments/today-visits/', accessToken);
}

/// GET /api/appointments/doctor/mine/ — 의사 본인 일정.
/// (주의: /api/appointments/mine/은 환자 전용이라 의사 토큰으로 부르면 403 남)
Future<List<Appointment>> fetchMyAppointments(String accessToken) async {
  return _fetchAppointmentList('$apiBaseUrl/api/appointments/doctor/mine/', accessToken);
}

Future<List<Appointment>> _fetchAppointmentList(String url, String accessToken) async {
  http.Response response;
  try {
    response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
  } catch (_) {
    throw ApiException('서버에 연결할 수 없어요. 네트워크 상태를 확인해주세요.');
  }

  if (response.statusCode != 200) {
    throw ApiException('예약 목록을 불러오지 못했어요. (${response.statusCode})');
  }

  final list = jsonDecode(utf8.decode(response.bodyBytes)) as List;
  return list.cast<Map<String, dynamic>>().map(Appointment.fromJson).toList();
}

Future<void> _postAction(String url, String accessToken) async {
  final response = await http.post(
    Uri.parse(url),
    headers: {'Authorization': 'Bearer $accessToken'},
  );
  if (response.statusCode != 200) {
    final body = utf8.decode(response.bodyBytes);
    final match = RegExp(r'<pre class="exception_value">(.*?)</pre>', dotAll: true).firstMatch(body);
    // ignore: avoid_print
    print('❗ _postAction $url ${response.statusCode} exception: ${match?.group(1) ?? body}');
    throw ApiException('처리에 실패했어요. (${response.statusCode})');
  }
}

/// GET /api/appointments/doctor/mine/ — 의사 본인 일정 (원본 JSON, 각 role이 자기 Appointment.fromJson으로 파싱).
/// (주의: /api/appointments/mine/은 환자 전용이라 의사 토큰으로 부르면 403 남)
Future<List<Map<String, dynamic>>> fetchMyAppointmentsRaw(String accessToken) async {
  http.Response response;
  try {
    response = await http.get(
      Uri.parse('$apiBaseUrl/api/appointments/doctor/mine/'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
  } catch (_) {
    throw ApiException('서버에 연결할 수 없어요. 네트워크 상태를 확인해주세요.');
  }

  if (response.statusCode != 200) {
    throw ApiException('일정을 불러오지 못했어요. (${response.statusCode})');
  }

  final list = jsonDecode(utf8.decode(response.bodyBytes)) as List;
  return list.cast<Map<String, dynamic>>();
}

/// POST /api/appointments/{id}/process/ — 예약요청 승인/반려. body에 action('approve'|'reject') 필수.
Future<void> _postProcessAction(String id, String action, String accessToken) async {
  final uri = Uri.parse('$apiBaseUrl/api/appointments/$id/process/');
  final response = await http.post(
    uri,
    headers: {'Authorization': 'Bearer $accessToken', 'Content-Type': 'application/json'},
    body: jsonEncode({'action': action}),
  );
  if (response.statusCode != 200) {
    throw ApiException('처리에 실패했어요. (${response.statusCode})');
  }
}

/// POST /api/appointments/{id}/process/ (action=approve) — 예약요청 승인.
Future<void> approveAppointment(String id, String accessToken) =>
    _postProcessAction(id, 'approve', accessToken);

/// POST /api/appointments/{id}/process/ (action=reject) — 예약요청 반려.
/// (주의: .../cancel/ 은 이 용도가 아님 — 반려 시도하면 403 남. 반려도 승인처럼 process/에 action만 다르게 보냄)
Future<void> cancelAppointment(String id, String accessToken) =>
    _postProcessAction(id, 'reject', accessToken);

/// POST /api/appointments/{id}/check-in/ — 방문처리.
Future<void> checkInAppointment(String id, String accessToken) =>
    _postAction('$apiBaseUrl/api/appointments/$id/check-in/', accessToken);

/// POST /api/appointments/{id}/no-show/ — 미방문처리.
Future<void> markNoShow(String id, String accessToken) =>
    _postAction('$apiBaseUrl/api/appointments/$id/no-show/', accessToken);

/// POST /api/appointments/doctor/off-days/ — 단발 휴진 등록.
Future<void> createDoctorOffDay({
  required String accessToken,
  required DateTime date,
  required bool isMorningOff,
  required bool isAfternoonOff,
  required String reason,
}) async {
  final uri = Uri.parse('$apiBaseUrl/api/appointments/doctor/off-days/');
  String two(int n) => n.toString().padLeft(2, '0');
  final dateStr = '${date.year}-${two(date.month)}-${two(date.day)}';

  http.Response response;
  try {
    response = await http.post(
      uri,
      headers: {'Authorization': 'Bearer $accessToken', 'Content-Type': 'application/json'},
      body: jsonEncode({
        'date': dateStr,
        'is_morning_off': isMorningOff,
        'is_afternoon_off': isAfternoonOff,
        'reason': reason,
      }),
    );
  } catch (_) {
    throw ApiException('서버에 연결할 수 없어요. 네트워크 상태를 확인해주세요.');
  }

  if (response.statusCode != 200 && response.statusCode != 201) {
    throw ApiException('휴진 등록에 실패했어요. (${response.statusCode})');
  }
}

/// GET /api/appointments/doctor/off-days/ 항목 하나 (단발 휴진 등록건).
class DoctorOffDay {
  final String id;
  final DateTime date;
  final bool isMorningOff;
  final bool isAfternoonOff;
  final String reason;

  DoctorOffDay({
    required this.id,
    required this.date,
    required this.isMorningOff,
    required this.isAfternoonOff,
    required this.reason,
  });

  factory DoctorOffDay.fromJson(Map<String, dynamic> json) {
    return DoctorOffDay(
      id: json['id'].toString(),
      date: DateTime.parse(json['date'] as String),
      isMorningOff: json['is_morning_off'] as bool? ?? false,
      isAfternoonOff: json['is_afternoon_off'] as bool? ?? false,
      reason: json['reason'] as String? ?? '',
    );
  }
}

/// GET /api/appointments/doctor/off-days/ — 등록된 단발 휴진 목록 조회.
Future<List<DoctorOffDay>> fetchDoctorOffDays(String accessToken) async {
  final uri = Uri.parse('$apiBaseUrl/api/appointments/doctor/off-days/');

  http.Response response;
  try {
    response = await http.get(uri, headers: {'Authorization': 'Bearer $accessToken'});
  } catch (_) {
    throw ApiException('서버에 연결할 수 없어요. 네트워크 상태를 확인해주세요.');
  }

  if (response.statusCode != 200) {
    throw ApiException('휴진 목록을 불러오지 못했어요. (${response.statusCode})');
  }

  final decoded = jsonDecode(utf8.decode(response.bodyBytes));
  final list = decoded is Map<String, dynamic> ? decoded['results'] as List : decoded as List;
  try {
    return list.cast<Map<String, dynamic>>().map(DoctorOffDay.fromJson).toList();
  } catch (e) {
    // ignore: avoid_print
    print('❗ fetchDoctorOffDays parse error: $e / raw: ${utf8.decode(response.bodyBytes)}');
    rethrow;
  }
}

/// DELETE /api/appointments/doctor/off-days/{id}/ — 등록된 단발 휴진 취소.
Future<void> deleteDoctorOffDay(String id, String accessToken) async {
  final uri = Uri.parse('$apiBaseUrl/api/appointments/doctor/off-days/$id/');

  http.Response response;
  try {
    response = await http.delete(uri, headers: {'Authorization': 'Bearer $accessToken'});
  } catch (_) {
    throw ApiException('서버에 연결할 수 없어요. 네트워크 상태를 확인해주세요.');
  }

  if (response.statusCode != 200 && response.statusCode != 204) {
    throw ApiException('휴진 취소에 실패했어요. (${response.statusCode})');
  }
}

/// GET/PUT /api/appointments/doctor/weekly-schedule/ 항목 하나 (요일 x 오전/오후 진료가능 여부).
class WeeklyScheduleSlot {
  final String dayOfWeek; // 'mon'|'tue'|'wed'|'thu'|'fri'|'sat'
  final String period; // 'am'|'pm'
  final bool available; // false면 정기 휴진

  WeeklyScheduleSlot({
    required this.dayOfWeek,
    required this.period,
    required this.available,
  });

  factory WeeklyScheduleSlot.fromJson(Map<String, dynamic> json) {
    return WeeklyScheduleSlot(
      dayOfWeek: json['day_of_week'] as String,
      period: json['period'] as String,
      available: json['available'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'day_of_week': dayOfWeek,
        'period': period,
        'available': available,
      };
}

/// GET /api/appointments/doctor/weekly-schedule/ — 현재 정기 휴진 설정 조회.
Future<List<WeeklyScheduleSlot>> fetchDoctorWeeklySchedule(String accessToken) async {
  final uri = Uri.parse('$apiBaseUrl/api/appointments/doctor/weekly-schedule/');

  http.Response response;
  try {
    response = await http.get(uri, headers: {'Authorization': 'Bearer $accessToken'});
  } catch (_) {
    throw ApiException('서버에 연결할 수 없어요. 네트워크 상태를 확인해주세요.');
  }

  if (response.statusCode != 200) {
    throw ApiException('정기 휴진 설정을 불러오지 못했어요. (${response.statusCode})');
  }

  final list = jsonDecode(utf8.decode(response.bodyBytes)) as List;
  return list.cast<Map<String, dynamic>>().map(WeeklyScheduleSlot.fromJson).toList();
}

/// PUT /api/appointments/doctor/weekly-schedule/ — 정기 휴진 설정 저장(배열 전체 교체).
Future<void> updateDoctorWeeklySchedule({
  required String accessToken,
  required List<WeeklyScheduleSlot> slots,
}) async {
  final uri = Uri.parse('$apiBaseUrl/api/appointments/doctor/weekly-schedule/');

  http.Response response;
  try {
    response = await http.put(
      uri,
      headers: {'Authorization': 'Bearer $accessToken', 'Content-Type': 'application/json'},
      body: jsonEncode(slots.map((s) => s.toJson()).toList()),
    );
  } catch (_) {
    throw ApiException('서버에 연결할 수 없어요. 네트워크 상태를 확인해주세요.');
  }

  if (response.statusCode != 200) {
    throw ApiException('정기 휴진 저장에 실패했어요. (${response.statusCode})');
  }
}