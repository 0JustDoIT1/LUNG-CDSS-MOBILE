import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/network/api_client.dart';
import 'package:patient_app/core/network/api_exception.dart';
import 'package:patient_app/features/symptom/data/medication_api.dart';
import 'package:patient_app/features/symptom/data/medication_repository.dart';

void main() {
  group('MedicationRepository', () {
    test('parses a valid array', () {
      final logs = MedicationRepository.parseMedicationLogs([
        {
          'id': 'medication-log-uuid',
          'drug_name': 'Medication',
          'dosage': 'One tablet',
          'scheduled_time': '2026-08-05T09:00:00+09:00',
          'taken': false,
          'taken_at': null,
        },
      ]);

      expect(logs, hasLength(1));
      expect(logs.single.drugName, 'Medication');
    });

    test('parses an empty array', () {
      final logs = MedicationRepository.parseMedicationLogs(<dynamic>[]);

      expect(logs, isEmpty);
    });

    test('rejects an array item that is not an object', () {
      expect(
        () => MedicationRepository.parseMedicationLogs(<dynamic>['invalid']),
        throwsFormatException,
      );
    });

    test('preserves an ApiException from MedicationApi', () async {
      const apiException = ApiException(
        message: 'Request failed',
        statusCode: 403,
      );
      final repository = MedicationRepository(
        _FakeMedicationApi(error: apiException),
      );

      await expectLater(
        repository.getTodayMedicationLogs(),
        throwsA(same(apiException)),
      );
    });

    test('parses the mark-as-taken response', () async {
      final repository = MedicationRepository(
        _FakeMedicationApi(markAsTakenResponse: _validTakenResponse),
      );

      final log = await repository.markAsTaken('medication-log-uuid');

      expect(log.id, 'medication-log-uuid');
      expect(log.taken, isTrue);
      expect(log.takenAt, isNotNull);
    });

    test('preserves a format error in the mark-as-taken response', () async {
      final repository = MedicationRepository(
        _FakeMedicationApi(
          markAsTakenResponse: <String, dynamic>{
            ..._validTakenResponse,
            'taken': 'true',
          },
        ),
      );

      await expectLater(
        repository.markAsTaken('medication-log-uuid'),
        throwsFormatException,
      );
    });

    test('preserves an ApiException from markAsTaken', () async {
      const apiException = ApiException(
        message: 'Request failed',
        statusCode: 404,
      );
      final repository = MedicationRepository(
        _FakeMedicationApi(markAsTakenError: apiException),
      );

      await expectLater(
        repository.markAsTaken('medication-log-uuid'),
        throwsA(same(apiException)),
      );
    });
  });
}

const _validTakenResponse = <String, dynamic>{
  'id': 'medication-log-uuid',
  'drug_name': 'Medication',
  'dosage': 'One tablet',
  'scheduled_time': '2026-08-05T09:00:00+09:00',
  'taken': true,
  'taken_at': '2026-08-05T09:05:00+09:00',
};

class _FakeMedicationApi extends MedicationApi {
  _FakeMedicationApi({
    this.error,
    this.markAsTakenResponse,
    this.markAsTakenError,
  }) : super(ApiClient(dio: Dio()));

  final Object? error;
  final Map<String, dynamic>? markAsTakenResponse;
  final Object? markAsTakenError;

  @override
  Future<List<dynamic>> getTodayMedicationLogs() async {
    if (error != null) {
      throw error!;
    }

    return <dynamic>[];
  }

  @override
  Future<Map<String, dynamic>> markAsTaken(String logId) async {
    if (markAsTakenError != null) {
      throw markAsTakenError!;
    }

    return markAsTakenResponse ?? _validTakenResponse;
  }
}
