import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/features/auth/data/models/patient_gender.dart';

void main() {
  test('maps the female display option to the API value', () {
    expect(PatientGender.female.label, '여성');
    expect(PatientGender.female.apiValue, 'female');
  });

  test('maps the male display option to the API value', () {
    expect(PatientGender.male.label, '남성');
    expect(PatientGender.male.apiValue, 'male');
  });
}
