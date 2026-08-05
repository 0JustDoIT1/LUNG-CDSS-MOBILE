class DeviceTokenRegistration {
  DeviceTokenRegistration({
    required this.fcmToken,
    required this.platform,
    required this.deviceId,
    this.deviceName,
  }) {
    if (fcmToken.trim().isEmpty) {
      throw ArgumentError.value(fcmToken, 'fcmToken', '비어 있을 수 없습니다.');
    }
    if (platform != 'android' && platform != 'ios') {
      throw ArgumentError.value(platform, 'platform', 'android 또는 ios여야 합니다.');
    }
    if (deviceId.trim().isEmpty) {
      throw ArgumentError.value(deviceId, 'deviceId', '비어 있을 수 없습니다.');
    }
  }

  static const String appType = 'patient_app';

  final String fcmToken;
  final String platform;
  final String deviceId;
  final String? deviceName;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'fcm_token': fcmToken,
    'platform': platform,
    'app_type': appType,
    'device_id': deviceId,
    if (deviceName != null) 'device_name': deviceName,
  };
}
