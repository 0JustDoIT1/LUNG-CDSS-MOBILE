import '../models/notification.dart';

/// 화면 확인용 mock 알림 목록. 카테고리: 예약/채팅/증상위험도/케이스검토.
List<AppNotification> mockNotifications() {
  final now = DateTime.now();
  return [
    AppNotification(
      id: 'n1',
      title: '긴급 케이스 도착',
      message: '이O진 환자 케이스가 신뢰도 67%로 검토대기 등록됐어요.',
      createdAt: now.subtract(const Duration(minutes: 15)),
      type: NotificationType.caseReview,
    ),
    AppNotification(
      id: 'n2',
      title: '증상위험도 경고',
      message: '김O수 환자가 RED 등급 위험 신호로 분류됐어요. 확인이 필요해요.',
      createdAt: now.subtract(const Duration(minutes: 40)),
      type: NotificationType.triage,
    ),
    AppNotification(
      id: 'n3',
      title: '오늘 진료 알림',
      message: '10:30 홍길동님 진료 30분 전이에요.',
      createdAt: now.subtract(const Duration(hours: 1)),
      type: NotificationType.appointment,
      isRead: true,
    ),
    AppNotification(
      id: 'n4',
      title: '박간호사님의 메시지',
      message: '홍길동 환자 오늘 복약 0/2 미완료 상태예요. 확인 부탁드려요.',
      createdAt: now.subtract(const Duration(hours: 3)),
      type: NotificationType.chat,
      isRead: true,
    ),
  ];
}