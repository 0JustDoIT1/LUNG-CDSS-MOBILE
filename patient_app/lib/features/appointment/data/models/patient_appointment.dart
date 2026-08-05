class PatientAppointment {
  const PatientAppointment({
    required this.id,
    required this.patientName,
    required this.doctorName,
    required this.department,
    required this.requestedAtSlot,
    required this.confirmedSlot,
    required this.status,
    required this.createdAt,
  });

  factory PatientAppointment.fromJson(Map<String, dynamic> json) {
    return PatientAppointment(
      id: _readString(json, 'id'),
      patientName: _readString(json, 'patient_name'),
      doctorName: _readString(json, 'doctor_name'),
      department: _readString(json, 'department'),
      requestedAtSlot: _readDateTime(json, 'requested_at_slot'),
      confirmedSlot: _readNullableDateTime(json, 'confirmed_slot'),
      status: _readString(json, 'status'),
      createdAt: _readDateTime(json, 'created_at'),
    );
  }

  final String id;
  final String patientName;
  final String doctorName;
  final String department;
  final DateTime requestedAtSlot;
  final DateTime? confirmedSlot;
  final String status;
  final DateTime createdAt;

  static String _readString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String) {
      return value;
    }
    throw FormatException('$key 필드는 문자열이어야 합니다.');
  }

  static DateTime _readDateTime(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String) {
      throw FormatException('$key 필드는 날짜 문자열이어야 합니다.');
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      throw FormatException('$key 필드의 날짜 형식이 올바르지 않습니다.');
    }
    return parsed;
  }

  static DateTime? _readNullableDateTime(
    Map<String, dynamic> json,
    String key,
  ) {
    final value = json[key];
    if (value == null) {
      return null;
    }
    if (value is! String) {
      throw FormatException('$key 필드는 날짜 문자열 또는 null이어야 합니다.');
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      throw FormatException('$key 필드의 날짜 형식이 올바르지 않습니다.');
    }
    return parsed;
  }
}
