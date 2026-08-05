import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/network/api_client.dart';
import 'package:patient_app/core/network/api_exception.dart';
import 'package:patient_app/features/settings/data/models/notification_preference.dart';
import 'package:patient_app/features/settings/data/notification_preferences_api.dart';

void main() {
  test('uses the exact GET endpoint', () async {
    final client = _FakeApiClient(getData: <dynamic>[]);
    await NotificationPreferencesApi(client).fetchNotificationPreferences();
    expect(client.getPath, '/api/auth/notifications/preferences/');
  });

  test('uses the exact PATCH endpoint and individual category body', () async {
    final client = _FakeApiClient(
      patchData: <String, dynamic>{'category': 'chat', 'enabled': false},
    );
    await NotificationPreferencesApi(client).updateNotificationPreference(
      category: NotificationPreferenceCategory.chat,
      enabled: false,
    );
    expect(client.patchPath, '/api/auth/notifications/preferences/update/');
    expect(client.patchBody, {'category': 'chat', 'enabled': false});
  });

  test('sends all as one PATCH request', () async {
    final client = _FakeApiClient(
      patchData: <String, dynamic>{'category': 'all', 'enabled': true},
    );
    await NotificationPreferencesApi(client).updateNotificationPreference(
      category: NotificationPreferenceCategory.all,
      enabled: true,
    );
    expect(client.patchCalls, 1);
    expect(client.patchBody, {'category': 'all', 'enabled': true});
  });

  test('preserves ApiException', () async {
    const error = ApiException(message: 'failed', statusCode: 403);
    final api = NotificationPreferencesApi(_FakeApiClient(error: error));
    await expectLater(api.fetchNotificationPreferences(), throwsA(same(error)));
  });
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient({this.getData, this.patchData, this.error})
    : super(dio: Dio());

  final Object? getData;
  final Object? patchData;
  final Object? error;
  String? getPath;
  String? patchPath;
  Object? patchBody;
  int patchCalls = 0;

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    getPath = path;
    if (error != null) throw error!;
    return Response<T>(
      data: getData as T?,
      requestOptions: RequestOptions(path: path),
    );
  }

  @override
  Future<Response<T>> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    patchCalls++;
    patchPath = path;
    patchBody = data;
    if (error != null) throw error!;
    return Response<T>(
      data: patchData as T?,
      requestOptions: RequestOptions(path: path),
    );
  }
}
