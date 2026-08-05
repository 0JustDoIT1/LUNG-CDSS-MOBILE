import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/appointment.dart';
import '../../../../data/repositories/appointment_repository.dart';
import '../../../../data/repositories/mock_appointment_repository.dart';
import '../../../auth/presentation/providers/auth_dependency_providers.dart';
import '../../data/appointment_api.dart';
import '../../data/appointment_repository.dart' as api_repository;
import '../../data/models/patient_appointment.dart';

final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  return MockAppointmentRepository();
});

final appointmentsProvider =
    AsyncNotifierProvider<AppointmentsNotifier, List<Appointment>>(
      AppointmentsNotifier.new,
    );

class AppointmentsNotifier extends AsyncNotifier<List<Appointment>> {
  @override
  Future<List<Appointment>> build() async {
    final repository = ref.read(appointmentRepositoryProvider);

    return repository.getAppointments();
  }

  Future<bool> updateAppointmentDate({
    required String appointmentId,
    required DateTime newAppointmentAt,
  }) async {
    final repository = ref.read(appointmentRepositoryProvider);

    try {
      await repository.updateAppointmentDate(
        appointmentId: appointmentId,
        newAppointmentAt: newAppointmentAt,
      );

      state = AsyncData(await repository.getAppointments());

      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }

  Future<bool> cancelAppointment(String appointmentId) async {
    final repository = ref.read(appointmentRepositoryProvider);

    try {
      await repository.cancelAppointment(appointmentId);

      state = AsyncData(await repository.getAppointments());

      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }
}

final appointmentDetailProvider = FutureProvider.family<Appointment?, String>((
  ref,
  appointmentId,
) async {
  final appointments = await ref.watch(appointmentsProvider.future);

  for (final appointment in appointments) {
    if (appointment.id == appointmentId) {
      return appointment;
    }
  }

  return null;
});

final appointmentApiProvider = Provider<AppointmentApi>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AppointmentApi(apiClient);
});

final myAppointmentRepositoryProvider =
    Provider<api_repository.AppointmentRepository>((ref) {
      final appointmentApi = ref.watch(appointmentApiProvider);
      return api_repository.AppointmentRepository(appointmentApi);
    });

final myAppointmentsProvider = FutureProvider<List<PatientAppointment>>((
  ref,
) async {
  final repository = ref.read(myAppointmentRepositoryProvider);
  return repository.getMyAppointments();
});

final appointmentCancelProvider =
    NotifierProvider<AppointmentCancelNotifier, Set<String>>(
      AppointmentCancelNotifier.new,
    );

class AppointmentCancelNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  Future<void> cancelAppointment(String appointmentId) async {
    if (state.contains(appointmentId)) {
      return;
    }

    state = <String>{...state, appointmentId};

    try {
      final repository = ref.read(myAppointmentRepositoryProvider);
      await repository.cancelAppointment(appointmentId);
      ref.invalidate(myAppointmentsProvider);
      await ref.read(myAppointmentsProvider.future);
    } finally {
      state = <String>{...state}..remove(appointmentId);
    }
  }
}
