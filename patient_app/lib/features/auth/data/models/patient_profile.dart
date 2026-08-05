class PatientProfile {
  const PatientProfile({
    required this.patientNumber,
    required this.birthDate,
    required this.gender,
    required this.hospitalName,
    required this.assignedDoctorId,
    required this.name,
    required this.phoneNumber,
  });

  factory PatientProfile.fromJson(Map<String, dynamic> json) {
    final genderValue = json['gender'];
    if (genderValue != null && genderValue is! String) {
      throw const FormatException('gender 필드는 문자열 또는 null이어야 합니다.');
    }

    return PatientProfile(
      patientNumber: _readString(json, 'patient_number'),
      birthDate: _readDateTime(json, 'birth_date'),
      gender: genderValue == null || (genderValue as String).isEmpty
          ? null
          : genderValue,
      hospitalName: _readString(json, 'hospital_name'),
      assignedDoctorId: _readNullableString(json, 'assigned_doctor'),
      name: _readString(json, 'name'),
      phoneNumber: _readNullableString(json, 'phone_number'),
    );
  }

  final String patientNumber;
  final DateTime birthDate;
  final String? gender;
  final String hospitalName;
  final String? assignedDoctorId;
  final String name;
  final String? phoneNumber;

  static String _readString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String) {
      return value;
    }
    throw FormatException('$key 필드는 문자열이어야 합니다.');
  }

  static String? _readNullableString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null || value is String) {
      return value as String?;
    }
    throw FormatException('$key 필드는 문자열 또는 null이어야 합니다.');
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
}
