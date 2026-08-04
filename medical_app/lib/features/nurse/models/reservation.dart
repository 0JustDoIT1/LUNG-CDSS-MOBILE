/// 예약 신청 한 건. 신청리스트에 뜨는 항목.
/// 승인 시 Appointment.status=confirmed로 전환.
/// TODO: 실제 연결 시 fromJson() 추가하고 API로 교체.
class ReservationRequest {
  final String id;
  final String patientName;
  final String department; // 희망 과
  final String doctorName; // 희망 의사
  final DateTime desiredDateTime; // 희망 일시
  final DateTime requestedAt; // 신청시각

  const ReservationRequest({
    required this.id,
    required this.patientName,
    required this.department,
    required this.doctorName,
    required this.desiredDateTime,
    required this.requestedAt,
  });
}

enum CheckInStatus {
  waiting, // 대기
  checkedIn, // 방문처리 완료
  noShow; // 노쇼

  String get label => switch (this) {
        CheckInStatus.waiting => '대기',
        CheckInStatus.checkedIn => '방문완료',
        CheckInStatus.noShow => '미방문',
      };
}

/// 오늘 예약 한 건 (진료관리 탭용).
class TodayAppointment {
  final String id;
  final String patientName;
  final DateTime dateTime;
  CheckInStatus status;

  TodayAppointment({
    required this.id,
    required this.patientName,
    required this.dateTime,
    required this.status,
  });
}