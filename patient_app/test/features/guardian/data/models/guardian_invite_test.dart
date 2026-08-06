import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/features/guardian/data/models/guardian_invite.dart';

void main() {
  test('parses the GuardianLink serializer response', () {
    final invite = GuardianInvite.fromJson(<String, dynamic>{
      'id': 'link-id',
      'invite_code': 'SERVER1',
      'guardian_name': null,
      'invited_at': '2026-08-06T10:00:00+09:00',
      'accepted_at': null,
    });

    expect(invite.id, 'link-id');
    expect(invite.inviteCode, 'SERVER1');
    expect(invite.guardianName, isNull);
    expect(invite.invitedAt, DateTime.parse('2026-08-06T10:00:00+09:00'));
    expect(invite.acceptedAt, isNull);
  });

  test('rejects a malformed invite response', () {
    expect(
      () => GuardianInvite.fromJson(<String, dynamic>{
        'id': 'link-id',
        'invite_code': 'SERVER1',
        'guardian_name': null,
        'invited_at': 'not-a-date',
        'accepted_at': null,
      }),
      throwsFormatException,
    );
  });
}
