import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/medication_schedule.dart';
import '../../../../data/repositories/mock_symptom_medication_repository.dart';
import '../../../../data/repositories/symptom_medication_repository.dart';
import '../../../auth/presentation/providers/auth_dependency_providers.dart';
import '../../data/medication_api.dart';
import '../../data/medication_repository.dart';
import '../../data/models/medication_log.dart';
import '../../data/models/symptom_record.dart';
import '../../data/models/symptom_submit_request.dart';
import '../../data/symptom_api.dart';
import '../../data/symptom_repository.dart';

final symptomMedicationRepositoryProvider =
    Provider<SymptomMedicationRepository>((ref) {
      return MockSymptomMedicationRepository();
    });

final medicationSchedulesProvider =
    AsyncNotifierProvider<
      MedicationSchedulesNotifier,
      List<MedicationSchedule>
    >(MedicationSchedulesNotifier.new);

class MedicationSchedulesNotifier
    extends AsyncNotifier<List<MedicationSchedule>> {
  @override
  Future<List<MedicationSchedule>> build() async {
    final repository = ref.read(symptomMedicationRepositoryProvider);

    return repository.getMedicationSchedules();
  }

  Future<void> updateTakenStatus({
    required String medicationId,
    required bool isTaken,
  }) async {
    final repository = ref.read(symptomMedicationRepositoryProvider);

    final previousState = state;

    state = await AsyncValue.guard(() async {
      await repository.updateMedicationTakenStatus(
        medicationId: medicationId,
        isTaken: isTaken,
      );

      return repository.getMedicationSchedules();
    });

    if (state.hasError) {
      state = previousState;
    }
  }
}

final medicationApiProvider = Provider<MedicationApi>((ref) {
  final apiClient = ref.watch(apiClientProvider);

  return MedicationApi(apiClient);
});

final medicationRepositoryProvider = Provider<MedicationRepository>((ref) {
  final medicationApi = ref.watch(medicationApiProvider);

  return MedicationRepository(medicationApi);
});

final todayMedicationLogsProvider = FutureProvider<List<MedicationLog>>((
  ref,
) async {
  final repository = ref.read(medicationRepositoryProvider);

  return repository.getTodayMedicationLogs();
});

final medicationTakenProvider =
    NotifierProvider<MedicationTakenNotifier, Set<String>>(
      MedicationTakenNotifier.new,
    );

class MedicationTakenNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  Future<void> markAsTaken(String logId) async {
    if (state.contains(logId)) {
      return;
    }

    state = <String>{...state, logId};

    try {
      final repository = ref.read(medicationRepositoryProvider);
      await repository.markAsTaken(logId);
      ref.invalidate(todayMedicationLogsProvider);
      await ref.read(todayMedicationLogsProvider.future);
    } finally {
      state = <String>{...state}..remove(logId);
    }
  }
}

final symptomApiProvider = Provider<SymptomApi>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SymptomApi(apiClient);
});

final symptomRepositoryProvider = Provider<SymptomRepository>((ref) {
  final symptomApi = ref.watch(symptomApiProvider);
  return SymptomRepository(symptomApi);
});

final symptomRecordsProvider = FutureProvider<List<SymptomRecord>>((ref) {
  final repository = ref.read(symptomRepositoryProvider);
  return repository.fetchMySymptomRecords();
});

final symptomSubmitProvider = NotifierProvider<SymptomSubmitNotifier, bool>(
  SymptomSubmitNotifier.new,
);

class SymptomSubmitNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  Future<void> submit(SymptomSubmitRequest request) async {
    if (state) {
      return;
    }

    state = true;
    try {
      final repository = ref.read(symptomRepositoryProvider);
      await repository.submitSymptoms(request);
      ref.invalidate(symptomRecordsProvider);
    } finally {
      state = false;
    }
  }
}
