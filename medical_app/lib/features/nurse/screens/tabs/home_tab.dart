import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/api/auth_api.dart';
import '../../../../core/api/symptoms_api.dart';
import '../../../../core/auth/session_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../care_plan_medication_screen.dart';
import '../symptom_checks_screen.dart';

/// 탭 3(중앙): 홈 대시보드.
/// "담당환자 이상 신호"는 실제 API(GET /api/symptoms/checks/nurse-visible/) 연동됨.
/// 나머지(예약요약/다음방문/케어플랜)는 아직 mock.
class NurseHomeTab extends StatefulWidget {
  const NurseHomeTab({super.key});

  @override
  State<NurseHomeTab> createState() => _NurseHomeTabState();
}

class _NurseHomeTabState extends State<NurseHomeTab> {
  List<SymptomCheck> _riskChecks = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRisk());
  }

  Future<void> _loadRisk() async {
    final token = context.read<SessionController>().accessToken;
    if (token == null) return;
    try {
      final checks = await fetchNurseVisibleSymptomChecks(token);
      checks.sort((a, b) {
        if (a.isRed != b.isRed) return a.isRed ? -1 : 1;
        return b.checkedAt.compareTo(a.checkedAt);
      });
      if (!mounted) return;
      setState(() => _riskChecks = checks.where((c) => !c.nurseReviewed).toList());
    } on ApiException catch (_) {
      // 조용히 무시 — 이 섹션만 비어보이면 됨
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GreetingHeader(),
            const SizedBox(height: 16),
            const _SummaryRow(),
            const SizedBox(height: 16),
            const _NextVisitCard(),
            const SizedBox(height: 24),
            _SectionTitle('케어플랜 처리 필요'),
            const SizedBox(height: 8),
            const _CarePlanTile(name: '홍길동', subtitle: '치료계획 확정 · 복약설정 대기'),
            const _CarePlanTile(name: '이순신', subtitle: '치료계획 확정 · 복약설정 대기'),
            const SizedBox(height: 24),
            _SectionTitle('담당환자 이상 신호'),
            const SizedBox(height: 8),
            if (_riskChecks.isEmpty)
              Text('현재 확인이 필요한 위험 신호가 없어요', style: TextStyle(color: Colors.grey.shade500))
            else
              ..._riskChecks.take(3).map((c) => _AlertPatientTile(check: c)),
          ],
        ),
      ),
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '박간호사님',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          '오늘의 예약요청·케어플랜 현황',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: '예약요청 대기',
            value: '5건',
            highlighted: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: '미방문/방문처리',
            value: '3건',
            highlighted: false,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final bool highlighted;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.highlighted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlighted ? Colors.orange.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: highlighted ? Colors.orange.shade700 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: highlighted ? Colors.orange.shade800 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

/// 다음 방문 예정 — 가장 가까운 체크인 대상 1건만 크게 강조.
/// TODO: 실제 연결 시 mock 대신 오늘 예약 중 가장 가까운 대기중 건으로 교체.
class _NextVisitCard extends StatelessWidget {
  const _NextVisitCard();

  DateTime get _mockNextVisit => DateTime.now().add(const Duration(minutes: 20));

  String _countdownLabel(DateTime target) {
    final diff = target.difference(DateTime.now());
    if (diff.isNegative) return '진행중';
    if (diff.inMinutes < 1) return '곧 도착';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 후';
    final hours = diff.inMinutes ~/ 60;
    final mins = diff.inMinutes % 60;
    return mins == 0 ? '$hours시간 후' : '$hours시간 $mins분 후';
  }

  @override
  Widget build(BuildContext context) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final visit = _mockNextVisit;
    final dateLabel = '${visit.month}월 ${visit.day}일 (${weekdays[visit.weekday - 1]})';
    String two(int n) => n.toString().padLeft(2, '0');
    final timeLabel = '${two(visit.hour)}:${two(visit.minute)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_available, color: Colors.black87, size: 18),
              const SizedBox(width: 6),
              const Text(
                '다음 방문 예정',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.seed,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _countdownLabel(visit),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            dateLabel,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            timeLabel,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '이순신님',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    );
  }
}

class _CarePlanTile extends StatelessWidget {
  final String name;
  final String subtitle;

  const _CarePlanTile({required this.name, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CarePlanMedicationScreen(patientName: name),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.orange.shade300),
          ],
        ),
      ),
    );
  }
}

class _AlertPatientTile extends StatelessWidget {
  final SymptomCheck check;

  const _AlertPatientTile({required this.check});

  @override
  Widget build(BuildContext context) {
    final color = check.isRed ? Colors.red : (check.isYellow ? Colors.orange : Colors.green);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SymptomChecksScreen()),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 0,
        color: Colors.grey.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(Icons.priority_high, color: color),
          ),
          title: Text(check.patientName),
          subtitle: Text(check.isRed ? '위험(RED) 신호 감지' : '주의(YELLOW) 신호 감지'),
          trailing: Chip(
            label: const Text('확인필요'),
            backgroundColor: Colors.orange.shade50,
            labelStyle: TextStyle(
              color: Colors.orange.shade800,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            side: BorderSide.none,
          ),
        ),
      ),
    );
  }
}