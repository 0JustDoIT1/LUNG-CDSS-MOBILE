import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/network/api_client.dart';
import 'package:patient_app/core/network/api_exception.dart';
import 'package:patient_app/features/appointment/data/appointment_api.dart';
import 'package:patient_app/features/appointment/data/appointment_repository.dart';

void main() {
  group('AppointmentRepository', () {
    test('parses a valid array', () async {
      final repository = AppointmentRepository(
        _FakeAppointmentApi(response: <dynamic>[_validJson]),
      );

      final appointments = await repository.getMyAppointments();

      expect(appointments, hasLength(1));
      expect(appointments.single.id, 'appointment-uuid');
    });

    test('parses an empty array', () async {
      final repository = AppointmentRepository(
        _FakeAppointmentApi(response: <dynamic>[]),
      );

      expect(await repository.getMyAppointments(), isEmpty);
    });

    test('rejects an array item that is not an object', () async {
      final repository = AppointmentRepository(
        _FakeAppointmentApi(response: <dynamic>['invalid']),
      );

      await expectLater(repository.getMyAppointments(), throwsFormatException);
    });

    test('preserves an ApiException from AppointmentApi', () async {
      const apiException = ApiException(
        message: 'Request failed',
        statusCode: 403,
      );
      final repository = AppointmentRepository(
        _FakeAppointmentApi(error: apiException),
      );

      await expectLater(
        repository.getMyAppointments(),
        throwsA(same(apiException)),
      );
    });

    test('completes cancelAppointment', () async {
      final api = _FakeAppointmentApi();
      final repository = AppointmentRepository(api);

      await repository.cancelAppointment('appointment-uuid');

      expect(api.cancelledAppointmentIds, <String>['appointment-uuid']);
    });

    test('preserves an ApiException from cancelAppointment', () async {
      const apiException = ApiException(
        message: 'Request failed',
        statusCode: 404,
      );
      final repository = AppointmentRepository(
        _FakeAppointmentApi(cancelError: apiException),
      );

      await expectLater(
        repository.cancelAppointment('appointment-uuid'),
        throwsA(same(apiException)),
      );
    });
  });
}

const _validJson = <String, dynamic>{
  'id': 'appointment-uuid',
  'patient_name': 'Patient',
  'doctor_name': 'Doctor',
  'department': 'Pulmonology',
  'requested_at_slot': '2026-08-10T09:00:00+09:00',
  'confirmed_slot': '2026-08-10T10:00:00+09:00',
  'status': 'confirmed',
  'created_at': '2026-08-05T10:00:00+09:00',
};

class _FakeAppointmentApi extends AppointmentApi {
  _FakeAppointmentApi({this.response, this.error, this.cancelError})
    : super(ApiClient(dio: Dio()));

  final List<dynamic>? response;
  final Object? error;
  final Object? cancelError;
  final List<String> cancelledAppointmentIds = <String>[];

  @override
  Future<List<dynamic>> getMyAppointments() async {
    if (error != null) {
      throw error!;
    }
    return response ?? <dynamic>[];
  }

  @override
  Future<void> cancelAppointment(String appointmentId) async {
    if (cancelError != null) {
      throw cancelError!;
    }
    cancelledAppointmentIds.add(appointmentId);
  }
}
