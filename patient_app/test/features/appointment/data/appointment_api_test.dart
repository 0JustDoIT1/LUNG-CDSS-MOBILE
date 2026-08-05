import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/network/api_client.dart';
import 'package:patient_app/core/network/api_exception.dart';
import 'package:patient_app/features/appointment/data/appointment_api.dart';

void main() {
  group('AppointmentApi.cancelAppointment', () {
    test('posts to the cancel endpoint without a request body', () async {
      final apiClient = _FakeApiClient();
      final api = AppointmentApi(apiClient);

      await api.cancelAppointment('appointment-uuid');

      expect(apiClient.postCallCount, 1);
      expect(apiClient.lastPath, '/api/appointments/appointment-uuid/cancel/');
      expect(apiClient.lastData, isNull);
    });

    test('rejects an empty id before making a request', () async {
      final apiClient = _FakeApiClient();
      final api = AppointmentApi(apiClient);

      await expectLater(api.cancelAppointment('   '), throwsArgumentError);

      expect(apiClient.postCallCount, 0);
    });

    test('preserves an ApiException from ApiClient', () async {
      const apiException = ApiException(
        message: 'Request failed',
        statusCode: 403,
      );
      final api = AppointmentApi(_FakeApiClient(error: apiException));

      await expectLater(
        api.cancelAppointment('appointment-uuid'),
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
