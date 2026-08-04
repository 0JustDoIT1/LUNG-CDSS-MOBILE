class PatientProfile {
  const PatientProfile({
    required this.id,
    required this.name,
    required this.patientNumber,
    required this.hospitalName,
    this.assignedDoctorName,
  });

  final String id;
  final String name;
  final String patientNumber;
  final String hospitalName;
  final String? assignedDoctorName;

  PatientProfile copyWith({
    String? id,
    String? name,
    String? patientNumber,
    String? hospitalName,
    String? assignedDoctorName,
  }) {
    return PatientProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      patientNumber: patientNumber ?? this.patientNumber,
      hospitalName: hospitalName ?? this.hospitalName,
      assignedDoctorName: assignedDoctorName ?? this.assignedDoctorName,
    );
  }
}