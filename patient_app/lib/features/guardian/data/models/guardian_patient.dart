class GuardianPatient {
  const GuardianPatient({required this.patientId, required this.patientName});

  factory GuardianPatient.fromJson(Map<String, dynamic> json) {
    return GuardianPatient(
      patientId: _readString(json, 'patient_id'),
      patientName: _readString(json, 'patient_name'),
    );
  }

  final String patientId;
  final String patientName;

  static String _readString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String) return value;
    throw FormatException('$key 필드는 문자열이어야 합니다.');
  }
}
