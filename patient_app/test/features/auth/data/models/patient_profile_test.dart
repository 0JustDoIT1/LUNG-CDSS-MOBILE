import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/features/auth/data/models/patient_profile.dart';

void main() {
  group('PatientProfile.fromJson', () {
    test('parses valid JSON', () {
      final profile = PatientProfile.fromJson(_validJson);

      expect(profile.patientNumber, 'P-001');
      expect(profile.birthDate, DateTime(1990, 1, 2));
      expect(profile.gender, 'female');
      expect(profile.hospitalName, 'Hospital');
      expect(profile.assignedDoctorId, 'doctor-uuid');
      expect(profile.name, 'Patient');
      expect(profile.phoneNumber, '010-1234-5678');
    });

    test('normalizes a null gender to null', () {
      final profile = PatientProfile.fromJson({..._validJson, 'gender': null});
      expect(profile.gender, isNull);
    });

    test('normalizes an empty gender to null', () {
      final profile = PatientProfile.fromJson({..._validJson, 'gender': ''});
      expect(profile.gender, isNull);
    });

    test('keeps a null assigned_doctor as null', () {
      final profile = PatientProfile.fromJson({
        ..._validJson,
        'assigned_doctor': null,
      });
      expect(profile.assignedDoctorId, isNull);
    });

    test('rejects an invalid required field type', () {
      expect(
        () => PatientProfile.fromJson({..._validJson, 'name': 1}),
        throwsFormatException,
      );
    });

    test('rejects an invalid birth_date', () {
      expect(
        () => PatientProfile.fromJson({..._validJson, 'birth_date': 'invalid'}),
        throwsFormatException,
      );
    });
  });
}

const _validJson = <String, dynamic>{
  'patient_number': 'P-001',
  'birth_date': '1990-01-02',
  'gender': 'female',
  'hospital_name': 'Hospital',
  'assigned_doctor': 'doctor-uuid',
  'name': 'Patient',
  'phone_number': '010-1234-5678',
};
