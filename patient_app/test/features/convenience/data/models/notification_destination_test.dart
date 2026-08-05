import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/features/convenience/data/models/notification_destination.dart';

void main() {
  final validCases = <String, NotificationDestinationType>{
    '/results/case-id': NotificationDestinationType.result,
    '/appointments/appointment-id': NotificationDestinationType.appointment,
    '/medications/logs/log-id': NotificationDestinationType.medication,
    '/symptoms/check-id': NotificationDestinationType.symptom,
    '/chat/thread-id': NotificationDestinationType.chat,
  };

  for (final entry in validCases.entries) {
    test('parses ${entry.key}', () {
      final destination = NotificationDeepLinkParser.parse(entry.key);
      expect(destination?.type, entry.value);
      expect(destination?.id, entry.key.split('/').last);
    });
  }

  test('parses the path of an absolute URL', () {
    final destination = NotificationDeepLinkParser.parse(
      'https://example.test/results/case-id?ignored=true',
    );
    expect(destination?.type, NotificationDestinationType.result);
    expect(destination?.id, 'case-id');
  });

  for (final value in <String?>[
    null,
    '',
    '   ',
    '%',
    '/results',
    '/results/',
    '/unknown/id',
    '/results/id/extra',
    '/results/{case_id}',
    '/results/%7Bcase_id%7D',
    '/results/case%20id',
    '/medications/logs',
  ]) {
    test('rejects invalid link $value', () {
      expect(NotificationDeepLinkParser.parse(value), isNull);
    });
  }
}
