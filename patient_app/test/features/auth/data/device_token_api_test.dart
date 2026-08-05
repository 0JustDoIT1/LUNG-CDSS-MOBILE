import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/network/api_client.dart';
import 'package:patient_app/core/network/api_exception.dart';
import 'package:patient_app/features/auth/data/device_token_api.dart';
import 'package:patient_app/features/auth/data/models/device_token_registration.dart';

void main() {
  test('posts the exact Android registration body', () async {
    final client = _FakeApiClient();
    final api = DeviceTokenApi(client);
    await api.registerDeviceToken(
      DeviceTokenRegistration(
        fcmToken: 'fcm-value',
        platform: 'android',
        deviceId: 'device-value',
        deviceName: 'Android device',
      ),
    );

    expect(client.postPath, '/api/auth/device-token/');
    expect(client.postData, {
      'fcm_token': 'fcm-value',
      'platform': 'android',
      'app_type': 'patient_app',
      'device_id': 'device-value',
      'device_name': 'Android device',
    });
  });

  test('supports iOS and omits a null device name', () async {
    final client = _FakeApiClient();
    await DeviceTokenApi(client).registerDeviceToken(
      DeviceTokenRegistration(
        fcmToken: 'fcm-value',
        platform: 'ios',
        deviceId: 'device-value',
      ),
    );
    expect(client.postData, {
      'fcm_token': 'fcm-value',
      'platform': 'ios',
      'app_type': 'patient_app',
      'device_id': 'device-value',
    });
  });

  test(
    'deletes the current device with app_type as a query parameter',
    () async {
      final client = _FakeApiClient();
      await DeviceTokenApi(
        client,
      ).unregisterDeviceToken(deviceId: 'device-value');
      expect(client.deletePath, '/api/auth/device-token/device-value/');
      expect(client.deleteQuery, {'app_type': 'patient_app'});
    },
  );

  test(
    'preserves ApiException and accepts an empty success response',
    () async {
      await DeviceTokenApi(_FakeApiClient()).registerDeviceToken(
        DeviceTokenRegistration(
          fcmToken: 'fcm-value',
          platform: 'android',
          deviceId: 'device-value',
        ),
      );

      const error = ApiException(message: 'failed', statusCode: 403);
      await expectLater(
        DeviceTokenApi(
          _FakeApiClient(error: error),
        ).unregisterDeviceToken(deviceId: 'device-value'),
        throwsA(same(error)),
      );
    },
  );
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient({this.error}) : super(dio: Dio());
  final Object? error;
  String? postPath;
  Object? postData;
  String? deletePath;
  Map<String, dynamic>? deleteQuery;

  @override
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    if (error != null) throw error!;
    postPath = path;
    postData = data;
    return Response<T>(requestOptions: RequestOptions(path: path));
  }

  @override
  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    if (error != null) throw error!;
    deletePath = path;
    deleteQuery = queryParameters;
    return Response<T>(requestOptions: RequestOptions(path: path));
  }
}
