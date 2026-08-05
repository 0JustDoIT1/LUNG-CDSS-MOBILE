import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/features/auth/data/device_identity_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  test(
    'creates an installation id once and returns the same value later',
    () async {
      var generations = 0;
      final storage = DeviceIdentityStorage(
        idGenerator: () {
          generations++;
          return 'generated-device-id';
        },
      );

      expect(await storage.getOrCreateDeviceId(), 'generated-device-id');
      expect(await storage.getOrCreateDeviceId(), 'generated-device-id');
      expect(generations, 1);
    },
  );

  test('clearing registration cache preserves the installation id', () async {
    final storage = DeviceIdentityStorage(idGenerator: () => 'installation-id');
    await storage.getOrCreateDeviceId();
    await storage.saveRegisteredFcmToken('fcm-value');

    await storage.clearRegisteredFcmToken();

    expect(await storage.readDeviceId(), 'installation-id');
    expect(await storage.readRegisteredFcmToken(), isNull);
  });
}
