import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/features/intake/data/models/patient_qr_token.dart';

void main() {
  final now = DateTime(2026, 8, 6, 12);

  test('parses exact fields and computes five-minute expiry', () {
    final value = PatientQrToken.fromJson(<String, dynamic>{
      'token': 'server-token',
      'expires_in': 300,
    }, now: now);
    expect(value.token, 'server-token');
    expect(value.expiresIn, 300);
    expect(value.expiresAt, DateTime(2026, 8, 6, 12, 5));
  });

  test('rejects empty tokens and invalid expiry values', () {
    for (final json in <Map<String, dynamic>>[
      <String, dynamic>{'token': '', 'expires_in': 300},
      <String, dynamic>{'token': 'token', 'expires_in': 0},
      <String, dynamic>{'token': 'token', 'expires_in': '300'},
      <String, dynamic>{'token': 'token', 'expires_in': 1.5},
    ]) {
      expect(
        () => PatientQrToken.fromJson(json, now: now),
        throwsFormatException,
      );
    }
  });
}
