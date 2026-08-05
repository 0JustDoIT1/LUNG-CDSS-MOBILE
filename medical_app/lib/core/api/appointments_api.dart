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

/// GET /api/appointments/mine/ — 의사 본인 일정.
Future<List<Appointment>> fetchMyAppointments(String accessToken) async {
  return _fetchAppointmentList('$apiBaseUrl/api/appointments/mine/', accessToken);
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
    throw ApiException('처리에 실패했어요. (${response.statusCode})');
  }
}

/// GET /api/appointments/mine/ — 의사 본인 일정 (원본 JSON, 각 role이 자기 Appointment.fromJson으로 파싱).
Future<List<Map<String, dynamic>>> fetchMyAppointmentsRaw(String accessToken) async {
  http.Response response;
  try {
    response = await http.get(
      Uri.parse('$apiBaseUrl/api/appointments/mine/'),
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

/// POST /api/appointments/{id}/process/ — 예약요청 승인.
Future<void> approveAppointment(String id, String accessToken) =>
    _postAction('$apiBaseUrl/api/appointments/$id/process/', accessToken);

/// POST /api/appointments/{id}/cancel/ — 예약요청 반려 / 예약 취소.
Future<void> cancelAppointment(String id, String accessToken) =>
    _postAction('$apiBaseUrl/api/appointments/$id/cancel/', accessToken);

/// POST /api/appointments/{id}/check-in/ — 방문처리.
Future<void> checkInAppointment(String id, String accessToken) =>
    _postAction('$apiBaseUrl/api/appointments/$id/check-in/', accessToken);

/// POST /api/appointments/{id}/no-show/ — 미방문처리.
Future<void> markNoShow(String id, String accessToken) =>
    _postAction('$apiBaseUrl/api/appointments/$id/no-show/', accessToken);