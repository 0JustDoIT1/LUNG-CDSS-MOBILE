import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/network/api_client.dart';
import 'package:patient_app/core/network/api_exception.dart';
import 'package:patient_app/features/convenience/data/notification_api.dart';

void main() {
  group('NotificationApi.markAsRead', () {
    test('posts to the read endpoint without a request body', () async {
      final apiClient = _FakeApiClient();
      final api = NotificationApi(apiClient);

      await api.markAsRead('notification-uuid');

      expect(apiClient.postCallCount, 1);
      expect(
        apiClient.lastPath,
        '/api/communication/notifications/notification-uuid/read/',
      );
      expect(apiClient.lastData, isNull);
    });

    test('rejects an empty notification id before making a request', () async {
      final apiClient = _FakeApiClient();
      final api = NotificationApi(apiClient);

      await expectLater(api.markAsRead('   '), throwsArgumentError);

      expect(apiClient.postCallCount, 0);
    });

    test('preserves an ApiException from ApiClient', () async {
      const apiException = ApiException(
        message: 'Request failed',
        statusCode: 403,
      );
      final apiClient = _FakeApiClient(error: apiException);
      final api = NotificationApi(apiClient);

      await expectLater(
        api.markAsRead('notification-uuid'),
        throwsA(same(apiException)),
      );
    });
  });
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient({this.error}) : super(dio: Dio());

  final Object? error;
  int postCallCount = 0;
  String? lastPath;
  Object? lastData;

  @override
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    postCallCount += 1;
    lastPath = path;
    lastData = data;

    if (error != null) {
      throw error!;
    }

    return Response<T>(requestOptions: RequestOptions(path: path));
  }
}
