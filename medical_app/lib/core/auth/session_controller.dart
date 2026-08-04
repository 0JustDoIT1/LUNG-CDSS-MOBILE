import 'package:flutter/foundation.dart';

import '../constants/user_role.dart';

/// 로그인 상태 & 현재 역할(의사/간호사)을 앱 전역에서 들고 있는 컨트롤러.
///
/// 지금은 실제 인증(의사면허번호 API 검증 등)이 붙기 전이라
/// [logIn]을 호출하면 바로 로그인된 것으로 처리하는 임시 구현이다.
/// 나중에 실제 로그인 로직으로 교체할 지점.
class SessionController extends ChangeNotifier {
  UserRole? _role;

  UserRole? get role => _role;
  bool get isLoggedIn => _role != null;

  void logIn(UserRole role) {
    _role = role;
    notifyListeners();
  }

  void logOut() {
    _role = null;
    notifyListeners();
  }
}
