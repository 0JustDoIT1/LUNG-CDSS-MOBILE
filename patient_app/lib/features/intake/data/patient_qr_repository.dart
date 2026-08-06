import 'models/patient_qr_token.dart';
import 'patient_qr_api.dart';

class PatientQrRepository {
  PatientQrRepository(this._api, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final PatientQrApi _api;
  final DateTime Function() _now;

  Future<PatientQrToken> issue() async {
    return PatientQrToken.fromJson(await _api.issue(), now: _now());
  }
}
