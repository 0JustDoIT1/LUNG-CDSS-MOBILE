import '../models/chat.dart';

/// 화면 확인용 mock 채팅 목록.
List<ChatThread> mockChatThreads() {
  final now = DateTime.now();
  return [
    ChatThread(
      id: 'nurse-park',
      partnerName: '박간호사',
      lastMessage: '홍길동 환자 복약순응도 낮아서 확인 부탁드려요',
      lastMessageAt: now.subtract(const Duration(minutes: 12)),
      unreadCount: 2,
    ),
    ChatThread(
      id: 'nurse-kim',
      partnerName: '김간호사',
      lastMessage: '네, 처방 확인했습니다',
      lastMessageAt: now.subtract(const Duration(hours: 3)),
    ),
  ];
}

/// 화면 확인용 mock 메시지 목록 (스레드 id 기준).
List<ChatMessage> mockMessagesFor(String threadId) {
  final now = DateTime.now();
  if (threadId == 'nurse-park') {
    return [
      ChatMessage(
        senderName: '박간호사',
        isMe: false,
        text: '선생님, 홍길동 환자 복약순응도가 62%로 떨어졌어요',
        sentAt: now.subtract(const Duration(minutes: 20)),
      ),
      ChatMessage(
        senderName: '나',
        isMe: true,
        text: '확인했습니다. 다음 진료 때 상담 진행할게요 @박간호사',
        sentAt: now.subtract(const Duration(minutes: 18)),
      ),
      ChatMessage(
        senderName: '박간호사',
        isMe: false,
        text: '홍길동 환자 복약순응도 낮아서 확인 부탁드려요',
        sentAt: now.subtract(const Duration(minutes: 12)),
      ),
    ];
  }
  return [
    ChatMessage(
      senderName: '김간호사',
      isMe: false,
      text: '최민수 환자 처방 확인 부탁드립니다',
      sentAt: now.subtract(const Duration(hours: 3, minutes: 5)),
    ),
    ChatMessage(
      senderName: '나',
      isMe: true,
      text: '네, 처방 확인했습니다',
      sentAt: now.subtract(const Duration(hours: 3)),

    ),
  ];
}