import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/features/auth/data/models/device_token_registration.dart';

void main() {
  test('accepts only backend-supported mobile platforms', () {
    for (final platform in ['android', 'ios']) {
      expect(
        DeviceTokenRegistration(
          fcmToken: 'token',
          platform: platform,
          deviceId: 'device-id',
        ).platform,
        platform,
      );
    }
    expect(
      () => DeviceTokenRegistration(
        fcmToken: 'token',
        platform: 'web',
        deviceId: 'device-id',
      ),
      throwsArgumentError,
    );
  });
}
