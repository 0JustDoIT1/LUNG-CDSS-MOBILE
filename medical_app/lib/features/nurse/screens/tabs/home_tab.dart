import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/api/appointments_api.dart';
import '../../../../core/api/auth_api.dart';
import '../../../../core/api/medications_api.dart';
import '../../../../core/auth/session_controller.dart';
import '../../../../core/lifecycle/app_resume_notifier.dart';
import '../../../../core/widget/home_widget_service.dart';
import '../../../../main.dart';
import '../../models/reservation.dart';
import '../care_plan_medication_screen.dart';

/// 탭 3(중앙): 홈 대시보드.
/// "케어플랜 처리 필요"(GET /api/medications/pending-setup/) 실제 API 연동됨.
/// 나머지(예약요약/다음방문)는 아직 mock.
/// 포그라운드 푸시 수신 + 앱 재개(resume) 시 새로고침으로 자동 반영됨.
class NurseHomeTab extends StatefulWidget {
  final ValueChanged<int> onNavigateToTab;

  const NurseHomeTab({super.key, required this.onNavigateToTab});

  @override
  State<NurseHomeTab> createState() => _NurseHomeTabState();
}

class _NurseHomeTabState extends State<NurseHomeTab> {
  List<PendingMedicationSetupPatient> _pendingSetup = [];
  List<Appointment> _queue = [];
  List<Appointment> _todayVisits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    fcmService.incomingMessage.addListener(_refresh);
    appResumeNotifier.addListener(_refresh);
  }

  @override
  void dispose() {
    fcmService.incomingMessage.removeListener(_refresh);
    appResumeNotifier.removeListener(_refresh);
    super.dispose();
  }

  /// 최초 진입 시에만 스피너를 보여주고 조회 — 0건으로 먼저 그려졌다가 실제 값으로
  /// 바뀌는(한 박자 늦게 뜨는) 게 보이지 않도록.
  Future<void> _load() async {
    await _refresh();
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  /// 3개 API를 동시에 쏴서(순차 await이면 응답시간이 다 더해짐) 기다린다.
  /// 섹션별로 실패해도 나머지는 계속 보여줘야 해서 각자 따로 try/catch.
  Future<void> _refresh() async {
    final token = context.read<SessionController>().accessToken;
    if (token == null) return;

    final pendingFuture = fetchPendingMedicationSetupPatients(token);
    final queueFuture = fetchAppointmentQueue(token);
    final visitsFuture = fetchTodayVisits(token);

    try {
      final pendingSetup = await pendingFuture;
      if (!mounted) return;
      setState(() => _pendingSetup = pendingSetup);
    } on ApiException catch (_) {
      // 조용히 무시 — 이 섹션만 비어보이면 됨
    }

    try {
      final queue = await queueFuture;
      if (!mounted) return;
      setState(() => _queue = queue);
      updatePendingAppointmentsWidget(requestCount: queue.length);
    } on ApiException catch (_) {
      // 조용히 무시 — 카운트만 0으로 표시됨
    }

    try {
      final visits = await visitsFuture;
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
            // 인사말은 네트워크 응답을 기다릴 필요가 없으니 항상 즉시 표시.
            _GreetingHeader(),
            const SizedBox(height: 18),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              _SummaryRow(
                pendingRequestCount: _queue.length,
                unprocessedTodayCount: _unprocessedTodayVisits.length,
                onNavigateToTab: widget.onNavigateToTab,
              ),
              const SizedBox(height: 16),
              _NextVisitCard(appointment: _nextVisit),
              const SizedBox(height: 24),

              /// 케어플랜 처리 필요 섹션
              _SectionTitle(
                '케어플랜 처리 필요',
                count: _pendingSetup.length,
                badgeColor: const Color(0xFF2B78D4),
              ),
              const SizedBox(height: 10),
              if (_pendingSetup.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.assignment_turned_in_outlined, color: Colors.blue.shade600, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '복약설정이 필요한 환자가 없습니다',
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                )
              else
                ..._pendingSetup.map((p) => _CarePlanTile(
                      name: p.name,
                      subtitle: '치료계획 확정 · 복약설정 대기',
                      patientId: p.id,
                      onReturn: _refresh,
                    )),
            ],
          ],
        ),
      ),
    );
  }
}

/// 🎨 [수정] 상단 인사말 헤더 꾸미기 (간호사님 뱃지 포함)
class _GreetingHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF2B78D4).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2B78D4).withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF2B78D4),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2B78D4).withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      '박간호사님',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF26B2C8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '호흡기내과',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '오늘의 예약요청·케어플랜 현황입니다',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
            icon: Icons.pending_actions_rounded,
            highlighted: pendingRequestCount > 0,
            onTap: () => onNavigateToTab(0), // 예약관리 탭
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: '미방문/방문처리',
            value: '$unprocessedTodayCount건',
            icon: Icons.calendar_today_rounded,
            highlighted: false,
            onTap: () => onNavigateToTab(0), // 예약관리 탭
          ),
        ),
      ],
    );
  }
}

/// 상단 요약 카드 (Colors.slateBg 에러 수정 완료)
class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool highlighted;
  final VoidCallback onTap;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.highlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = highlighted ? const Color(0xFF2B78D4) : Colors.grey.shade600;
    final primaryBg = highlighted
        ? const Color(0xFF2B78D4).withValues(alpha: 0.08)
        : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: primaryBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlighted
              ? const Color(0xFF2B78D4).withValues(alpha: 0.3)
              : Colors.grey.shade200,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: highlighted
                            ? const Color(0xFF2B78D4)
                            : Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        size: 18,
                        color: highlighted ? Colors.white : Colors.grey.shade700,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: highlighted
                          ? const Color(0xFF2B78D4)
                          : Colors.grey.shade400,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: activeColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                    color: highlighted
                        ? const Color(0xFF1E293B)
                        : Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 🎨 [수정] 다음 방문 예정 카드 (그라데이션 제거 + 깔끔한 레이아웃 재배치)
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

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2B78D4).withValues(alpha: 0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2B78D4).withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 카드 헤더 부분
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF2B78D4).withValues(alpha: 0.06),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.event_available_rounded, color: Color(0xFF2B78D4), size: 18),
                const SizedBox(width: 8),
                const Text(
                  '다음 방문 예정 일정',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2B78D4),
                  ),
                ),
                if (a != null) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2B78D4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _countdownLabel(a.displaySlot),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          /// 카드 내부 바디 영역 (시각, 날짜, 환자 정보 재배치)
          Padding(
            padding: const EdgeInsets.all(18),
            child: a == null
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      '오늘 남은 대기 환자가 없습니다',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  )
                : Row(
                    children: [
                      /// 좌측: 시간 및 날짜 정보
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${two(a.displaySlot.hour)}:${two(a.displaySlot.minute)}',
                              style: const TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.5,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.calendar_month_rounded, size: 14, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  '${a.displaySlot.month}월 ${a.displaySlot.day}일 (${weekdays[a.displaySlot.weekday - 1]})',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      /// 구분선
                      Container(
                        height: 40,
                        width: 1,
                        color: Colors.grey.shade200,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                      ),

                      /// 우측: 환자 정보 영역
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '예약 환자',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${a.patientName} 환자님',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// 카운터 뱃지가 결합된 섹션 타이틀
class _SectionTitle extends StatelessWidget {
  final String text;
  final int? count;
  final Color badgeColor;

  const _SectionTitle(this.text, {this.count, this.badgeColor = Colors.blue});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: -0.4),
        ),
        if (count != null && count! > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// 케어플랜 처리 필요 타일
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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2B78D4).withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2B78D4).withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
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
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2B78D4).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.medication_liquid_rounded,
                    color: Color(0xFF2B78D4),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2B78D4).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '복약 미설정',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2B78D4),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2B78D4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '설정하기',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
