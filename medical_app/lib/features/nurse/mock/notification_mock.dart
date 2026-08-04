import '../models/notification.dart';

/// 화면 확인용 mock 알림 목록. 카테고리: 예약/채팅/증상위험도/케이스검토.
List<AppNotification> mockNotifications() {
  final now = DateTime.now();
  return [
    AppNotification(
      id: 'n1',
      title: '새 예약요청',
      message: '정O아 환자가 8월 5일 오전 10시 예약을 신청했어요.',
      createdAt: now.subtract(const Duration(minutes: 10)),
      type: NotificationType.appointment,
    ),
    AppNotification(
      id: 'n2',
      title: '미방문 위험 안내',
      message: '박O훈 환자 예약시간이 20분 지났어요. 확인해주세요.',
      createdAt: now.subtract(const Duration(minutes: 25)),
      type: NotificationType.appointment,
    ),
    AppNotification(
      id: 'n3',
      title: '증상위험도 경고',
      message: '이O진 환자가 RED 등급 위험 신호로 분류됐어요. 확인이 필요해요.',
      createdAt: now.subtract(const Duration(minutes: 50)),
      type: NotificationType.triage,
    ),
    AppNotification(
      id: 'n4',
      title: '김의사님의 메시지',
      message: '확인했습니다. 다음 진료 때 상담 진행할게요.',
      createdAt: now.subtract(const Duration(hours: 2)),
      type: NotificationType.chat,
      isRead: true,
    ),
    AppNotification(
      id: 'n5',
      title: '케이스 승인 완료',
      message: '김O수 환자 케이스가 승인 처리됐어요.',
      createdAt: now.subtract(const Duration(hours: 4)),
      type: NotificationType.caseReview,
      isRead: true,
    ),
  ];
}