import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../intake/presentation/providers/patient_qr_provider.dart';
import '../../../intake/presentation/providers/intake_form_provider.dart';

class PatientQrScreen extends ConsumerStatefulWidget {
  const PatientQrScreen({super.key});

  @override
  ConsumerState<PatientQrScreen> createState() => _PatientQrScreenState();
}

class _PatientQrScreenState extends ConsumerState<PatientQrScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(patientQrProvider.notifier).recalculateRemainingTime();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(patientQrProvider);
    final intakeState = ref.watch(intakeFormProvider);
    final isIntakeSubmitted = intakeState.asData?.value.isCompleted == true;

    return Scaffold(
      appBar: AppBar(title: const Text('환자 QR')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '의료진에게 이 QR을 보여주세요.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (!isIntakeSubmitted) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '현재 문진표가 제출되지 않았습니다. 문진표를 먼저 제출해주세요.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                _QrContent(state: state),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QrContent extends ConsumerWidget {
  const _QrContent({required this.state});

  final PatientQrState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (state.status) {
      case PatientQrStatus.loading:
        return const CircularProgressIndicator();
      case PatientQrStatus.error:
        return _MessageWithRetry(
          message: patientQrErrorMessage(state.error),
          onRetry: ref.read(patientQrProvider.notifier).issue,
        );
      case PatientQrStatus.expired:
        return _MessageWithRetry(
          message: 'QR이 만료되었습니다.',
          onRetry: ref.read(patientQrProvider.notifier).issue,
        );
      case PatientQrStatus.data:
        final value = state.value!;
        return Column(
          children: [
            Semantics(
              label: '환자 임시 QR 코드',
              child: Container(
                width: 240,
                height: 240,
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: PatientQrCode(data: value.token),
              ),
            ),
            const SizedBox(height: 20),
            Text('${_formatRemaining(state.remainingSeconds)} 후 만료'),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: ref.read(patientQrProvider.notifier).issue,
              child: const Text('새 QR 발급'),
            ),
          ],
        );
    }
  }

  static String _formatRemaining(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
}

class PatientQrCode extends StatelessWidget {
  const PatientQrCode({required this.data, super.key});

  final String data;

  @override
  Widget build(BuildContext context) => QrImageView(data: data);
}

class _MessageWithRetry extends StatelessWidget {
  const _MessageWithRetry({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 20),
        FilledButton(onPressed: onRetry, child: const Text('새 QR 발급')),
      ],
    );
  }
}
