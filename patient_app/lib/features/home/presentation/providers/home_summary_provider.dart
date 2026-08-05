import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/home_summary.dart';
import '../../../../data/repositories/home_repository.dart';
import '../../../../data/repositories/mock_home_repository.dart';
import '../../../symptom/presentation/providers/symptom_medication_provider.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return MockHomeRepository();
});

final homeSummaryProvider = FutureProvider<HomeSummary>((ref) async {
  final repository = ref.read(homeRepositoryProvider);
  final summary = await repository.getHomeSummary();

  final recordsState = ref.watch(symptomRecordsProvider);
  final records = recordsState.asData?.value ?? [];

  final now = DateTime.now();

  final hasSymptomRecordToday = records.any((record) {
    final recordedAt = record.recordedAt;

    return recordedAt.year == now.year &&
        recordedAt.month == now.month &&
        recordedAt.day == now.day;
  });

  return summary.copyWith(
    hasSymptomRecordToday: hasSymptomRecordToday,
  );
});