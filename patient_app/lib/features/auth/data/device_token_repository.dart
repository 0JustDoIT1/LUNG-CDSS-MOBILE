import 'device_token_api.dart';
import 'models/device_token_registration.dart';

class DeviceTokenRepository {
  DeviceTokenRepository(this._api);

  final DeviceTokenApi _api;

  Future<void> registerDeviceToken(DeviceTokenRegistration registration) {
    return _api.registerDeviceToken(registration);
  }

  Future<void> unregisterDeviceToken(String deviceId) {
    return _api.unregisterDeviceToken(deviceId: deviceId);
  }
}
