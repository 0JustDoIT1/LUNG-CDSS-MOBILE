class Appointment {
  const Appointment({
    required this.id,
    required this.department,
    required this.doctorName,
    required this.hospitalName,
    required this.location,
    required this.appointmentAt,
    required this.status,
    required this.purpose,
    this.memo,
  });

  final String id;
  final String department;
  final String doctorName;
  final String hospitalName;
  final String location;
  final DateTime appointmentAt;
  final AppointmentStatus status;
  final String purpose;
  final String? memo;

  Appointment copyWith({
    String? id,
    String? department,
    String? doctorName,
    String? hospitalName,
    String? location,
    DateTime? appointmentAt,
    AppointmentStatus? status,
    String? purpose,
    String? memo,
  }) {
    return Appointment(
      id: id ?? this.id,
      department: department ?? this.department,
      doctorName: doctorName ?? this.doctorName,
      hospitalName: hospitalName ?? this.hospitalName,
      location: location ?? this.location,
      appointmentAt: appointmentAt ?? this.appointmentAt,
      status: status ?? this.status,
      purpose: purpose ?? this.purpose,
      memo: memo ?? this.memo,
    );
  }
}

enum AppointmentStatus {
  scheduled,
  completed,
  cancelled,
}

extension AppointmentStatusExtension on AppointmentStatus {
  String get label {
    switch (this) {
      case AppointmentStatus.scheduled:
        return '예약예정';
      case AppointmentStatus.completed:
        return '진료완료';
      case AppointmentStatus.cancelled:
        return '예약취소';
    }
  }
}