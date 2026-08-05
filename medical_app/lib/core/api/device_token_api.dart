import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_api.dart';

/// POST /api/auth/device-token/ — FCM 토큰 서버 등록.
Future<void> registerDeviceToken({
  required String fcmToken,
  required String deviceId,
  required String accessToken,
}) async {
  final uri = Uri.parse('$apiBaseUrl/api/auth/device-token/');

  http.Response response;
  try {
    response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'fcm_token': fcmToken,
        'app_type': 'medical',
        'platform': 'android',
        'device_id': deviceId,
      }),
    );
  } catch (_) {
    throw ApiException('서버에 연결할 수 없어요. 네트워크 상태를 확인해주세요.');
  }

  if (response.statusCode != 200 && response.statusCode != 201) {
    throw ApiException('기기 토큰 등록에 실패했어요. (${response.statusCode})');
  }
}