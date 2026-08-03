import 'package:flutter/material.dart';

class IntakeCompletedScreen extends StatelessWidget {
  const IntakeCompletedScreen({
    super.key,
    required this.onViewAnswers,
    required this.onGoHome,
  });

  final VoidCallback onViewAnswers;
  final VoidCallback onGoHome;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('문진 작성 완료'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 48,
                  color: Theme.of(context)
                      .colorScheme
                      .primary,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                '문진 작성이 완료되었습니다',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                '작성한 문진 내용은 의료진에게 전달되며\n진료 준비에 활용됩니다.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onViewAnswers,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                    child: Text('작성 내용 확인'),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onGoHome,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                    child: Text('홈으로 이동'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}