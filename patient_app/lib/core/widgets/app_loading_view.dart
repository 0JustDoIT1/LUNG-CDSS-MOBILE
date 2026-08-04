import 'package:flutter/material.dart';

class AppLoadingView extends StatelessWidget {
  const AppLoadingView({
    super.key,
    this.message = '정보를 불러오는 중입니다.',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(
                    color: Colors.grey.shade700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}