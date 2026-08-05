import '../../../core/auth/token_storage.dart';
import 'auth_api.dart';
import 'models/auth_result.dart';
import 'models/hospital.dart';
import 'models/patient_profile.dart';

class AuthRepository {
  AuthRepository({required AuthApi authApi, required TokenStorage tokenStorage})
    : _authApi = authApi,
      _tokenStorage = tokenStorage;

  final AuthApi _authApi;
  final TokenStorage _tokenStorage;

  Future<AuthResult> socialLogin({
    required String provider,
    required String token,
  }) async {
    final json = await _authApi.socialLogin(provider: provider, token: token);

    final result = AuthResult.fromJson(json);

    if (result.isExistingMember) {
      await _tokenStorage.saveTokens(
        accessToken: result.accessToken!,
        refreshToken: result.refreshToken!,
      );

      await _tokenStorage.deleteSignupToken();
      return result;
    }

    if (result.isNewMember) {
      await _tokenStorage.saveSignupToken(result.signupToken!);
      return result;
    }

    throw const FormatException('소셜 로그인 응답에 JWT 또는 signup_token이 없습니다.');
  }

  Future<Hospital> getHospital() async {
    final json = await _authApi.getHospital();
    final hospital = Hospital.fromJson(json);

    if (hospital.id.isEmpty) {
      throw const FormatException('병원 조회 응답에 hospital id가 없습니다.');
    }

    return hospital;
  }

  Future<void> registerPatient({
    required String birthDate,
    required String hospitalId,
    required String phoneNumber,
    required String gender,
  }) async {
    final signupToken = await _tokenStorage.readSignupToken();

    if (signupToken == null || signupToken.isEmpty) {
      throw StateError('저장된 signup_token이 없습니다. 소셜 로그인을 다시 진행해주세요.');
    }

    final json = await _authApi.registerPatient(
      signupToken: signupToken,
      birthDate: birthDate,
      hospitalId: hospitalId,
      phoneNumber: phoneNumber,
      gender: gender,
    );

    final result = AuthResult.fromJson(json);

    if (!result.isExistingMember) {
      throw const FormatException('회원가입 응답에 access 또는 refresh 토큰이 없습니다.');
    }

    await _tokenStorage.saveTokens(
      accessToken: result.accessToken!,
      refreshToken: result.refreshToken!,
    );

    await _tokenStorage.deleteSignupToken();
  }

  Future<PatientProfile> getPatientProfile() async {
    final json = await _authApi.getPatientProfile();
    if (json is! Map<String, dynamic>) {
      throw const FormatException('환자 프로필 응답은 객체여야 합니다.');
    }
    return PatientProfile.fromJson(json);
  }

  Future<PatientProfile> updatePatientProfile({
    String? name,
    String? birthDate,
    String? gender,
  }) async {
    final json = await _authApi.updatePatientProfile(
      name: name,
      birthDate: birthDate,
      gender: gender,
    );
    if (json is! Map<String, dynamic>) {
      throw const FormatException('환자 프로필 수정 응답은 객체여야 합니다.');
    }
    return PatientProfile.fromJson(json);
  }

  Future<bool> hasAccessToken() async {
    final accessToken = await _tokenStorage.readAccessToken();
    final refreshToken = await _tokenStorage.readRefreshToken();
    final hasAccess = accessToken != null && accessToken.isNotEmpty;
    final hasRefresh = refreshToken != null && refreshToken.isNotEmpty;
    if (hasAccess != hasRefresh) {
      await _tokenStorage.clearAuthTokens();
      return false;
    }
    return hasAccess && hasRefresh;
  }

  Future<void> logout() async {
    final refreshToken = await _tokenStorage.readRefreshToken();

    try {
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _authApi.logout(refreshToken: refreshToken);
      }
    } finally {
      await _tokenStorage.clearAuthTokens();
    }
  }
}
