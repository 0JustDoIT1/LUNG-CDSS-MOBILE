import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/features/settings/data/models/notification_preference.dart';

void main() {
  test('parses every supported category and boolean value', () {
    const values = <String>[
      'all',
      'medication',
      'appointment',
      'chat',
      'triage',
      'case_review',
    ];

    for (var index = 0; index < values.length; index++) {
      final preference = NotificationPreference.fromJson({
        'category': values[index],
        'enabled': index.isEven,
      });
      expect(preference.category.apiValue, values[index]);
      expect(preference.enabled, index.isEven);
    }
  });

  test('rejects an unsupported category', () {
    expect(
      () => NotificationPreference.fromJson({
        'category': 'unknown',
        'enabled': true,
      }),
      throwsFormatException,
    );
  });

  test('rejects a non-boolean enabled value', () {
    expect(
      () => NotificationPreference.fromJson({
        'category': 'chat',
        'enabled': 'true',
      }),
      throwsFormatException,
    );
  });
}
