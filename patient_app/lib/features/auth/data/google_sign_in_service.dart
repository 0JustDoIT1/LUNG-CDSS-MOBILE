import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInService {
  GoogleSignInService();

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    await _googleSignIn.initialize();

    _isInitialized = true;
  }

  Future<String> signInAndGetIdToken() async {
    await initialize();

    final account = await _googleSignIn.authenticate();
    final authentication = account.authentication;
    final idToken = authentication.idToken;

    if (idToken == null || idToken.isEmpty) {
      throw StateError(
        'Google 로그인에서 ID 토큰을 받지 못했습니다.',
      );
    }

    return idToken;
  }

  Future<void> signOut() async {
    await initialize();
    await _googleSignIn.signOut();
  }
}
