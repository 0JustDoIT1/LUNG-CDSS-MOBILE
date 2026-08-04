import '../models/patient_profile.dart';

abstract interface class PatientRepository {
  Future<PatientProfile> getPatientProfile();
}