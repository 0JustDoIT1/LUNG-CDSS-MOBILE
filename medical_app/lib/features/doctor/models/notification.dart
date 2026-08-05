/// 알림 한 건. 실제 API(GET /api/communication/notifications/) 응답 구조.
class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final NotificationType type;
  final String? deepLink;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.type,
    this.deepLink,
    this.isRead = false,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      message: json['body'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      type: NotificationType.fromServer(json['category'] as String),
      deepLink: json['deep_link'] as String?,
      isRead: json['is_read'] as bool? ?? false,
    );
  }
}

enum NotificationType {
  medication, // 복약
  appointment, // 예약 — 간호사에게 특히 중요(예약요청/노쇼)
  chat, // 채팅 — 의사-간호사 채팅
  triage, // 증상위험도 — RED 트리아지 발생 알림
  caseReview; // 케이스검토 — 의사에게 특히 중요(검토대기/승인반려결과)

  static NotificationType fromServer(String value) => switch (value) {
        'medication' => NotificationType.medication,
        'appointment' => NotificationType.appointment,
        'chat' => NotificationType.chat,
        'triage' => NotificationType.triage,
        'case_review' => NotificationType.caseReview,
        _ => NotificationType.chat,
      };

  String get label => switch (this) {
        NotificationType.medication => '복약',
        NotificationType.appointment => '예약',
        NotificationType.chat => '채팅',
        NotificationType.triage => '증상위험도(트리아지)',
        NotificationType.caseReview => '케이스검토',
      };
}