import '../mock/mock_patient_data.dart';
import '../models/patient_profile.dart';
import 'patient_repository.dart';

class MockPatientRepository implements PatientRepository {
  @override
  Future<PatientProfile> getPatientProfile() async {
    await Future<void>.delayed(
      const Duration(milliseconds: 500),
    );

    return MockPatientData.profile;
  }
}