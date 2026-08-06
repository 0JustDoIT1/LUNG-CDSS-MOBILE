import '../../../core/utils/datetime_utils.dart';

/// 예약 한 건. 실제 API(GET /api/appointments/mine/) 응답 구조.
class Appointment {
  final String id;
  final String patientName;
  final String doctorName;
  final String department;
  final DateTime requestedAtSlot;
  final DateTime? confirmedSlot;
  final AppointmentStatus status;
  final DateTime createdAt;

  const Appointment({
    required this.id,
    required this.patientName,
    required this.doctorName,
    required this.department,
    required this.requestedAtSlot,
    this.confirmedSlot,
    required this.status,
    required this.createdAt,
  });

  /// 화면에 보여줄 진료 일시 — 확정된 게 있으면 그거, 없으면 희망 일시.
  DateTime get dateTime => confirmedSlot ?? requestedAtSlot;

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] as String,
      patientName: json['patient_name'] as String? ?? '',
      doctorName: json['doctor_name'] as String? ?? '',
      department: json['department'] as String? ?? '',
      requestedAtSlot: parseServerDateTime(json['requested_at_slot'] as String),
      confirmedSlot: json['confirmed_slot'] != null
          ? parseServerDateTime(json['confirmed_slot'] as String)
          : null,
      status: AppointmentStatus.fromServer(json['status'] as String),
      createdAt: parseServerDateTime(json['created_at'] as String),
    );
  }
}

enum AppointmentStatus {
  requested, // 요청됨
  confirmed, // 확정
  remindedD7,
  remindedD1,
  checkedIn, // 방문완료
  completed, // 진료완료
  cancelled, // 취소
  noShow; // 미방문

  static AppointmentStatus fromServer(String value) => switch (value) {
        'requested' => AppointmentStatus.requested,
        'confirmed' => AppointmentStatus.confirmed,
        'reminded_d7' => AppointmentStatus.remindedD7,
        'reminded_d1' => AppointmentStatus.remindedD1,
        'checked_in' => AppointmentStatus.checkedIn,
        'completed' => AppointmentStatus.completed,
        'cancelled' => AppointmentStatus.cancelled,
        'no_show' => AppointmentStatus.noShow,
        _ => AppointmentStatus.requested,
      };

  String get label => switch (this) {
        AppointmentStatus.requested => '요청됨',
        AppointmentStatus.confirmed => '예정',
        AppointmentStatus.remindedD7 => '예정',
        AppointmentStatus.remindedD1 => '예정',
        AppointmentStatus.checkedIn => '방문완료',
        AppointmentStatus.completed => '진료완료',
        AppointmentStatus.cancelled => '취소됨',
        AppointmentStatus.noShow => '미방문',
      };
}