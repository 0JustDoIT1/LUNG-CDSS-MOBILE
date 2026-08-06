import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/api/auth_api.dart';
import '../../../../core/api/cases_api.dart';
import '../../../../core/auth/session_controller.dart';
import '../../../../core/lifecycle/app_resume_notifier.dart';
import '../../../../main.dart';
import '../../models/review_case.dart';
import '../case_detail_screen.dart';

/// 탭 1: 검토대기 큐. 실제 API(GET /api/cases/) 연동됨.
///
/// - 정렬: confidence 낮은순(기본) ↔ 접수순 토글
/// - 즐겨찾기 필터: 즐겨찾기한 케이스만 보기
/// - confidence 70% 미만이면 빨간 "긴급" 뱃지
/// - 포그라운드 푸시 수신 + 앱 재개(resume) 시 새로고침으로, 새로 들어온 케이스가 반영됨.
class CasesTab extends StatefulWidget {
  const CasesTab({super.key});

  @override
  State<CasesTab> createState() => _CasesTabState();
}

enum _SortMode { confidence, submittedOrder }

class _CasesTabState extends State<CasesTab> {
  _SortMode _sortMode = _SortMode.confidence;
  bool _favoriteOnly = false;

  List<ReviewCase>? _cases;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    fcmService.incomingMessage.addListener(_silentRefresh);
    appResumeNotifier.addListener(_silentRefresh);
  }

  @override
  void dispose() {
    fcmService.incomingMessage.removeListener(_silentRefresh);
    appResumeNotifier.removeListener(_silentRefresh);
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final token = context.read<SessionController>().accessToken;
    if (token == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = '로그인이 필요해요.';
      });
      return;
    }

    try {
      final cases = await fetchCases(token);
      if (!mounted) return;
      setState(() {
        _cases = cases;
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

  /// 폴링/푸시 수신 시 배경에서 조용히 새로고침 — 실패해도 기존 목록 유지, 로딩/에러 화면 건드리지 않음.
  Future<void> _silentRefresh() async {
    final token = context.read<SessionController>().accessToken;
    if (token == null) return;
    try {
      final cases = await fetchCases(token);
      if (!mounted) return;
      setState(() => _cases = cases);
    } on ApiException catch (_) {
      // 조용히 무시
    }
  }

  Future<void> _toggleFavorite(ReviewCase c) async {
    final token = context.read<SessionController>().accessToken;
    if (token == null) return;

    setState(() => c.isFavorite = !c.isFavorite); // 낙관적 업데이트
    try {
      await toggleCaseFavorite(c.id, token);
    } on ApiException catch (_) {
      if (!mounted) return;
      setState(() => c.isFavorite = !c.isFavorite); // 실패하면 되돌리기
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('즐겨찾기 처리에 실패했어요')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                          Icon(
                            Icons.swap_vert,
                            size: 16,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            _sortMode == _SortMode.confidence ? '신뢰도순' : '접수순',
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
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
                  IconButton(
                    tooltip: '새로고침',
                    onPressed: _load,
                    icon: const Icon(Icons.refresh, size: 20),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(child: _buildBody()),
      ],
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

    var cases = List.of(_cases ?? []);

    if (_favoriteOnly) {
      cases = cases.where((c) => c.isFavorite).toList();
    }

    cases.sort((a, b) {
      if (_sortMode == _SortMode.confidence) {
        return a.confidence.compareTo(b.confidence); // 낮은순 우선
      }
      return a.uploadedAt.compareTo(b.uploadedAt); // 접수순
    });

    if (cases.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Center(child: Text('표시할 케이스가 없어요')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: cases.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final c = cases[index];
          return _CaseCard(
            reviewCase: c,
            onToggleFavorite: _toggleFavorite,
            onTap: () async {
              final needsRefresh = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => CaseDetailScreen(reviewCase: c)),
              );
              if (needsRefresh == true) _load();
            },
          );
        },
      ),
    );
  }
}

class _CaseCard extends StatelessWidget {
  final ReviewCase reviewCase;
  final void Function(ReviewCase) onToggleFavorite;
  final VoidCallback onTap;

  const _CaseCard({
    required this.reviewCase,
    required this.onToggleFavorite,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = reviewCase;
    final confidencePercent = (c.confidence * 100).round();

    return Card(
      child: ListTile(
        leading: IconButton(
          onPressed: () => onToggleFavorite(c),
          icon: Icon(
            c.isFavorite ? Icons.star : Icons.star_border,
            size: 28,
            color: c.isFavorite ? Colors.amber : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        title: Text(c.patientName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${c.type.label} · $confidencePercent%'),
            Text(
              _timeAgo(c.uploadedAt),
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        trailing: _Pill(
          label: c.status.label,
          color: switch (c.status) {
            CaseStatus.pending => Colors.orange,
            CaseStatus.confirmed => Colors.green,
          },
        ),
        onTap: onTap,
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