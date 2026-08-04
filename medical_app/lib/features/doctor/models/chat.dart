/// 채팅 상대방(간호사) 스레드 하나.
/// TODO: 실제 연결 시 fromJson() 추가하고 API/WebSocket으로 교체.
class ChatThread {
  final String id;
  final String partnerName; // 간호사 이름
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;

  const ChatThread({
    required this.id,
    required this.partnerName,
    required this.lastMessage,
    required this.lastMessageAt,
    this.unreadCount = 0,
  });
}

/// 채팅 메시지 한 건.
class ChatMessage {
  final String senderName;
  final bool isMe;
  final String text;
  final DateTime sentAt;
  

  const ChatMessage({
    required this.senderName,
    required this.isMe,
    required this.text,
    required this.sentAt,
    
  });
}