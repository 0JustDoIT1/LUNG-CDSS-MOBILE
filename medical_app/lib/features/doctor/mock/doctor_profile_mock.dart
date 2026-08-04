import '../models/doctor_profile.dart';

/// 화면 확인용 mock 데이터.
DoctorProfile mockDoctorProfile() {
  return const DoctorProfile(
    name: '김의사',
    hospital: 'LUNG-CDSS 대학병원',
    department: '호흡기내과',
    licenseNumber: '12345-2024',
    specialtyTags: ['폐암클리닉', '금연클리닉'],
  );
}