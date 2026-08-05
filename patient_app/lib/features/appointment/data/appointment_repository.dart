import 'appointment_api.dart';
import 'models/patient_appointment.dart';

class AppointmentRepository {
  AppointmentRepository(this._appointmentApi);

  final AppointmentApi _appointmentApi;

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
