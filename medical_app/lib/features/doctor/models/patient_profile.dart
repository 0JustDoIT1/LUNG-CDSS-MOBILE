/// 환자 상세정보(기본정보/진단정보/문진표 요약).
/// TODO: 실제 연결 시 fromJson() 추가하고 API 응답으로 교체.
class PatientProfile {
  final String name;
  final String patientId; // 환자번호
  final String birthDate; // 문자열로만 표시 (YYYY-MM-DD)
  final String finalSubtype; // ConfirmedFinding.final_subtype
  final String intakeSummary; // IntakeForm 요약 — TODO: 환자앱 문진표 API 연결 예정

  const PatientProfile({
    required this.name,
    required this.patientId,
    required this.birthDate,
    required this.finalSubtype,
    required this.intakeSummary,
  });
}