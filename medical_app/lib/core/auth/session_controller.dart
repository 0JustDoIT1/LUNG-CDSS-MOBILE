import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../main.dart';
import '../api/auth_api.dart';
import '../constants/user_role.dart';
import 'jwt_utils.dart';

/// 로그인 상태 & 현재 역할(의사/간호사)을 앱 전역에서 들고 있는 컨트롤러.
/// 실제 서버(POST /api/auth/staff/login/, .../staff/signup/) 연동됨.
/// 토큰은 SharedPreferences에 로컬 저장 — 앱 껐다 켜도 로그인 유지.
///
/// TODO: refresh 토큰으로 access 토큰 자동갱신하는 로직은 아직 없음(만료되면 재로그인 필요).
class SessionController extends ChangeNotifier {
  static const _keyAccessToken = 'session.accessToken';
  static const _keyRefreshToken = 'session.refreshToken';
  static const _keyRole = 'session.role';
  static const _keyName = 'session.name';

  UserRole? _role;
  String? _accessToken;
  String? _refreshToken;
  String _name = '';
  bool _isLoading = false;

  UserRole? get role => _role;
  bool get isLoggedIn => _role != null;
  String? get accessToken => _accessToken;
  String get name => _name;
  bool get isLoading => _isLoading;

  /// 로그인 응답엔 사용자 id가 없어서, access 토큰(JWT)에서 매번 꺼냄.
  String? get myUserId => _accessToken != null ? decodeJwtUserId(_accessToken!) : null;

  UserRole? _parseRole(String serverRole) => switch (serverRole) {
        'doctor' => UserRole.doctor,
        'nurse' => UserRole.nurse,
        _ => null, // 병리사(pathologist) 등 이 앱에서 지원 안 하는 역할
      };

  /// 앱 시작 시 저장된 세션 복원.
  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final savedRole = prefs.getString(_keyRole);
    if (savedRole == null) return;

    _role = _parseRole(savedRole);
    _accessToken = prefs.getString(_keyAccessToken);
    _refreshToken = prefs.getString(_keyRefreshToken);
    _name = prefs.getString(_keyName) ?? '';
    notifyListeners();

    if (_accessToken != null) {
      fcmService.init(_accessToken!); // ← 추가: 앱 재시작 시에도 FCM 등록
    }
  }

  /// 로그인/회원가입 응답(StaffLoginResult)을 세션에 반영 + 로컬저장.
  /// 지원 안 하는 역할(병리사 등)이면 false 반환, 정상 처리되면 true.
Future<bool> applyLoginResult(StaffLoginResult result) async {
    final role = _parseRole(result.role);
    if (role == null) return false;

    _role = role;
    _accessToken = result.access;
    _refreshToken = result.refresh;
    _name = result.name;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccessToken, result.access);
    await prefs.setString(_keyRefreshToken, result.refresh);
    await prefs.setString(_keyRole, result.role);
    await prefs.setString(_keyName, result.name);

    notifyListeners();
    fcmService.init(result.access); // 로그인 성공 시 FCM 토큰 발급+서버등록 (실패해도 로그인엔 영향 없음)
    return true;
  }

  /// 실제 서버 로그인. 성공하면 null, 실패하면 사용자에게 보여줄 에러 메시지를 반환.
  Future<String?> logInWithCredentials({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await staffLogin(email: email, password: password);
      final ok = await applyLoginResult(result);
      if (!ok) return '이 앱은 의사/간호사 계정만 로그인할 수 있어요.';
      return null;
    } on ApiException catch (e) {
      return e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logOut() async {
    _role = null;
    _accessToken = null;
    _refreshToken = null;
    _name = '';

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyRefreshToken);
    await prefs.remove(_keyRole);
    await prefs.remove(_keyName);

    notifyListeners();
  }
}