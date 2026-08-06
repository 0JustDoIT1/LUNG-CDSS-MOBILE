import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/api/appointments_api.dart';
import '../../../../core/api/auth_api.dart';
import '../../../../core/api/medications_api.dart';
import '../../../../core/api/symptoms_api.dart';
import '../../../../core/auth/session_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../models/reservation.dart';
import '../care_plan_medication_screen.dart';
import '../symptom_checks_screen.dart';

/// 탭 3(중앙): 홈 대시보드.
/// "담당환자 이상 신호"(GET /api/symptoms/checks/nurse-visible/),
/// "케어플랜 처리 필요"(GET /api/medications/pending-setup/) 실제 API 연동됨.
/// 나머지(예약요약/다음방문)는 아직 mock.
class NurseHomeTab extends StatefulWidget {
  final ValueChanged<int> onNavigateToTab;

  const NurseHomeTab({super.key, required this.onNavigateToTab});

  @override
  State<NurseHomeTab> createState() => _NurseHomeTabState();
}

class _NurseHomeTabState extends State<NurseHomeTab> {
  List<SymptomCheck> _riskChecks = [];
  List<PendingMedicationSetupPatient> _pendingSetup = [];
  List<Appointment> _queue = [];
  List<Appointment> _todayVisits = [];
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

    try {
      final pendingSetup = await fetchPendingMedicationSetupPatients(token);
      if (!mounted) return;
      setState(() => _pendingSetup = pendingSetup);
    } on ApiException catch (_) {
      // 조용히 무시 — 이 섹션만 비어보이면 됨
    }

    try {
      final queue = await fetchAppointmentQueue(token);
      if (!mounted) return;
      setState(() => _queue = queue);
    } on ApiException catch (_) {
      // 조용히 무시 — 카운트만 0으로 표시됨
    }

    try {
      final visits = await fetchTodayVisits(token);
      if (!mounted) return;
      setState(() => _todayVisits = visits);
    } on ApiException catch (_) {
      // 조용히 무시
    }
  }

  List<Appointment> get _unprocessedTodayVisits => _todayVisits.where((a) =>
      a.status == AppointmentStatus.confirmed ||
      a.status == AppointmentStatus.remindedD7 ||
      a.status == AppointmentStatus.remindedD1).toList();

  Appointment? get _nextVisit {
    final now = DateTime.now();
    final upcoming = _unprocessedTodayVisits.where((a) => a.displaySlot.isAfter(now)).toList()
      ..sort((a, b) => a.displaySlot.compareTo(b.displaySlot));
    return upcoming.isEmpty ? null : upcoming.first;
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
            _SummaryRow(
              pendingRequestCount: _queue.length,
              unprocessedTodayCount: _unprocessedTodayVisits.length,
              onNavigateToTab: widget.onNavigateToTab,
            ),
            const SizedBox(height: 16),
            _NextVisitCard(appointment: _nextVisit),
            const SizedBox(height: 24),
            
            _SectionTitle('케어플랜 처리 필요'),
            const SizedBox(height: 8),
            if (_pendingSetup.isEmpty)
              Text(
                '복약설정이 필요한 환자가 없어요',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              )
            else
              ..._pendingSetup.map((p) => _CarePlanTile(
                    name: p.name,
                    subtitle: '치료계획 확정 · 복약설정 대기',
                    patientId: p.id,
                    onReturn: _loadRisk,
                  )),
            const SizedBox(height: 24),
            _SectionTitle('담당환자 이상 신호'),
            const SizedBox(height: 8),
            if (_riskChecks.isEmpty)
              Text(
                '현재 확인이 필요한 위험 신호가 없어요',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              )
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
          style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final int pendingRequestCount;
  final int unprocessedTodayCount;
  final ValueChanged<int> onNavigateToTab;

  const _SummaryRow({
    required this.pendingRequestCount,
    required this.unprocessedTodayCount,
    required this.onNavigateToTab,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: '예약요청 대기',
            value: '$pendingRequestCount건',
            highlighted: pendingRequestCount > 0,
            onTap: () => onNavigateToTab(0), // 예약관리 탭
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: '미방문/방문처리',
            value: '$unprocessedTodayCount건',
            highlighted: false,
            onTap: () => onNavigateToTab(0), // 예약관리 탭
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
  final VoidCallback onTap;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.highlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: highlighted ? Colors.orange.shade50 : colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      color: highlighted ? Colors.orange.shade700 : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: highlighted ? Colors.orange.shade800 : colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Icon(
                  Icons.chevron_right,
                  color: highlighted ? Colors.orange.shade300 : colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NextVisitCard extends StatelessWidget {
  final Appointment? appointment;

  const _NextVisitCard({required this.appointment});

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
    final a = appointment;
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    String two(int n) => n.toString().padLeft(2, '0');
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_available, color: colorScheme.onSurface, size: 18),
              const SizedBox(width: 6),
              Text(
                '다음 방문 예정',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              if (a != null) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.seed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _countdownLabel(a.displaySlot),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          if (a == null)
            Text(
              '오늘 남은 방문이 없어요',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            )
          else ...[
            Text(
              '${a.displaySlot.month}월 ${a.displaySlot.day}일 (${weekdays[a.displaySlot.weekday - 1]})',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${two(a.displaySlot.hour)}:${two(a.displaySlot.minute)}',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${a.patientName}님',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
          ],
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
  final String? patientId; // null이면 UUID 매칭 실패 — 탭 비활성화
  final VoidCallback onReturn;
  const _CarePlanTile({
    required this.name,
    required this.subtitle,
    required this.patientId,
    required this.onReturn,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = patientId != null;
    return GestureDetector(
      onTap: enabled
          ? () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CarePlanMedicationScreen(
                    patientId: patientId!,
                    patientName: name,
                  ),
                ),
              );
              onReturn(); // 스케줄이 새로 생겼을 수 있으니 목록 새로고침
            }
          : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
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
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.orange.shade300),
          ],
        ),
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
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
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