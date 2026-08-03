import '../models/appointment.dart';

abstract class AppointmentRepository {
  Future<List<Appointment>> getAppointments();

  Future<Appointment?> getAppointmentById(
    String id,
  );

  Future<Appointment> updateAppointmentDate({
    required String appointmentId,
    required DateTime newAppointmentAt,
  });

  Future<Appointment> cancelAppointment(
    String appointmentId,
  );
}