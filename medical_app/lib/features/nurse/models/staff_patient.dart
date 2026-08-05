/// 담당환자 한 명 (GET /api/auth/staff/patients/ 응답 기준).
class StaffPatient {
  final String id; // 환자 UUID — 복약스케줄 등 다른 API 호출 시 그대로 사용
  final String name;
  final String patientNumber;
  final String birthDate; // 'YYYY-MM-DD' 문자열 그대로 보관

  const StaffPatient({
    required this.id,
    required this.name,
    required this.patientNumber,
    required this.birthDate,
  });

  factory StaffPatient.fromJson(Map<String, dynamic> json) {
    return StaffPatient(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      patientNumber: json['patient_number'] as String? ?? '',
      birthDate: json['birth_date'] as String? ?? '',
    );
  }
}