import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../main.dart';
import '../api/auth_api.dart';
import '../constants/user_role.dart';
import 'jwt_utils.dart';
import 'token_storage.dart';

/// 로그인 상태 & 현재 역할(의사/간호사)을 앱 전역에서 들고 있는 컨트롤러.
/// 실제 서버(POST /api/auth/staff/login/, .../staff/signup/) 연동됨.
/// 토큰은 flutter_secure_storage(암호화)에 저장 — 앱 껐다 켜도 로그인 유지.
/// access 토큰 만료 전에 refresh 토큰으로 자동 갱신(POST /api/auth/refresh/) — 강제 재로그인 없음.
class SessionController extends ChangeNotifier {
  static const _keyRole = 'session.role';
  static const _keyName = 'session.name';

  final TokenStorage _tokenStorage = TokenStorage();

  UserRole? _role;
  String? _accessToken;
  String? _refreshToken;
  String _name = '';
  bool _isLoading = false;
  Timer? _refreshTimer;

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

    final accessToken = await _tokenStorage.readAccessToken();
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (accessToken == null || refreshToken == null) return;

    _role = _parseRole(savedRole);
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _name = prefs.getString(_keyName) ?? '';
    notifyListeners();

    fcmService.init(accessToken); // 앱 재시작 시에도 FCM 등록
    _scheduleRefresh();
  }

  /// 로그인/가입 응답(StaffLoginResult)을 세션에 반영 + 로컬저장.
  /// 지원 안 하는 역할(병리사 등)이면 false 반환, 정상 처리되면 true.
  Future<bool> applyLoginResult(StaffLoginResult result) async {
    final role = _parseRole(result.role);
    if (role == null) return false;

    _role = role;
    _accessToken = result.access;
    _refreshToken = result.refresh;
    _name = result.name;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRole, result.role);
    await prefs.setString(_keyName, result.name);
    await _tokenStorage.saveTokens(accessToken: result.access, refreshToken: result.refresh);

    notifyListeners();
    fcmService.init(result.access); // 로그인 성공 시 FCM 토큰 발급+서버등록 (실패해도 로그인엔 영향 없음)
    _scheduleRefresh();
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

  /// access 토큰 만료 60초 전에 자동으로 refresh 토큰으로 갱신하도록 타이머를 건다.
  /// exp 클레임을 못 읽으면(이상한 토큰) 5분 뒤 재시도.
  void _scheduleRefresh() {
    _refreshTimer?.cancel();
    final token = _accessToken;
    if (token == null) return;

    final expiry = decodeJwtExpiry(token);
    final delay = expiry == null
        ? const Duration(minutes: 5)
        : expiry.difference(DateTime.now()) - const Duration(seconds: 60);

    if (delay.isNegative) {
      _performRefresh();
      return;
    }
    _refreshTimer = Timer(delay, _performRefresh);
  }

  Future<void> _performRefresh() async {
    final refreshToken = _refreshToken;
    if (refreshToken == null) return;

    try {
      final result = await refreshAccessToken(refreshToken);
      _accessToken = result.access;
      if (result.refresh != null) _refreshToken = result.refresh;

      await _tokenStorage.saveTokens(accessToken: _accessToken!, refreshToken: _refreshToken!);
      notifyListeners();
      fcmService.init(_accessToken!);
      _scheduleRefresh();
    } on ApiException catch (_) {
      // refresh 토큰마저 만료/무효면 더 이상 자동갱신 불가 — 재로그인 필요.
      await logOut();
    }
  }

  Future<void> logOut() async {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _role = null;
    _accessToken = null;
    _refreshToken = null;
    _name = '';

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyRole);
    await prefs.remove(_keyName);
    await _tokenStorage.clear();

    notifyListeners();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
