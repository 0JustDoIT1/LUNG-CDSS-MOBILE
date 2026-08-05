import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/features/auth/data/models/auth_result.dart';

void main() {
  test('parses female from a registration response', () {
    final result = AuthResult.fromJson({
      'access': 'access-token',
      'refresh': 'refresh-token',
      'gender': 'female',
    });

    expect(result.gender, 'female');
  });

  test('keeps a null registration gender', () {
    final result = AuthResult.fromJson({
      'access': 'access-token',
      'refresh': 'refresh-token',
      'gender': null,
    });

    expect(result.gender, isNull);
  });

  test('rejects a non-string registration gender', () {
    expect(() => AuthResult.fromJson({'gender': true}), throwsFormatException);
  });
}
