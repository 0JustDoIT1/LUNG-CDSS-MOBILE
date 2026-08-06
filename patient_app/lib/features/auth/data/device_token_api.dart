import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import 'models/device_token_registration.dart';

class DeviceTokenApi {
  DeviceTokenApi(this._apiClient);

  final ApiClient _apiClient;

  Future<void> registerDeviceToken(DeviceTokenRegistration registration) async {
    debugPrint('[DeviceToken] POST /api/auth/device-token/ started');
    final response = await _apiClient.post<void>(
      '/api/auth/device-token/',
      data: registration.toJson(),
    );
    debugPrint(
      '[DeviceToken] POST /api/auth/device-token/ '
      'status=${response.statusCode}',
    );
  }

  Future<void> unregisterDeviceToken({required String deviceId}) async {
    if (deviceId.trim().isEmpty) {
      throw ArgumentError.value(deviceId, 'deviceId', '비어 있을 수 없습니다.');
    }
    await _apiClient.delete<void>(
      '/api/auth/device-token/$deviceId/',
      queryParameters: const <String, dynamic>{
        'app_type': DeviceTokenRegistration.appType,
      },
    );
  }
}
