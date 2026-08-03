import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/appointment.dart';
import '../../../../data/repositories/appointment_repository.dart';
import '../../../../data/repositories/mock_appointment_repository.dart';

final appointmentRepositoryProvider =
    Provider<AppointmentRepository>((ref) {
  return MockAppointmentRepository();
});

final appointmentsProvider =
    AsyncNotifierProvider<
      AppointmentsNotifier,
      List<Appointment>
    >(
  AppointmentsNotifier.new,
);

class AppointmentsNotifier
    extends AsyncNotifier<List<Appointment>> {
  @override
  Future<List<Appointment>> build() async {
    final repository = ref.read(
      appointmentRepositoryProvider,
    );

    return repository.getAppointments();
  }

  Future<bool> updateAppointmentDate({
    required String appointmentId,
    required DateTime newAppointmentAt,
  }) async {
    final repository = ref.read(
      appointmentRepositoryProvider,
    );

    try {
      await repository.updateAppointmentDate(
        appointmentId: appointmentId,
        newAppointmentAt: newAppointmentAt,
      );

      state = AsyncData(
        await repository.getAppointments(),
      );

      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }

  Future<bool> cancelAppointment(
    String appointmentId,
  ) async {
    final repository = ref.read(
      appointmentRepositoryProvider,
    );

    try {
      await repository.cancelAppointment(
        appointmentId,
      );

      state = AsyncData(
        await repository.getAppointments(),
      );

      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }
}

final appointmentDetailProvider =
    FutureProvider.family<Appointment?, String>(
  (ref, appointmentId) async {
    final appointments = await ref.watch(
      appointmentsProvider.future,
    );

    for (final appointment in appointments) {
      if (appointment.id == appointmentId) {
        return appointment;
      }
    }

    return null;
  },
);