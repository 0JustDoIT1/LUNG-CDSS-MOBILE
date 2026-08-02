import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/home_summary.dart';
import '../../../../data/repositories/home_repository.dart';
import '../../../../data/repositories/mock_home_repository.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return MockHomeRepository();
});

final homeSummaryProvider = FutureProvider<HomeSummary>((ref) async {
  final repository = ref.read(homeRepositoryProvider);

  return repository.getHomeSummary();
});