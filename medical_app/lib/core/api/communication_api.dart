import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_api.dart';

/// 채팅 스레드 하나. GET /api/communication/threads/ 응답 구조.
class ChatThread {
  final String id;
  final String? relatedCase;
  final String otherParticipantName;
  final String lastMessage;
  final int unreadCount;
  final DateTime createdAt;

  ChatThread({
    required this.id,
    this.relatedCase,
    required this.otherParticipantName,
    required this.lastMessage,
    required this.unreadCount,
    required this.createdAt,
  });

  factory ChatThread.fromJson(Map<String, dynamic> json) {
    return ChatThread(
      id: json['id'] as String,
      relatedCase: json['related_case'] as String?,
      otherParticipantName: json['other_participant_name'] as String? ?? '',
      lastMessage: json['last_message'] as String? ?? '',
      // 문서상 타입이 string으로 나와서 안전하게 파싱
      unreadCount: int.tryParse('${json['unread_count']}') ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

Future<List<T>> _fetchList<T>(
  String url,
  String accessToken,
  T Function(Map<String, dynamic>) fromJson,
) async {
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
    throw ApiException('불러오지 못했어요. (${response.statusCode})');
  }

  final list = jsonDecode(utf8.decode(response.bodyBytes)) as List;
  return list.cast<Map<String, dynamic>>().map(fromJson).toList();
}

/// GET /api/communication/notifications/ — fromJson은 각 role의 AppNotification.fromJson을 넘겨서 사용.
Future<List<T>> fetchNotifications<T>(
  String accessToken,
  T Function(Map<String, dynamic>) fromJson,
) =>
    _fetchList('$apiBaseUrl/api/communication/notifications/', accessToken, fromJson);

/// POST /api/communication/notifications/{id}/read/
Future<void> markNotificationRead(String notificationId, String accessToken) async {
  final response = await http.post(
    Uri.parse('$apiBaseUrl/api/communication/notifications/$notificationId/read/'),
    headers: {'Authorization': 'Bearer $accessToken'},
  );
  if (response.statusCode != 200) {
    throw ApiException('읽음처리에 실패했어요.');
  }
}

/// GET /api/communication/threads/ — 실제로 대화 나눈 스레드만 옴(대화 없으면 안 뜸).
Future<List<ChatThread>> fetchChatThreads(String accessToken) => _fetchList(
      '$apiBaseUrl/api/communication/threads/',
      accessToken,
      ChatThread.fromJson,
    );