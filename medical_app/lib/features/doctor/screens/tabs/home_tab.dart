import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/api/appointments_api.dart';
import '../../../../core/api/auth_api.dart';
import '../../../../core/api/cases_api.dart';
import '../../../../core/auth/session_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../models/appointment.dart';
import '../../models/review_case.dart';
import '../case_detail_screen.dart';
import '../patient_detail_screen.dart';

/// 탭 3(중앙): 홈 대시보드. 실제 API(cases, appointments) 연동됨.
/// 케이스 조회 실패 시에만 전체 에러 화면을 보여주고, 예약 조회는 독립적으로 실패를 허용해
/// (예: /api/appointments/mine/ 403) 나머지 섹션은 정상 표시되도록 처리.
class DoctorHomeTab extends StatefulWidget {
  final ValueChanged<int> onNavigateToTab;

  const DoctorHomeTab({super.key, required this.onNavigateToTab});

  @override
  State<DoctorHomeTab> createState() => _DoctorHomeTabState();
}

class _DoctorHomeTabState extends State<DoctorHomeTab> {
  List<ReviewCase> _cases = [];
  List<Appointment> _appointments = [];
  bool _isLoading = true;
  String? _casesErrorMessage;
  String? _appointmentsErrorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _casesErrorMessage = null;
      _appointmentsErrorMessage = null;
    });
    final token = context.read<SessionController>().accessToken;
    if (token == null) return;

    // 케이스 조회 — 홈 화면의 핵심 데이터라 실패 시 전체 에러 화면으로 처리
    try {
      final cases = await fetchCases(token);
      if (!mounted) return;
      setState(() => _cases = cases);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _casesErrorMessage = e.message);
    }

    // 예약 조회 — 독립적으로 실패 허용 (예: appointments/mine/ 403이어도 나머지 섹션은 유지)
    try {
      final rawAppointments = await fetchMyAppointmentsRaw(token);
      if (!mounted) return;
      setState(() => _appointments = rawAppointments.map(Appointment.fromJson).toList());
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _appointmentsErrorMessage = e.message);
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  List<ReviewCase> get _pendingCases =>
      _cases.where((c) => c.status == CaseStatus.pending).toList();

  int get _urgentCount => _pendingCases.where((c) => c.isUrgent).length;

  List<Appointment> get _todayAppointments {
    final now = DateTime.now();
    return _appointments
        .where((a) =>
            a.dateTime.year == now.year &&
            a.dateTime.month == now.month &&
            a.dateTime.day == now.day)
        .toList();
  }

  Appointment? get _nextAppointment {
    final now = DateTime.now();
    final upcoming = _todayAppointments.where((a) => a.dateTime.isAfter(now)).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return upcoming.isEmpty ? null : upcoming.first;
  }

  List<ReviewCase> get _favoriteCases => _cases.where((c) => c.isFavorite).toList();

  List<ReviewCase> get _recentPendingCases {
    final list = List.of(_pendingCases)
      ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
    return list.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 케이스 조회 자체가 실패하면 홈 화면을 구성할 핵심 데이터가 없으므로 전체 에러 화면
    if (_casesErrorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _casesErrorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: _load, child: const Text('다시 시도')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GreetingHeader(),
              const SizedBox(height: 16),
              _SummaryRow(
                pendingCount: _pendingCases.length,
                urgentCount: _urgentCount,
                todayAppointmentCount:
                    _appointmentsErrorMessage == null ? _todayAppointments.length : null,
                onNavigateToTab: widget.onNavigateToTab,
              ),
              const SizedBox(height: 16),
              _appointmentsErrorMessage != null
                  ? _AppointmentUnavailableCard(onRetry: _load)
                  : _NextAppointmentCard(appointment: _nextAppointment),
              const SizedBox(height: 24),
              _SectionTitle('즐겨찾기 케이스', icon: Icons.star, color: AppTheme.gradientStart),
              const SizedBox(height: 8),
              if (_favoriteCases.isEmpty)
                Text(
                  '즐겨찾기한 케이스가 없어요',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                )
              else
                ..._favoriteCases.map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _FavoriteCaseTile(reviewCase: c),
                    )),
              const SizedBox(height: 24),
              _SectionTitle('최근 검토대기', icon: Icons.pending_actions, color: AppTheme.gradientEnd),
              const SizedBox(height: 8),
              if (_recentPendingCases.isEmpty)
                Text(
                  '검토대기 중인 케이스가 없어요',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                )
              else
                ..._recentPendingCases.map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _RecentCaseTile(reviewCase: c),
                    )),
            ],
          ),
        ),
      ),
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.medical_services, color: AppTheme.seed, size: 22),
            const SizedBox(width: 6),
            Text(
              '${session.name}님',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '오늘의 검토대기·예약 현황',
          style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final int pendingCount;
  final int urgentCount;
  final int? todayAppointmentCount; // null = 조회 실패
  final ValueChanged<int> onNavigateToTab;

  const _SummaryRow({
    required this.pendingCount,
    required this.urgentCount,
    required this.todayAppointmentCount,
    required this.onNavigateToTab,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _SummaryCard(
              title: '검토대기',
              value: '$pendingCount건',
              subtitle: urgentCount > 0 ? '긴급 $urgentCount건 포함' : null,
              cardColor: AppTheme.gradientEnd,
              onTap: () => onNavigateToTab(0), // 케이스(검토대기) 탭
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SummaryCard(
              title: '오늘 예약',
              value: todayAppointmentCount != null ? '$todayAppointmentCount건' : '—',
              subtitle: todayAppointmentCount == null ? '불러오기 실패' : null,
              cardColor: AppTheme.gradientStart,
              onTap: () => onNavigateToTab(1), // 일정 탭
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final Color cardColor;
  final VoidCallback onTap;

  const _SummaryCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.cardColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      shadowColor: cardColor.withValues(alpha: 0.5),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        hoverColor: Colors.white.withValues(alpha: 0.12),
        splashColor: Colors.white.withValues(alpha: 0.2),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: const TextStyle(fontSize: 13, color: Colors.white70)),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle ?? ' ', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ),
              const Positioned(
                top: 0,
                right: 0,
                child: Icon(Icons.chevron_right, color: Colors.white70, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 오늘의 다음 진료 — 가장 가까운 예약 1건만 크게 강조해서 보여줌. appointment가 null이면 "예약 없음" 표시.
class _NextAppointmentCard extends StatelessWidget {
  final Appointment? appointment;

  const _NextAppointmentCard({required this.appointment});

  String _countdownLabel(DateTime target) {
    final diff = target.difference(DateTime.now());
    if (diff.isNegative) return '진행중';
    if (diff.inMinutes < 1) return '곧 시작';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 후';
    final hours = diff.inMinutes ~/ 60;
    final mins = diff.inMinutes % 60;
    return mins == 0 ? '$hours시간 후' : '$hours시간 $mins분 후';
  }

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, color: onSurface, size: 18),
              const SizedBox(width: 6),
              Text(
                '오늘의 다음 진료',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: onSurface),
              ),
              if (a != null) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.seed, borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    _countdownLabel(a.dateTime),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          if (a == null)
            Text(
              '오늘 남은 예약이 없어요',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            )
          else ...[
            Builder(builder: (context) {
              const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
              final dateLabel =
                  '${a.dateTime.month}월 ${a.dateTime.day}일 (${weekdays[a.dateTime.weekday - 1]})';
              String two(int n) => n.toString().padLeft(2, '0');
              final timeLabel = '${two(a.dateTime.hour)}:${two(a.dateTime.minute)}';
              final colorScheme = Theme.of(context).colorScheme;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeLabel,
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: colorScheme.onSurface),
                  ),
                ],
              );
            }),
          ],
        ],
      ),
    );
  }
}

/// 예약 조회 API(예: appointments/mine/)가 실패했을 때 표시되는 대체 카드. 케이스 섹션은 정상 유지.
class _AppointmentUnavailableCard extends StatelessWidget {
  final VoidCallback onRetry;

  const _AppointmentUnavailableCard({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colorScheme.onSurfaceVariant, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '일정 정보를 불러오지 못했어요',
              style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('재시도')),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;

  const _SectionTitle(this.text, {required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _FavoriteCaseTile extends StatelessWidget {
  final ReviewCase reviewCase;

  const _FavoriteCaseTile({required this.reviewCase});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.star, color: Colors.amber, size: 22),
        title: Text(reviewCase.patientName),
        trailing: Chip(
          label: Text(reviewCase.type.label),
          backgroundColor: Colors.blue.shade50,
          labelStyle: TextStyle(color: Colors.blue.shade700, fontSize: 12),
          side: BorderSide.none,
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => PatientDetailScreen(patientName: reviewCase.patientName)),
          );
        },
      ),
    );
  }
}

class _RecentCaseTile extends StatelessWidget {
  final ReviewCase reviewCase;

  const _RecentCaseTile({required this.reviewCase});

  @override
  Widget build(BuildContext context) {
    final confidencePercent = (reviewCase.confidence * 100).round();

    return Card(
      child: ListTile(
        leading: Icon(Icons.pending_actions, color: AppTheme.gradientEnd, size: 22),
        title: Text(reviewCase.patientName),
        subtitle: Text('신뢰도 $confidencePercent%'),
        trailing: reviewCase.isUrgent
            ? Chip(
                label: const Text('긴급'),
                backgroundColor: Colors.red.shade50,
                labelStyle: TextStyle(color: Colors.red.shade700, fontSize: 12, fontWeight: FontWeight.w600),
                side: BorderSide.none,
              )
            : null,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => CaseDetailScreen(reviewCase: reviewCase)),
          );
        },
      ),
    );
  }
}