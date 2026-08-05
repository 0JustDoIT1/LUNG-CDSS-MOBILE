import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../data/models/appointment.dart';
import '../../../../data/repositories/appointment_repository.dart';
import '../../../../data/repositories/mock_appointment_repository.dart';
import '../../../auth/presentation/providers/auth_dependency_providers.dart';
import '../../data/appointment_api.dart';
import '../../data/appointment_repository.dart' as api_repository;
import '../../data/models/patient_appointment.dart';
import '../../data/models/appointment_booking.dart';

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

class AppointmentBookingState {
  const AppointmentBookingState({
    this.departments = const AsyncLoading(),
    this.doctors = const AsyncData(<AppointmentDoctor>[]),
    this.slots = const AsyncData(null),
    this.selectedDepartment,
    this.selectedDoctor,
    this.selectedDate,
    this.selectedSlot,
    this.isSubmitting = false,
    this.lastError,
  });

  final AsyncValue<List<AppointmentDepartment>> departments;
  final AsyncValue<List<AppointmentDoctor>> doctors;
  final AsyncValue<AppointmentSlots?> slots;
  final AppointmentDepartment? selectedDepartment;
  final AppointmentDoctor? selectedDoctor;
  final DateTime? selectedDate;
  final AppointmentSlot? selectedSlot;
  final bool isSubmitting;
  final Object? lastError;

  AppointmentBookingState copyWith({
    AsyncValue<List<AppointmentDepartment>>? departments,
    AsyncValue<List<AppointmentDoctor>>? doctors,
    AsyncValue<AppointmentSlots?>? slots,
    AppointmentDepartment? selectedDepartment,
    AppointmentDoctor? selectedDoctor,
    DateTime? selectedDate,
    AppointmentSlot? selectedSlot,
    bool clearDepartment = false,
    bool clearDoctor = false,
    bool clearDate = false,
    bool clearSlot = false,
    bool? isSubmitting,
    Object? lastError,
    bool clearError = false,
  }) => AppointmentBookingState(
    departments: departments ?? this.departments,
    doctors: doctors ?? this.doctors,
    slots: slots ?? this.slots,
    selectedDepartment: clearDepartment
        ? null
        : selectedDepartment ?? this.selectedDepartment,
    selectedDoctor: clearDoctor ? null : selectedDoctor ?? this.selectedDoctor,
    selectedDate: clearDate ? null : selectedDate ?? this.selectedDate,
    selectedSlot: clearSlot ? null : selectedSlot ?? this.selectedSlot,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    lastError: clearError ? null : lastError ?? this.lastError,
  );
}

final appointmentBookingProvider =
    NotifierProvider<AppointmentBookingNotifier, AppointmentBookingState>(
      AppointmentBookingNotifier.new,
    );

class AppointmentBookingNotifier extends Notifier<AppointmentBookingState> {
  @override
  AppointmentBookingState build() {
    Future<void>.microtask(loadDepartments);
    return const AppointmentBookingState();
  }

  Future<void> loadDepartments() async {
    state = state.copyWith(departments: const AsyncLoading());
    try {
      final data = await ref
          .read(myAppointmentRepositoryProvider)
          .fetchDepartments();
      state = state.copyWith(departments: AsyncData(data));
    } catch (error, stack) {
      state = state.copyWith(departments: AsyncError(error, stack));
    }
  }

  Future<void> selectDepartment(AppointmentDepartment department) async {
    state = state.copyWith(
      selectedDepartment: department,
      clearDoctor: true,
      clearDate: true,
      clearSlot: true,
      doctors: const AsyncLoading(),
      slots: const AsyncData(null),
      clearError: true,
    );
    try {
      final data = await ref
          .read(myAppointmentRepositoryProvider)
          .fetchDoctors(department.code);
      if (state.selectedDepartment?.code == department.code) {
        state = state.copyWith(doctors: AsyncData(data));
      }
    } catch (error, stack) {
      if (state.selectedDepartment?.code == department.code) {
        state = state.copyWith(doctors: AsyncError(error, stack));
      }
    }
  }

  void selectDoctor(AppointmentDoctor doctor) {
    state = state.copyWith(
      selectedDoctor: doctor,
      clearDate: true,
      clearSlot: true,
      slots: const AsyncData(null),
    );
  }

  Future<void> selectDate(DateTime date) async {
    final doctor = state.selectedDoctor;
    if (doctor == null) return;
    state = state.copyWith(
      selectedDate: date,
      clearSlot: true,
      slots: const AsyncLoading(),
      clearError: true,
    );
    final value = _date(date);
    try {
      final data = await ref
          .read(myAppointmentRepositoryProvider)
          .fetchDoctorSlots(doctorId: doctor.id, date: value);
      if (state.selectedDoctor?.id == doctor.id && state.selectedDate == date) {
        state = state.copyWith(slots: AsyncData(data));
      }
    } catch (error, stack) {
      state = state.copyWith(slots: AsyncError(error, stack));
    }
  }

  void selectSlot(AppointmentSlot slot) {
    if (slot.status != 'available') {
      return;
    }
    state = state.copyWith(selectedSlot: slot, clearError: true);
  }

  Future<bool> submit() async {
    if (state.isSubmitting) return false;
    final department = state.selectedDepartment;
    final doctor = state.selectedDoctor;
    final slot = state.selectedSlot;
    if (department == null ||
        doctor == null ||
        slot == null ||
        slot.status != 'available') {
      return false;
    }
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await ref
          .read(myAppointmentRepositoryProvider)
          .createAppointment(
            doctorId: doctor.id,
            department: department.code,
            requestedAtSlot: slot.dateTimeValue,
          );
      ref.invalidate(myAppointmentsProvider);
      return true;
    } catch (error) {
      state = state.copyWith(lastError: error);
      if (error is ApiException && error.statusCode == 409) {
        state = state.copyWith(clearSlot: true);
        await selectDate(state.selectedDate!);
        state = state.copyWith(lastError: error);
      }
      return false;
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }

  static String _date(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
