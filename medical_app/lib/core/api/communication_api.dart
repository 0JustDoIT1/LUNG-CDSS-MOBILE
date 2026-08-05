import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

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

/// GET /api/communication/threads/counterparts/ 항목 하나 — 대화 시작 가능한 상대(같은 과).
class ChatCounterpart {
  final String id;
  final String name;

  ChatCounterpart({required this.id, required this.name});

  factory ChatCounterpart.fromJson(Map<String, dynamic> json) {
    return ChatCounterpart(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
    );
  }
}

/// GET /api/communication/threads/counterparts/ — 대화 시작 가능한 상대 목록(같은 과).
Future<List<ChatCounterpart>> fetchChatCounterparts(String accessToken) => _fetchList(
      '$apiBaseUrl/api/communication/threads/counterparts/',
      accessToken,
      ChatCounterpart.fromJson,
    );

/// POST /api/communication/threads/start/ — 새 대화 시작(이미 스레드가 있으면 기존 것을 그대로 돌려줌).
Future<ChatThread> startChatThread({
  required String userId,
  String? caseId,
  required String accessToken,
}) async {
  final uri = Uri.parse('$apiBaseUrl/api/communication/threads/start/');
  final body = <String, dynamic>{'user_id': userId};
  if (caseId != null) body['case_id'] = caseId;

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

  if (response.statusCode != 200 && response.statusCode != 201) {
    throw ApiException('대화를 시작하지 못했어요. (${response.statusCode})');
  }

  final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  return ChatThread.fromJson(json);
}

/// 채팅 메시지 한 건. REST 히스토리 응답과 WS로 오는 메시지가 동일한 구조(MessageSerializer 그대로).
class ChatMessage {
  final String id;
  final String sender; // 발신자 user id (UUID) — SessionController.myUserId와 비교해 내 메시지인지 판단
  final String senderName;
  final String content;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.senderName,
    required this.content,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      sender: json['sender'] as String,
      senderName: json['sender_name'] as String? ?? '',
      content: json['content'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// GET /api/communication/threads/{thread_id}/messages/ — 과거 메시지 히스토리(WS 연결 전 최초 로딩용).
Future<List<ChatMessage>> fetchChatMessages(String threadId, String accessToken) => _fetchList(
      '$apiBaseUrl/api/communication/threads/$threadId/messages/',
      accessToken,
      ChatMessage.fromJson,
    );

/// wss://.../ws/chat/{thread_id}?token={access_token} 실시간 연결 하나.
/// 서버가 끊김을 자동 재연결해주지 않아서, 연결이 끊기면 클라이언트가 알아서 재연결함.
class ChatSocket {
  final String threadId;
  final String accessToken;
  final void Function(ChatMessage message) onMessage;

  WebSocketChannel? _channel;
  bool _disposed = false;

  ChatSocket({
    required this.threadId,
    required this.accessToken,
    required this.onMessage,
  });

  void connect() {
    if (_disposed) return;

    final wsBase = apiBaseUrl.replaceFirst('https://', 'wss://').replaceFirst('http://', 'ws://');
    final uri = Uri.parse('$wsBase/ws/chat/$threadId?token=$accessToken');

    try {
      _channel = WebSocketChannel.connect(uri);
    } catch (_) {
      _scheduleReconnect();
      return;
    }

    _channel!.stream.listen(
      (event) {
        try {
          final json = jsonDecode(event as String) as Map<String, dynamic>;
          onMessage(ChatMessage.fromJson(json));
        } catch (_) {
          // 파싱 안 되는 이벤트는 무시
        }
      },
      onDone: _scheduleReconnect,
      onError: (_) => _scheduleReconnect(),
      cancelOnError: true,
    );
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    Future.delayed(const Duration(seconds: 2), connect);
  }

  /// 메시지 전송은 WS로 — REST로 보내면 저장은 되지만 다른 접속자에게 실시간 전파가 안 됨.
  void send(String content) {
    _channel?.sink.add(jsonEncode({'content': content}));
  }

  void dispose() {
    _disposed = true;
    _channel?.sink.close();
  }
}