import '../models/patient_profile.dart';

/// 화면 확인용 mock 데이터.
PatientProfile mockPatientProfile(String patientName) {
  return PatientProfile(
    name: patientName,
    patientId: 'P-20260001',
    birthDate: '1968-03-14',
    finalSubtype: 'LUAD',
    intakeSummary: '기침 3주 이상 지속, 체중감소 2kg, 흡연력 20갑년. '
        '가족력 특이사항 없음.',
  );
}