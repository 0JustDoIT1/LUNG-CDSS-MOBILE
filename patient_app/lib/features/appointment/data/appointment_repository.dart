import 'appointment_api.dart';
import 'models/patient_appointment.dart';
import 'models/appointment_booking.dart';

class AppointmentRepository {
  AppointmentRepository(this._appointmentApi);

  final AppointmentApi _appointmentApi;

  Future<List<AppointmentDepartment>> fetchDepartments() async =>
      (await _appointmentApi.fetchDepartments())
          .map((item) {
            if (item is! Map<String, dynamic>) {
              throw const FormatException('진료과는 객체여야 합니다.');
            }
            return AppointmentDepartment.fromJson(item);
          })
          .toList(growable: false);

  Future<List<AppointmentDoctor>> fetchDoctors(String department) async =>
      (await _appointmentApi.fetchDoctors(department))
          .map((item) {
            if (item is! Map<String, dynamic>) {
              throw const FormatException('의료진은 객체여야 합니다.');
            }
            return AppointmentDoctor.fromJson(item);
          })
          .toList(growable: false);

  Future<AppointmentSlots> fetchDoctorSlots({
    required String doctorId,
    required String date,
  }) async => AppointmentSlots.fromJson(
    await _appointmentApi.fetchDoctorSlots(doctorId: doctorId, date: date),
  );

  Future<PatientAppointment> createAppointment({
    required String doctorId,
    required String department,
    required String requestedAtSlot,
  }) async => PatientAppointment.fromJson(
    await _appointmentApi.createAppointment(
      doctorId: doctorId,
      department: department,
      requestedAtSlot: requestedAtSlot,
    ),
  );

  Future<List<PatientAppointment>> getMyAppointments() async {
    final appointments = await _appointmentApi.getMyAppointments();
    return parseAppointments(appointments);
  }

  Future<void> cancelAppointment(String appointmentId) {
    return _appointmentApi.cancelAppointment(appointmentId);
  }

  static List<PatientAppointment> parseAppointments(
    List<dynamic> appointments,
  ) {
    return appointments
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const FormatException('예약 목록의 각 항목은 객체여야 합니다.');
          }
          return PatientAppointment.fromJson(item);
        })
        .toList(growable: false);
  }
}
