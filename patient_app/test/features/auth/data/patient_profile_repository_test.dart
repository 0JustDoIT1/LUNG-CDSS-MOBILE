import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/auth/token_storage.dart';
import 'package:patient_app/core/network/api_client.dart';
import 'package:patient_app/core/network/api_exception.dart';
import 'package:patient_app/features/auth/data/auth_api.dart';
import 'package:patient_app/features/auth/data/auth_repository.dart';

void main() {
  group('AuthRepository.getPatientProfile', () {
    test('converts a valid object to PatientProfile', () async {
      final repository = _repository(_FakeAuthApi(response: _validJson));

      final profile = await repository.getPatientProfile();

      expect(profile.name, 'Patient');
      expect(profile.patientNumber, 'P-001');
    });

    test('rejects a response that is not an object', () async {
      final repository = _repository(_FakeAuthApi(response: <dynamic>[]));

      await expectLater(repository.getPatientProfile(), throwsFormatException);
    });

    test('preserves an ApiException', () async {
      const apiException = ApiException(
        message: 'Request failed',
        statusCode: 403,
      );
      final repository = _repository(_FakeAuthApi(error: apiException));

      await expectLater(
        repository.getPatientProfile(),
        throwsA(same(apiException)),
      );
    });

    test('preserves a FormatException from model parsing', () async {
      final repository = _repository(
        _FakeAuthApi(response: {..._validJson, 'birth_date': 'invalid'}),
      );

      await expectLater(repository.getPatientProfile(), throwsFormatException);
    });
  });

  group('AuthRepository.updatePatientProfile', () {
    test('converts the PATCH response to PatientProfile', () async {
      final api = _FakeAuthApi(response: _validJson);
      final repository = _repository(api);

      final profile = await repository.updatePatientProfile(
        name: 'Patient',
        gender: 'female',
      );

      expect(profile.name, 'Patient');
      expect(api.updatedName, 'Patient');
      expect(api.updatedGender, 'female');
      expect(api.updatedBirthDate, isNull);
    });

    test('preserves an update ApiException', () async {
      const exception = ApiException(message: 'forbidden', statusCode: 403);
      final repository = _repository(_FakeAuthApi(error: exception));

      await expectLater(
        repository.updatePatientProfile(name: 'Patient'),
        throwsA(same(exception)),
      );
    });
  });
}

AuthRepository _repository(AuthApi authApi) {
  return AuthRepository(authApi: authApi, tokenStorage: TokenStorage());
}

const _validJson = <String, dynamic>{
  'patient_number': 'P-001',
  'birth_date': '1990-01-02',
  'gender': 'female',
  'hospital_name': 'Hospital',
  'assigned_doctor': 'doctor-uuid',
  'name': 'Patient',
  'phone_number': '010-1234-5678',
};

class _FakeAuthApi extends AuthApi {
  _FakeAuthApi({this.response, this.error})
    : super(apiClient: ApiClient(dio: Dio()));

  final dynamic response;
  final Object? error;
  String? updatedName;
  String? updatedBirthDate;
  String? updatedGender;

  @override
  Future<dynamic> getPatientProfile() async {
    if (error != null) {
      throw error!;
    }
    return response;
  }

  @override
  Future<dynamic> updatePatientProfile({
    String? name,
    String? birthDate,
    String? gender,
  }) async {
    if (error != null) throw error!;
    updatedName = name;
    updatedBirthDate = birthDate;
    updatedGender = gender;
    return response;
  }
}
