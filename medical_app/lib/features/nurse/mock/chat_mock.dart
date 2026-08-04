import '../models/chat.dart';

/// 화면 확인용 mock 채팅 목록.
List<ChatThread> mockChatThreads() {
  final now = DateTime.now();
  return [
    ChatThread(
      id: 'doctor-kim',
      partnerName: '김의사',
      lastMessage: '네, 다음 진료 때 상담 진행할게요',
      lastMessageAt: now.subtract(const Duration(minutes: 18)),
    ),
    ChatThread(
      id: 'doctor-park',
      partnerName: '박의사',
      lastMessage: '최민수 환자 처방 언제 나오나요?',
      lastMessageAt: now.subtract(const Duration(hours: 2)),
      unreadCount: 1,
    ),
  ];
}

/// 화면 확인용 mock 메시지 목록 (스레드 id 기준).
List<ChatMessage> mockMessagesFor(String threadId) {
  final now = DateTime.now();
  if (threadId == 'doctor-kim') {
    return [
      ChatMessage(
        senderName: '나',
        isMe: true,
        text: '선생님, 홍길동 환자 복약순응도가 62%로 떨어졌어요 @김의사',
        sentAt: now.subtract(const Duration(minutes: 20)),
        isRead: true,
      ),
      ChatMessage(
        senderName: '김의사',
        isMe: false,
        text: '확인했습니다. 다음 진료 때 상담 진행할게요',
        sentAt: now.subtract(const Duration(minutes: 18)),
      ),
    ];
  }
  return [
    ChatMessage(
      senderName: '나',
      isMe: true,
      text: '최민수 환자 처방 확인 부탁드립니다',
      sentAt: now.subtract(const Duration(hours: 2, minutes: 5)),
      isRead: false,
    ),
    ChatMessage(
      senderName: '박의사',
      isMe: false,
      text: '최민수 환자 처방 언제 나오나요?',
      sentAt: now.subtract(const Duration(hours: 2)),
    ),
  ];
}