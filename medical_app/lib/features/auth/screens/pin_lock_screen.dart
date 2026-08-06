import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/security/security_settings_controller.dart';
import '../../../core/theme/app_theme.dart';
import 'biometric_auth_screen.dart';

/// 앱 잠금 PIN 화면 — patient_app 보안설정과 동일한 목업.
/// 실제 서버/저장소 연동 없이 "1234" 고정 PIN으로만 통과됨.
class PinLockScreen extends StatefulWidget {
  const PinLockScreen({super.key});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  static const _correctPin = '1234';

  String _pin = '';
  bool _isLoading = false;
  String? _errorText;

  Future<void> _verifyPin() async {
    if (_pin.length != 4 || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    if (_pin != _correctPin) {
      setState(() {
        _isLoading = false;
        _pin = '';
        _errorText = 'PIN 번호가 일치하지 않아요.';
      });
      return;
    }

    context.read<SecuritySettingsController>().markUnlocked();
    // 성공하면 라우터 redirect가 자동으로 홈으로 넘겨줌 — 여기서 직접 이동 안 함.
  }

  void _enterNumber(String number) {
    if (_pin.length >= 4 || _isLoading) return;
    setState(() {
      _pin += number;
      _errorText = null;
    });
    if (_pin.length == 4) _verifyPin();
  }

  void _removeNumber() {
    if (_pin.isEmpty || _isLoading) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _errorText = null;
    });
  }

  Widget _buildPinDot(int index) {
    final isFilled = index < _pin.length;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isFilled ? AppTheme.gradientEnd : Colors.transparent,
        border: Border.all(
          color: isFilled ? AppTheme.gradientEnd : Colors.grey.shade400,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _buildNumberButton(String number) {
    return SizedBox(
      width: 68,
      height: 68,
      child: OutlinedButton(
        onPressed: _isLoading ? null : () => _enterNumber(number),
        style: OutlinedButton.styleFrom(
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
        ),
        child: Text(number, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final security = context.watch<SecuritySettingsController>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                children: [
                  const Icon(Icons.lock_outline_rounded, size: 56, color: AppTheme.gradientEnd),
                  const SizedBox(height: 20),
                  const Text(
                    'PIN 번호를 입력해주세요',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '앱 잠금 해제를 위해 4자리 PIN을 입력해주세요.',
                    style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      4,
                      (i) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: _buildPinDot(i),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 22,
                    child: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _errorText ?? '',
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 20,
                    runSpacing: 14,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final n in ['1', '2', '3', '4', '5', '6', '7', '8', '9']) _buildNumberButton(n),
                      const SizedBox(width: 68, height: 68),
                      _buildNumberButton('0'),
                      SizedBox(
                        width: 68,
                        height: 68,
                        child: IconButton(
                          onPressed: _isLoading ? null : _removeNumber,
                          icon: const Icon(Icons.backspace_outlined),
                        ),
                      ),
                    ],
                  ),
                  if (security.biometricEnabled) ...[
                    const SizedBox(height: 20),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const BiometricAuthScreen()),
                        );
                      },
                      icon: const Icon(Icons.fingerprint_rounded, size: 18),
                      label: const Text('생체인증으로 잠금 해제'),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    '테스트 PIN: 1234',
                    style: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 11),
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
