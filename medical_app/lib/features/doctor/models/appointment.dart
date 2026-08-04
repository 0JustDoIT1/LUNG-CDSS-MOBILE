/// 하루치 예약 한 건.
/// TODO: 실제 연결 시 fromJson() 추가하고 API 응답으로 교체.
class Appointment {
  final String id;
  final String patientName;
  final DateTime dateTime;
  final AppointmentStatus status;

  const Appointment({
    required this.id,
    required this.patientName,
    required this.dateTime,
    required this.status,
  });
}

enum AppointmentStatus {
  scheduled, // 예정
  visited, // 방문완료
  noShow; // 미방문

  String get label => switch (this) {
        AppointmentStatus.scheduled => '예정',
        AppointmentStatus.visited => '방문완료',
        AppointmentStatus.noShow => '미방문',
      };
}