/// 의사 프로필. DoctorProfile과 대응.
/// TODO: 실제 연결 시 fromJson() 추가하고 API 응답으로 교체.
class DoctorProfile {
  final String name;
  final String hospital;
  final String department;
  final String licenseNumber; // 읽기전용
  final String? photoUrl; // GCS 저장 경로
  final List<String> specialtyTags; // 자유 태그

  const DoctorProfile({
    required this.name,
    required this.hospital,
    required this.department,
    required this.licenseNumber,
    this.photoUrl,
    this.specialtyTags = const [],
  });

  DoctorProfile copyWith({
    String? photoUrl,
    List<String>? specialtyTags,
  }) {
    return DoctorProfile(
      name: name,
      hospital: hospital,
      department: department,
      licenseNumber: licenseNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      specialtyTags: specialtyTags ?? this.specialtyTags,
    );
  }
}

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