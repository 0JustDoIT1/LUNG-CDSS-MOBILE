import 'intake_api.dart';
import 'models/intake_form.dart';

class IntakeRepository {
  IntakeRepository(this._api);

  final IntakeApi _api;

  Future<IntakeForm> fetchMyIntake() async {
    return IntakeForm.fromJson(await _api.fetchMyIntake());
  }

  Future<IntakeForm> saveMyIntake(IntakeContent content) async {
    return IntakeForm.fromJson(await _api.saveMyIntake(content));
  }
}
