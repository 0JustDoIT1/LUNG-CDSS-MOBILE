import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/auth_api.dart';
import '../../../core/api/cases_api.dart';
import '../../../core/auth/session_controller.dart';
import '../models/case_review_log.dart';
import '../models/review_case.dart';

/// 검토 이력 전체열람. 실제 API(GET /api/cases/{id}/review-log/) 연동됨.
/// CaseReviewLog 시간순(최신순), action별 아이콘 구분,
/// 각 항목에 검토자·시각·소견스냅샷 표시.
class CaseReviewHistoryScreen extends StatefulWidget {
  final ReviewCase reviewCase;

  const CaseReviewHistoryScreen({super.key, required this.reviewCase});

  @override
  State<CaseReviewHistoryScreen> createState() => _CaseReviewHistoryScreenState();
}

class _CaseReviewHistoryScreenState extends State<CaseReviewHistoryScreen> {
  List<CaseReviewLog>? _logs;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final token = context.read<SessionController>().accessToken;
    if (token == null) return;

    try {
      final logs = await fetchCaseReviewLogs(widget.reviewCase.id, token);
      logs.sort((a, b) => b.timestamp.compareTo(a.timestamp)); // 최신순
      if (!mounted) return;
      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.reviewCase.patientName} 검토 이력')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: _load, child: const Text('다시 시도')),
          ],
        ),
      );
    }

    final logs = _logs ?? [];
    if (logs.isEmpty) {
      return const Center(child: Text('검토 이력이 없어요'));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: logs.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
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
                      if (log.subtypeAtTime != null) ...[
                        const SizedBox(width: 8),
                        Chip(
                          label: Text(log.subtypeAtTime!),
                          labelStyle: const TextStyle(fontSize: 11),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          side: BorderSide.none,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(log.timestamp),
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
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