import '../mock/mock_appointment_data.dart';
import '../models/appointment.dart';
import 'appointment_repository.dart';

class MockAppointmentRepository implements AppointmentRepository {
  final List<Appointment> _appointments =
      List<Appointment>.from(
    MockAppointmentData.appointments,
  );

  @override
  Future<List<Appointment>> getAppointments() async {
    await Future<void>.delayed(
      const Duration(milliseconds: 400),
    );

    final appointments = List<Appointment>.from(
      _appointments,
    );

    appointments.sort(
      (a, b) => a.appointmentAt.compareTo(
        b.appointmentAt,
      ),
    );

    return appointments;
  }

  @override
  Future<Appointment?> getAppointmentById(
    String id,
  ) async {
    await Future<void>.delayed(
      const Duration(milliseconds: 300),
    );

    for (final appointment in _appointments) {
      if (appointment.id == id) {
        return appointment;
      }
    }

    return null;
  }

  @override
  Future<Appointment> updateAppointmentDate({
    required String appointmentId,
    required DateTime newAppointmentAt,
  }) async {
    await Future<void>.delayed(
      const Duration(milliseconds: 400),
    );

    final index = _appointments.indexWhere(
      (appointment) => appointment.id == appointmentId,
    );

    if (index == -1) {
      throw Exception('예약 정보를 찾을 수 없습니다.');
    }

    final current = _appointments[index];

    if (current.status != AppointmentStatus.scheduled) {
      throw Exception('예정된 예약만 변경할 수 있습니다.');
    }

    final updated = current.copyWith(
      appointmentAt: newAppointmentAt,
    );

    _appointments[index] = updated;

    return updated;
  }

  @override
  Future<Appointment> cancelAppointment(
    String appointmentId,
  ) async {
    await Future<void>.delayed(
      const Duration(milliseconds: 400),
    );

    final index = _appointments.indexWhere(
      (appointment) => appointment.id == appointmentId,
    );

    if (index == -1) {
      throw Exception('예약 정보를 찾을 수 없습니다.');
    }

    final current = _appointments[index];

    if (current.status != AppointmentStatus.scheduled) {
      throw Exception('예정된 예약만 취소할 수 있습니다.');
    }

    final updated = current.copyWith(
      status: AppointmentStatus.cancelled,
    );

    _appointments[index] = updated;

    return updated;
  }
}