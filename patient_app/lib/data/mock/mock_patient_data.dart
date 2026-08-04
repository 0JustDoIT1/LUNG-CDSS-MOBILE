import '../models/patient_profile.dart';

abstract final class MockPatientData {
  static const PatientProfile profile = PatientProfile(
    id: 'patient-001',
    name: '이대박',
    patientNumber: 'P20260802001',
    hospitalName: '숨잇대학교병원',
    assignedDoctorName: '김호흡',
  );
}