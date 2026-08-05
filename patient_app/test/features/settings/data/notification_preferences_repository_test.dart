import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/network/api_client.dart';
import 'package:patient_app/features/settings/data/notification_preferences_api.dart';
import 'package:patient_app/features/settings/data/notification_preferences_repository.dart';

void main() {
  test('parses a complete preference array', () async {
    final repository = _repository(_completeResponse);
    final values = await repository.fetchNotificationPreferences();
    expect(values, hasLength(6));
    expect(values.last.category.apiValue, 'case_review');
  });

  test('rejects a duplicate category', () async {
    final response = [..._completeResponse, _completeResponse.first];
    await expectLater(
      _repository(response).fetchNotificationPreferences(),
      throwsFormatException,
    );
  });

  test('rejects a missing category instead of filling a default', () async {
    await expectLater(
      _repository(
        _completeResponse.sublist(0, 5),
      ).fetchNotificationPreferences(),
      throwsFormatException,
    );
  });

  test('rejects a non-object array item', () async {
    await expectLater(
      _repository(<dynamic>[
        ..._completeResponse.take(5),
        'invalid',
      ]).fetchNotificationPreferences(),
      throwsFormatException,
    );
  });
}

NotificationPreferencesRepository _repository(List<dynamic> response) {
  return NotificationPreferencesRepository(
    NotificationPreferencesApi(_ResponseApiClient(response)),
  );
}

class _ResponseApiClient extends ApiClient {
  _ResponseApiClient(this.response) : super(dio: Dio());
  final List<dynamic> response;

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async => Response<T>(
    data: response as T,
    requestOptions: RequestOptions(path: path),
  );
}

final _completeResponse = <dynamic>[
  {'category': 'all', 'enabled': false},
  {'category': 'medication', 'enabled': true},
  {'category': 'appointment', 'enabled': true},
  {'category': 'chat', 'enabled': false},
  {'category': 'triage', 'enabled': true},
  {'category': 'case_review', 'enabled': true},
];
