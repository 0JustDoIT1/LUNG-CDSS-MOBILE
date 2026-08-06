import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../api/appointments_api.dart';
import '../api/auth_api.dart';
import '../api/intake_api.dart';
import '../auth/session_controller.dart';
import '../theme/app_theme.dart';

/// 환자 진료카드 QR 스캔 화면.
/// QR 원문값에서 토큰을 뽑아 GET /api/intake/qr/{token}/ 로 프로필+문진표 요약 조회.
/// showCheckInAction이 true면(간호사) 조회 결과에서 바로 방문처리(check-in)도 가능.
class QrScanScreen extends StatefulWidget {
  final bool showCheckInAction;

  const QrScanScreen({super.key, this.showCheckInAction = false});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// QR 원문이 URL 형태(예: https://.../qr/{token})일 수도, 토큰 문자열 그 자체일 수도 있어 둘 다 처리.
  String _extractToken(String rawValue) {
    final uri = Uri.tryParse(rawValue);
    if (uri != null && uri.hasScheme && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.last;
    }
    return rawValue;
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || capture.barcodes.isEmpty) return;
    final rawValue = capture.barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    final accessToken = context.read<SessionController>().accessToken;
    if (accessToken == null) return;

    setState(() => _isProcessing = true);
    await _controller.stop();
    if (!mounted) return;

    try {
      final token = _extractToken(rawValue);
      final summary = await fetchQrPatientSummary(token, accessToken);
      if (!mounted) return;

      if (summary == null) {
        _resumeWithMessage('QR이 만료되었거나 올바르지 않아요. 환자에게 다시 발급을 요청해주세요.');
        return;
      }

      setState(() => _isProcessing = false);
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => _QrResultSheet(
          summary: summary,
          showCheckInAction: widget.showCheckInAction,
        ),
      );
      if (!mounted) return;
      await _controller.start();
    } on ApiException catch (e) {
      if (!mounted) return;
      _resumeWithMessage(e.message);
    }
  }

  void _resumeWithMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    setState(() => _isProcessing = false);
    _controller.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('QR 스캔'),
        actions: [
          IconButton(
            onPressed: () => _controller.toggleTorch(),
            icon: const Icon(Icons.flash_on),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) => _CameraErrorView(error: error),
          ),
          IgnorePointer(
            child: Center(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.gradientEnd, width: 3),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          if (_isProcessing)
            const ColoredBox(
              color: Colors.black45,
              child: Center(child: CircularProgressIndicator()),
            ),
          const Positioned(
            left: 24,
            right: 24,
            bottom: 40,
            child: Text(
              '환자 진료카드 QR을 사각형 안에 맞춰주세요',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraErrorView extends StatelessWidget {
  final MobileScannerException error;

  const _CameraErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    final isPermissionIssue = error.errorCode == MobileScannerErrorCode.permissionDenied;

    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.no_photography_outlined, color: Colors.white70, size: 48),
              const SizedBox(height: 16),
              Text(
                isPermissionIssue
                    ? '카메라 권한이 꺼져있어요.\n기기 설정 > 앱 > 권한에서 카메라를 허용해주세요.'
                    : '카메라를 사용할 수 없어요. (${error.errorCode})',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QrResultSheet extends StatefulWidget {
  final QrPatientSummary summary;
  final bool showCheckInAction;

  const _QrResultSheet({required this.summary, required this.showCheckInAction});

  @override
  State<_QrResultSheet> createState() => _QrResultSheetState();
}

class _QrResultSheetState extends State<_QrResultSheet> {
  bool _isCheckingIn = false;
  String? _checkInMessage;

  Future<void> _checkIn() async {
    final accessToken = context.read<SessionController>().accessToken;
    if (accessToken == null) return;

    setState(() {
      _isCheckingIn = true;
      _checkInMessage = null;
    });

    try {
      final todayVisits = await fetchTodayVisits(accessToken);
      final match = todayVisits.where((a) => a.patientName == widget.summary.name).toList();
      if (match.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isCheckingIn = false;
          _checkInMessage = '오늘 예약된 진료를 찾을 수 없어요.';
        });
        return;
      }
      await checkInAppointment(match.first.id, accessToken);
      if (!mounted) return;
      setState(() {
        _isCheckingIn = false;
        _checkInMessage = '방문처리 완료했어요.';
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isCheckingIn = false;
        _checkInMessage = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final summary = widget.summary;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppTheme.seed.withValues(alpha: 0.12),
                  child: Text(
                    summary.name.isNotEmpty ? summary.name.substring(0, 1) : '?',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.gradientEnd),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(summary.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      if (summary.patientNumber != null || summary.birthDate != null)
                        Text(
                          [
                            if (summary.patientNumber != null) '환자번호 ${summary.patientNumber}',
                            if (summary.birthDate != null) summary.birthDate!,
                          ].join(' · '),
                          style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('문진표 요약', style: TextStyle(fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
            const SizedBox(height: 8),
            if (summary.intakeAnswers.isEmpty)
              Text('제출된 문진표가 없어요', style: TextStyle(color: colorScheme.onSurfaceVariant))
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final answer in summary.intakeAnswers) ...[
                        Text(
                          answer.questionText,
                          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 2),
                        Text(answer.answerText),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
              ),
            if (widget.showCheckInAction) ...[
              const SizedBox(height: 20),
              if (_checkInMessage != null) ...[
                Text(_checkInMessage!, style: TextStyle(color: colorScheme.onSurfaceVariant)),
                const SizedBox(height: 8),
              ],
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppTheme.gradientEnd),
                  onPressed: _isCheckingIn ? null : _checkIn,
                  child: _isCheckingIn
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('방문처리'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
