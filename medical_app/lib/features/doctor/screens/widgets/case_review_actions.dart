import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/api/auth_api.dart';
import '../../../../core/api/cases_api.dart' as cases_api;
import '../../../../core/auth/session_controller.dart';
import '../../models/review_case.dart';

/// 케이스 상세화면 하단에 고정으로 붙는 승인/반려 액션바.
/// 실제 API(POST /api/cases/{id}/review/) 연동됨.
///
/// - 승인(action=confirm): AI값 그대로 확정
/// - 반려(action=edit): 바텀시트로 소견/아형 수정 → 수정값으로 확정
/// - 서버는 둘 다 status=confirmed로 처리 (승인/반려를 별도 상태로 구분하지 않음)
class CaseReviewActionBar extends StatelessWidget {
  final ReviewCase reviewCase;

  const CaseReviewActionBar({super.key, required this.reviewCase});

  Future<void> _onApprove(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('승인하시겠어요?'),
        content: Text(
          'AI 분석 결과(${reviewCase.type.label}, '
          '${(reviewCase.confidence * 100).round()}%)를 그대로 확정합니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('승인'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final token = context.read<SessionController>().accessToken;
    if (token == null) return;

    try {
      await cases_api.reviewCase(
        caseId: reviewCase.id,
        accessToken: token,
        action: 'confirm',
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${reviewCase.patientName} 케이스 승인 완료')),
      );
      Navigator.of(context).pop(true); // 목록 화면에 "새로고침 필요" 신호
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _onReject(BuildContext context) async {
    final result = await showModalBottomSheet<_RejectFormResult>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _RejectForm(reviewCase: reviewCase),
    );

    if (result == null || !context.mounted) return;

    final token = context.read<SessionController>().accessToken;
    if (token == null) return;

    try {
      await cases_api.reviewCase(
        caseId: reviewCase.id,
        accessToken: token,
        action: 'edit',
        finalSubtype: result.type.label, // 'LUAD' | 'LUSC'
        finalNote: result.opinion,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${reviewCase.patientName} 케이스 반려(수정) 완료')),
      );
      Navigator.of(context).pop(true); // 목록 화면에 "새로고침 필요" 신호
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _onReject(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade700,
                side: BorderSide(color: Colors.red.shade200),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('반려'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: () => _onApprove(context),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('승인'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RejectFormResult {
  final CaseType type;
  final String opinion;

  _RejectFormResult({required this.type, required this.opinion});
}

class _RejectForm extends StatefulWidget {
  final ReviewCase reviewCase;

  const _RejectForm({required this.reviewCase});

  @override
  State<_RejectForm> createState() => _RejectFormState();
}

class _RejectFormState extends State<_RejectForm> {
  late CaseType _type;
  final TextEditingController _opinionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _type = widget.reviewCase.type;
  }

  @override
  void dispose() {
    _opinionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '반려 · 소견 수정',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          const Text('아형 수정', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SegmentedButton<CaseType>(
            segments: const [
              ButtonSegment(value: CaseType.luad, label: Text('LUAD')),
              ButtonSegment(value: CaseType.lusc, label: Text('LUSC')),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
          ),
          const SizedBox(height: 16),
          const Text('소견 수정', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _opinionController,
            maxLines: 4,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '수정된 소견을 입력하세요',
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade600,
              ),
              onPressed: () {
                Navigator.of(context).pop(
                  _RejectFormResult(
                    type: _type,
                    opinion: _opinionController.text,
                  ),
                );
              },
              child: const Text('반려 확정'),
            ),
          ),
        ],
      ),
    );
  }
}