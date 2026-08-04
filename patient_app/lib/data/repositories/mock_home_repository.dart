import '../mock/mock_home_data.dart';
import '../models/home_summary.dart';
import 'home_repository.dart';

class MockHomeRepository implements HomeRepository {
  @override
  Future<HomeSummary> getHomeSummary() async {
    await Future<void>.delayed(
      const Duration(milliseconds: 500),
    );

    return MockHomeData.summary;
  }
}