/// 알림 한 건.
/// TODO: 실제 연결 시 fromJson() 추가하고 API/WebSocket으로 교체.
class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final NotificationType type;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.type,
    this.isRead = false,
  });
}

enum NotificationType {
  appointment, // 예약 — 간호사에게 특히 중요(예약요청/노쇼)
  chat, // 채팅 — 의사-간호사 채팅
  triage, // 증상위험도 — RED 트리아지 발생 알림
  caseReview; // 케이스검토 — 의사에게 특히 중요(검토대기/승인반려결과)

  String get label => switch (this) {
        NotificationType.appointment => '예약',
        NotificationType.chat => '채팅',
        NotificationType.triage => '증상위험도(트리아지)',
        NotificationType.caseReview => '케이스검토',
      };
}