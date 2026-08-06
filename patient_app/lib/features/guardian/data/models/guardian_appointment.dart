class GuardianAppointment {
  const GuardianAppointment({
    required this.id,
    required this.requestedAtSlot,
    required this.confirmedSlot,
    required this.department,
    required this.doctorName,
    required this.status,
  });

  factory GuardianAppointment.fromJson(Map<String, dynamic> json) {
    return GuardianAppointment(
      id: _readString(json, 'id'),
      requestedAtSlot: _readDateTime(json, 'requested_at_slot'),
      confirmedSlot: _readNullableDateTime(json, 'confirmed_slot'),
      department: _readString(json, 'department'),
      doctorName: _readString(json, 'doctor_name'),
      status: _readString(json, 'status'),
    );
  }

  final String id;
  final DateTime requestedAtSlot;
  final DateTime? confirmedSlot;
  final String department;
  final String doctorName;
  final String status;

  DateTime get displaySlot => confirmedSlot ?? requestedAtSlot;

  static String _readString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String) return value;
    throw FormatException('$key 필드는 문자열이어야 합니다.');
  }

  static DateTime _readDateTime(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String) {
      throw FormatException('$key 필드는 날짜 문자열이어야 합니다.');
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) throw FormatException('$key 날짜 형식이 올바르지 않습니다.');
    return parsed;
  }

  static DateTime? _readNullableDateTime(
    Map<String, dynamic> json,
    String key,
  ) {
    final value = json[key];
    if (value == null) return null;
    if (value is! String) {
      throw FormatException('$key 필드는 날짜 문자열 또는 null이어야 합니다.');
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) throw FormatException('$key 날짜 형식이 올바르지 않습니다.');
    return parsed;
  }
}
