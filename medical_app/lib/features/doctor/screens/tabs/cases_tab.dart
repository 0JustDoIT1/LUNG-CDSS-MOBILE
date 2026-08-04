import 'package:flutter/material.dart';

import '../../mock/review_case_mock.dart';
import '../../models/review_case.dart';
import '../case_detail_screen.dart';

/// 탭 1: 검토대기 큐.
///
/// - 정렬: confidence 낮은순(기본) ↔ 접수순 토글
/// - 즐겨찾기 필터: 즐겨찾기한 케이스만 보기
/// - confidence 70% 미만이면 빨간 "긴급" 뱃지
///
/// TODO: 실제 연결 시 mockReviewCases() 대신 repository/provider에서 데이터 받아오기.
/// TODO: 케이스 탭하면 AI 결과 상세뷰로 이동하는 라우트 추가 (2단계).
class CasesTab extends StatefulWidget {
  const CasesTab({super.key});

  @override
  State<CasesTab> createState() => _CasesTabState();
}

enum _SortMode { confidence, submittedOrder }

class _CasesTabState extends State<CasesTab> {
  _SortMode _sortMode = _SortMode.confidence;
  bool _favoriteOnly = false;
  late final List<ReviewCase> _allCases = mockReviewCases();

  void _toggleFavorite(ReviewCase c) {
    setState(() => c.isFavorite = !c.isFavorite);
  }

  @override
  Widget build(BuildContext context) {
    var cases = List.of(_allCases);

    if (_favoriteOnly) {
      cases = cases.where((c) => c.isFavorite).toList();
    }

    cases.sort((a, b) {
      if (_sortMode == _SortMode.confidence) {
        return a.confidence.compareTo(b.confidence); // 낮은순 우선
      }
      return a.submittedAt.compareTo(b.submittedAt); // 접수순
    });

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '검토대기',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  InkWell(
                    onTap: () => setState(() {
                      _sortMode = _sortMode == _SortMode.confidence
                          ? _SortMode.submittedOrder
                          : _SortMode.confidence;
                    }),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Row(
                        children: [
                          Icon(Icons.swap_vert, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 2),
                          Text(
                            _sortMode == _SortMode.confidence ? '신뢰도순' : '접수순',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: '즐겨찾기만 보기',
                    onPressed: () =>
                        setState(() => _favoriteOnly = !_favoriteOnly),
                    icon: Icon(
                      _favoriteOnly ? Icons.star : Icons.star_border,
                      color: _favoriteOnly ? Colors.amber : null,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: cases.isEmpty
              ? const Center(child: Text('표시할 케이스가 없어요'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: cases.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final c = cases[index];
                    return _CaseCard(reviewCase: c, onToggleFavorite: _toggleFavorite);
                  },
                ),
        ),
      ],
    );
  }
}

class _CaseCard extends StatelessWidget {
  final ReviewCase reviewCase;
  final void Function(ReviewCase) onToggleFavorite;

  const _CaseCard({required this.reviewCase, required this.onToggleFavorite});

  @override
  Widget build(BuildContext context) {
    final c = reviewCase;
    final confidencePercent = (c.confidence * 100).round();

    return Card(
      color: Colors.white,
      child: ListTile(
        leading: IconButton(
          onPressed: () => onToggleFavorite(c),
          icon: Icon(
            c.isFavorite ? Icons.star : Icons.star_border,
            size: 28,
            color: c.isFavorite ? Colors.amber : Colors.grey.shade400,
          ),
        ),
        title: Text(
          c.patientName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${c.type.label} · $confidencePercent%'),
            Text(
              _timeAgo(c.submittedAt),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
        trailing: _Pill(
          label: c.status.label,
          color: switch (c.status) {
            CaseStatus.pending => Colors.orange,
            CaseStatus.approved => Colors.green,
            CaseStatus.rejected => Colors.red,
          },
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CaseDetailScreen(reviewCase: c),
            ),
          );
        },
      ),
    );
  }
}

/// 케이스 목록 상태 뱃지 — 크기(너비)를 통일해서 보여줌.
class _Pill extends StatelessWidget {
  final String label;
  final MaterialColor color;

  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(vertical: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color.shade700,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

String _timeAgo(DateTime time) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${time.year}-${two(time.month)}-${two(time.day)} '
      '${two(time.hour)}:${two(time.minute)}';
}