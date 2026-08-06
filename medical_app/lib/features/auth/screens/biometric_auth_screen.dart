import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';

import '../../../core/security/security_settings_controller.dart';
import '../../../core/theme/app_theme.dart';

/// 생체인증 화면 — local_auth로 실제 기기(또는 에뮬레이터) 지문/얼굴 인증을 수행.
class BiometricAuthScreen extends StatefulWidget {
  const BiometricAuthScreen({super.key});

  @override
  State<BiometricAuthScreen> createState() => _BiometricAuthScreenState();
}

class _BiometricAuthScreenState extends State<BiometricAuthScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _authenticate() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: '앱 잠금 해제를 위해 인증해주세요.',
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
      if (!mounted) return;

      if (didAuthenticate) {
        context.read<SecuritySettingsController>().markUnlocked();
        Navigator.of(context).pop();
        // 성공하면 라우터 redirect가 자동으로 홈으로 넘겨줌.
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = '인증에 실패했어요. 다시 시도해주세요.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = '생체인증을 사용할 수 없어요. 기기에 지문/얼굴이 등록돼 있는지 확인해주세요.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 104,
                    height: 104,
                    margin: const EdgeInsets.only(bottom: 0),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTheme.gradientEnd.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.fingerprint_rounded, size: 64, color: AppTheme.gradientEnd),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '생체인증으로 잠금을\n해제해주세요',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '등록된 지문 또는 얼굴 정보를 이용해\n안전하게 시작할 수 있어요.',
                    style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (_errorMessage != null) ...[
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                  ],
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.gradientEnd,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _isLoading ? null : _authenticate,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.fingerprint),
                    label: const Text('생체인증 시작'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.pin_outlined),
                    label: const Text('PIN 번호로 인증'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
