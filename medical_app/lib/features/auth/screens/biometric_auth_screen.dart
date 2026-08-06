import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/security/security_settings_controller.dart';
import '../../../core/theme/app_theme.dart';

/// 생체인증 화면 — patient_app 보안설정과 동일한 목업.
/// 실제 기기 생체인증(local_auth 등) 연동 없이 0.5초 뒤 무조건 성공 처리.
class BiometricAuthScreen extends StatefulWidget {
  const BiometricAuthScreen({super.key});

  @override
  State<BiometricAuthScreen> createState() => _BiometricAuthScreenState();
}

class _BiometricAuthScreenState extends State<BiometricAuthScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _authenticate() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    context.read<SecuritySettingsController>().markUnlocked();
    Navigator.of(context).pop();
    // 성공하면 라우터 redirect가 자동으로 홈으로 넘겨줌.
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
                  const SizedBox(height: 18),
                  Text(
                    '현재 단계에서는 실제 기기 생체인증 대신 Mock 인증 결과를 사용해요.',
                    style: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 11),
                    textAlign: TextAlign.center,
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
