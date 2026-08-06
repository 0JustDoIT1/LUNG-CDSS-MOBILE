import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/api/auth_api.dart';
import '../../../../core/api/cases_api.dart' as cases_api;
import '../../../../core/auth/session_controller.dart';
import '../../models/review_case.dart';

/// 케이스 상세화면 하단에 고정으로 붙는 승인/반려 액션바.
/// 실제 API(POST /api/cases/{id}/review/) 연동됨.
///
/// - 승인(action=confirm), 반려(action=edit) 모두 바텀시트로 아형/의사 소견을 입력받아
///   final_subtype/final_note로 전송 — 서버가 confirm에도 이 필드들을 요구함(누락 시 400).
/// - 서버는 둘 다 status=confirmed로 처리 (승인/반려를 별도 상태로 구분하지 않음)
class CaseReviewActionBar extends StatelessWidget {
  final ReviewCase reviewCase;

  const CaseReviewActionBar({super.key, required this.reviewCase});

  Future<void> _onApprove(BuildContext context) async {
    final result = await showModalBottomSheet<_ReviewFormResult>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ReviewForm(
        reviewCase: reviewCase,
        title: '승인 · 소견 입력',
        buttonLabel: '승인 확정',
        buttonColor: Colors.blue.shade600,
      ),
    );

    if (result == null || !context.mounted) return;

    final token = context.read<SessionController>().accessToken;
    if (token == null) return;

    try {
      await cases_api.reviewCase(
        caseId: reviewCase.id,
        accessToken: token,
        action: 'confirm',
        finalSubtype: result.type.label, // 'LUAD' | 'LUSC'
        finalNote: result.opinion,
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
    final result = await showModalBottomSheet<_ReviewFormResult>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ReviewForm(
        reviewCase: reviewCase,
        title: '반려 · 소견 수정',
        buttonLabel: '반려 확정',
        buttonColor: Colors.red.shade600,
      ),
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
    // 이미 확정된 케이스는 재승인/반려 대상이 아니라 버튼 자리에 안내 문구만 표시.
    if (reviewCase.status == CaseStatus.confirmed) {
      return SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              '이미 확정된 케이스예요',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

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

class _ReviewFormResult {
  final CaseType type;
  final String opinion;

  _ReviewFormResult({required this.type, required this.opinion});
}

/// 승인/반려 공통 입력폼 — 아형(subtype)과 의사 소견(note)을 입력받아
/// POST /api/cases/{id}/review/의 final_subtype/final_note로 그대로 전송됨.
class _ReviewForm extends StatefulWidget {
  final ReviewCase reviewCase;
  final String title;
  final String buttonLabel;
  final Color buttonColor;

  const _ReviewForm({
    required this.reviewCase,
    required this.title,
    required this.buttonLabel,
    required this.buttonColor,
  });

  @override
  State<_ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends State<_ReviewForm> {
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
            widget.title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          const Text('아형', style: TextStyle(fontWeight: FontWeight.w600)),
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
          const Text('의사 소견', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _opinionController,
            maxLines: 4,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '소견을 입력하세요',
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: widget.buttonColor,
              ),
              onPressed: () {
                Navigator.of(context).pop(
                  _ReviewFormResult(
                    type: _type,
                    opinion: _opinionController.text,
                  ),
                );
              },
              child: Text(widget.buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}