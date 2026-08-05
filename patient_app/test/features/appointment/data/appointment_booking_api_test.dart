import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/network/api_client.dart';
import 'package:patient_app/core/network/api_exception.dart';
import 'package:patient_app/features/appointment/data/appointment_api.dart';

void main() {
  test('uses departments endpoint', () async {
    final client = _Client(<dynamic>[]);
    await AppointmentApi(client).fetchDepartments();
    expect(client.path, '/api/appointments/departments/');
  });

  test('uses department query for doctors', () async {
    final client = _Client(<dynamic>[]);
    await AppointmentApi(client).fetchDoctors('호흡기내과');
    expect(client.path, '/api/appointments/doctors/');
    expect(client.query, <String, dynamic>{'department': '호흡기내과'});
  });

  test('uses doctor and date for slots', () async {
    final client = _Client(<String, dynamic>{
      'date': '2026-08-10',
      'timezone': 'Asia/Seoul',
      'slots': <dynamic>[],
    });
    await AppointmentApi(
      client,
    ).fetchDoctorSlots(doctorId: 'doctor-id', date: '2026-08-10');
    expect(client.path, '/api/appointments/doctors/doctor-id/slots/');
    expect(client.query, <String, dynamic>{'date': '2026-08-10'});
  });

  test('posts exact appointment body and preserves 409', () async {
    final client = _Client(<String, dynamic>{});
    await AppointmentApi(client).createAppointment(
      doctorId: 'doctor-id',
      department: '호흡기내과',
      requestedAtSlot: '2026-08-10T09:30:00+09:00',
    );
    expect(client.path, '/api/appointments/');
    expect(client.data, <String, dynamic>{
      'doctor_id': 'doctor-id',
      'department': '호흡기내과',
      'requested_at_slot': '2026-08-10T09:30:00+09:00',
    });

    const error = ApiException(
      message: 'conflict',
      statusCode: 409,
      code: 'CONFLICT',
    );
    await expectLater(
      AppointmentApi(_Client(null, error: error)).createAppointment(
        doctorId: 'doctor-id',
        department: '호흡기내과',
        requestedAtSlot: 'slot',
      ),
      throwsA(same(error)),
    );
  });
}

class _Client extends ApiClient {
  _Client(this.response, {this.error}) : super(dio: Dio());
  final Object? response;
  final Object? error;
  String? path;
  Map<String, dynamic>? query;
  Object? data;

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    if (error != null) throw error!;
    this.path = path;
    query = queryParameters;
    return Response<T>(
      data: response as T?,
      requestOptions: RequestOptions(path: path),
    );
  }

  @override
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    if (error != null) throw error!;
    this.path = path;
    this.data = data;
    return Response<T>(
      data: response as T?,
      requestOptions: RequestOptions(path: path),
    );
  }
}
