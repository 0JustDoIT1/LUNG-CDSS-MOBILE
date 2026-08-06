import '../../../core/auth/auth_role.dart';
import '../../../core/auth/token_storage.dart';
import 'guardian_api.dart';
import 'models/guardian_auth_result.dart';
import 'models/guardian_invite.dart';
import 'models/guardian_appointment.dart';
import 'models/guardian_medication.dart';
import 'models/guardian_patient.dart';
import 'models/guardian_result.dart';

class GuardianRepository {
  GuardianRepository(this._api, this._tokenStorage);

  final GuardianApi _api;
  final TokenStorage _tokenStorage;

  Future<GuardianInvite> createGuardianInvite() async {
    return GuardianInvite.fromJson(await _api.createGuardianInvite());
  }

  Future<void> registerGuardian({
    required String inviteCode,
    required String name,
  }) async {
    final json = await _api.registerGuardian(
      inviteCode: inviteCode,
      name: name,
    );
    final result = GuardianAuthResult.fromJson(json);
    await _tokenStorage.saveSession(
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
      role: AuthRole.guardian,
    );
  }

  Future<List<GuardianPatient>> getGuardianPatients() async =>
      _parse(await _api.getGuardianPatients(), GuardianPatient.fromJson);

  Future<List<GuardianAppointment>> getGuardianAppointments(
    String patientId,
  ) async => _parse(
    await _api.getGuardianAppointments(patientId),
    GuardianAppointment.fromJson,
  );

  Future<List<GuardianMedication>> getGuardianMedications(
    String patientId,
  ) async => _parse(
    await _api.getGuardianMedications(patientId),
    GuardianMedication.fromJson,
  );

  Future<List<GuardianResult>> getGuardianResults(String patientId) async =>
      _parse(await _api.getGuardianResults(patientId), GuardianResult.fromJson);

  static List<T> _parse<T>(
    List<dynamic> values,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    return values
        .map((value) {
          if (value is! Map<String, dynamic>) {
            throw const FormatException('보호자 조회 항목은 객체여야 합니다.');
          }
          return fromJson(value);
        })
        .toList(growable: false);
  }
}
