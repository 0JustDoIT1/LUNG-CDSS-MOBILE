import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/security/security_settings_controller.dart';
import '../../../core/theme/app_theme.dart';

/// PIN 최초 설정/변경 화면. 새 PIN을 입력 → 같은 값으로 다시 확인 → 저장.
/// 라우터가 직접 띄운 경우(최초 설정, 뒤로 갈 곳 없음)엔 저장 후 라우터 redirect가 알아서 넘겨주고,
/// 설정화면에서 push해서 띄운 경우(PIN 변경)엔 저장 후 true를 들고 pop한다.
class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

enum _Stage { enterNew, confirmNew }

class _PinSetupScreenState extends State<PinSetupScreen> {
  _Stage _stage = _Stage.enterNew;
  String _firstPin = '';
  String _pin = '';
  bool _isSaving = false;
  String? _errorText;

  void _enterNumber(String number) {
    if (_pin.length >= 4 || _isSaving) return;
    setState(() {
      _pin += number;
      _errorText = null;
    });
    if (_pin.length == 4) _onFourDigitsEntered();
  }

  void _removeNumber() {
    if (_pin.isEmpty || _isSaving) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _errorText = null;
    });
  }

  Future<void> _onFourDigitsEntered() async {
    if (_stage == _Stage.enterNew) {
      setState(() {
        _firstPin = _pin;
        _pin = '';
        _stage = _Stage.confirmNew;
      });
      return;
    }

    // 확인 단계 — 처음 입력한 값과 같은지 검증.
    if (_pin != _firstPin) {
      setState(() {
        _pin = '';
        _firstPin = '';
        _stage = _Stage.enterNew;
        _errorText = 'PIN이 서로 일치하지 않아요. 처음부터 다시 입력해주세요.';
      });
      return;
    }

    setState(() => _isSaving = true);
    final security = context.read<SecuritySettingsController>();
    await security.setPin(_pin);
    if (!mounted) return;
    security.markUnlocked();

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(true);
    }
    // else: 최초 설정 흐름 — 라우터 redirect가 자동으로 홈으로 넘겨줌.
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
        onPressed: _isSaving ? null : () => _enterNumber(number),
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
    final colorScheme = Theme.of(context).colorScheme;
    final isConfirmStage = _stage == _Stage.confirmNew;

    return Scaffold(
      appBar: AppBar(title: const Text('PIN 설정')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                children: [
                  const Icon(Icons.pin_outlined, size: 56, color: AppTheme.gradientEnd),
                  const SizedBox(height: 20),
                  Text(
                    isConfirmStage ? 'PIN을 다시 한 번 입력해주세요' : '사용할 PIN 4자리를 입력해주세요',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isConfirmStage ? '확인을 위해 방금 입력한 PIN을 한 번 더 입력해주세요.' : '이후 앱을 열 때 이 PIN으로 잠금을 해제해요.',
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
                    child: _isSaving
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
                          onPressed: _isSaving ? null : _removeNumber,
                          icon: const Icon(Icons.backspace_outlined),
                        ),
                      ),
                    ],
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
