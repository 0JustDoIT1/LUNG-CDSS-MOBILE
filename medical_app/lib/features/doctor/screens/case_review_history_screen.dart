import 'package:flutter/material.dart';

import '../mock/case_review_log_mock.dart';
import '../models/case_review_log.dart';
import '../models/review_case.dart';

/// 검토 이력 전체열람.
/// CaseReviewLog 시간순(최신순), action별 아이콘 구분,
/// 각 항목에 검토자·시각·소견스냅샷 표시.
class CaseReviewHistoryScreen extends StatelessWidget {
  final ReviewCase reviewCase;

  const CaseReviewHistoryScreen({super.key, required this.reviewCase});

  @override
  Widget build(BuildContext context) {
    final logs = mockReviewLogs(reviewCase.id)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // 최신순

    return Scaffold(
      appBar: AppBar(title: Text('${reviewCase.patientName} 검토 이력')),
      body: logs.isEmpty
          ? const Center(child: Text('검토 이력이 없어요'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) => _LogTile(log: logs[index]),
            ),
    );
  }
}

class _LogTile extends StatelessWidget {
  final CaseReviewLog log;

  const _LogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final isConfirmed = log.action == ReviewAction.confirmed;
    final color = isConfirmed ? Colors.green : Colors.red;
    final icon = isConfirmed ? Icons.check_circle : Icons.edit_note;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        log.action.label,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        log.reviewerName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(log.timestamp),
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  Text(log.opinionSnapshot),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${time.year}-${two(time.month)}-${two(time.day)} '
        '${two(time.hour)}:${two(time.minute)}';
  }
}