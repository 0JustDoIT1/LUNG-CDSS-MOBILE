import 'dart:async';

class AuthSessionCoordinator {
  final StreamController<void> _expiredController =
      StreamController<void>.broadcast(sync: true);

  int _generation = 0;
  bool _isLoggingOut = false;
  bool _expirationNotified = false;

  Stream<void> get onExpired => _expiredController.stream;

  int get generation => _generation;

  bool get isLoggingOut => _isLoggingOut;

  bool canStoreRefreshedTokens(int generation) {
    return !_isLoggingOut && generation == _generation;
  }

  void markAuthenticated() {
    _isLoggingOut = false;
    _expirationNotified = false;
  }

  void beginLogout() {
    _isLoggingOut = true;
    _generation++;
  }

  void finishLogout() {
    _isLoggingOut = false;
  }

  void notifyExpired() {
    if (_isLoggingOut || _expirationNotified) return;
    _expirationNotified = true;
    _generation++;
    _expiredController.add(null);
  }

  Future<void> dispose() => _expiredController.close();
}
