import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../mock/reservation_mock.dart';
import '../../models/reservation.dart';

/// 탭 1: 예약요청 큐 관리 + 진료관리(노쇼/방문 처리).
/// - 예약요청: 신청리스트(환자명, 희망 과/의사/일시, 신청시각) → 승인
/// - 진료관리: 오늘 예약리스트(시간순, 체크인상태) → 방문처리/노쇼/QR스캔
///
/// TODO: 실제 연결 시 mock 데이터 대신 API로 교체.
class QueueTab extends StatefulWidget {
  const QueueTab({super.key});

  @override
  State<QueueTab> createState() => _QueueTabState();
}

class _QueueTabState extends State<QueueTab> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final List<ReservationRequest> _requests = mockReservationRequests();
  late final List<TodayAppointment> _todayAppointments = mockTodayAppointments();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _approve(ReservationRequest r) {
    setState(() => _requests.remove(r));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${r.patientName} 예약 승인 완료')),
    );
    // TODO: Appointment.status=confirmed 저장 API 연결
  }

  void _reject(ReservationRequest r) {
    setState(() => _requests.remove(r));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${r.patientName} 예약 반려')),
    );
    // TODO: 반려 처리 API 연결
  }

  void _setStatus(TodayAppointment a, CheckInStatus status) {
    setState(() => a.status = status);
  }

  void _scanQr() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('QR 스캔은 카메라 연동 후 지원돼요')),
    );
    // TODO: 카메라로 QR 스캔 → Redis 토큰 검증 → 자동 checked_in 처리
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: Colors.black,
            tabs: const [
              Tab(text: '예약요청'),
              Tab(text: '진료관리'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _RequestListView(
                  requests: _requests,
                  onApprove: _approve,
                  onReject: _reject,
                ),
                _TodayListView(
                  appointments: _todayAppointments,
                  onSetStatus: _setStatus,
                  onScanQr: _scanQr,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestListView extends StatelessWidget {
  final List<ReservationRequest> requests;
  final void Function(ReservationRequest) onApprove;
  final void Function(ReservationRequest) onReject;

  const _RequestListView({
    required this.requests,
    required this.onApprove,
    required this.onReject,
  });

  String _fmtRequestedAt(DateTime d) {
    return '${_fmtDate(d)} ${_fmtTime(d)}';
  }

  String _fmtDate(DateTime d) => '${d.month}월 ${d.day}일';

  String _fmtTime(DateTime d) {
    final isAm = d.hour < 12;
    final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final minute = d.minute.toString().padLeft(2, '0');
    return '${isAm ? '오전' : '오후'} $hour12:$minute';
  }

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return const Center(child: Text('대기 중인 예약요청이 없어요'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final r = requests[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(r.patientName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(width: 8),
                  Text(
                    '신청 ${_fmtRequestedAt(r.requestedAt)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${r.department} · ${r.doctorName}',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 8),
              const Text(
                '예약 일정',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_fmtDate(r.desiredDateTime)} ${_fmtTime(r.desiredDateTime)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      label: '승인',
                      color: Colors.lightGreen.shade700,
                      filled: true,
                      onTap: () => onApprove(r),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionButton(
                      label: '반려',
                      color: Colors.red.shade600,
                      filled: true,
                      onTap: () => onReject(r),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 승인/반려용 작은 버튼. 마우스 올리면 색이 살짝 진해짐.
class _ActionButton extends StatefulWidget {
  final String label;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.filled,
    required this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = _isPressed
        ? Color.lerp(widget.color, Colors.black, 0.15)!
        : widget.color;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          widget.label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

/// 대기중인지, 처리완료(방문완료/미방문)인지 판단.
/// 대기 상태에서 30분 지나면 자동으로 미방문 확정 (별도 버튼 없이).
CheckInStatus _effectiveStatus(TodayAppointment a) {
  if (a.status != CheckInStatus.waiting) return a.status;
  final elapsedMin = DateTime.now().difference(a.dateTime).inMinutes;
  return elapsedMin >= 30 ? CheckInStatus.noShow : CheckInStatus.waiting;
}

class _TodayListView extends StatefulWidget {
  final List<TodayAppointment> appointments;
  final void Function(TodayAppointment, CheckInStatus) onSetStatus;
  final VoidCallback onScanQr;

  const _TodayListView({
    required this.appointments,
    required this.onSetStatus,
    required this.onScanQr,
  });

  @override
  State<_TodayListView> createState() => _TodayListViewState();
}

class _TodayListViewState extends State<_TodayListView>
    with SingleTickerProviderStateMixin {
  late final TabController _subTabController;

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sorted = List.of(widget.appointments)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final pending = sorted.where((a) => _effectiveStatus(a) == CheckInStatus.waiting).toList();
    final done = sorted.where((a) => _effectiveStatus(a) != CheckInStatus.waiting).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: TabBar(
                  controller: _subTabController,
                  labelColor: AppTheme.gradientEnd,
                  unselectedLabelColor: Colors.grey.shade500,
                  indicatorColor: AppTheme.gradientEnd,
                  tabs: [
                    Tab(text: '대기중 (${pending.length})'),
                    Tab(text: '처리완료 (${done.length})'),
                  ],
                ),
              ),
              IconButton(
                onPressed: widget.onScanQr,
                icon: const Icon(Icons.qr_code_scanner, size: 20),
                tooltip: 'QR스캔',
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _subTabController,
            children: [
              _AppointmentList(
                appointments: pending,
                onSetStatus: widget.onSetStatus,
                emptyText: '대기 중인 환자가 없어요',
              ),
              _AppointmentList(
                appointments: done,
                onSetStatus: widget.onSetStatus,
                emptyText: '처리완료된 환자가 없어요',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AppointmentList extends StatelessWidget {
  final List<TodayAppointment> appointments;
  final void Function(TodayAppointment, CheckInStatus) onSetStatus;
  final String emptyText;

  const _AppointmentList({
    required this.appointments,
    required this.onSetStatus,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    if (appointments.isEmpty) {
      return Center(child: Text(emptyText, style: TextStyle(color: Colors.grey.shade500)));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: appointments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return _AppointmentRow(appointment: appointments[index], onSetStatus: onSetStatus);
      },
    );
  }
}

class _AppointmentRow extends StatelessWidget {
  final TodayAppointment appointment;
  final void Function(TodayAppointment, CheckInStatus) onSetStatus;

  const _AppointmentRow({required this.appointment, required this.onSetStatus});

  @override
  Widget build(BuildContext context) {
    String two(int n) => n.toString().padLeft(2, '0');
    final time =
        '${two(appointment.dateTime.hour)}:${two(appointment.dateTime.minute)}';

    final status = _effectiveStatus(appointment);
    final elapsedMin = DateTime.now().difference(appointment.dateTime).inMinutes;
    // 20분 넘으면 곧 자동 미방문 처리된다는 경고 표시만 (아직 버튼은 없음).
    final isNearAutoNoShow = status == CheckInStatus.waiting && elapsedMin >= 20;

    final subtitle = status != CheckInStatus.waiting || isNearAutoNoShow
        ? '$time · ${elapsedMin.clamp(0, 999)}분 경과'
        : time;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isNearAutoNoShow ? Colors.orange.shade300 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(appointment.patientName, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isNearAutoNoShow ? Colors.orange.shade700 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          _StatusPill(
            label: status == CheckInStatus.checkedIn
                ? '방문완료'
                : status == CheckInStatus.noShow
                    ? '미방문'
                    : '방문처리',
            color: status == CheckInStatus.checkedIn
                ? Colors.green.shade700
                : status == CheckInStatus.noShow
                    ? Colors.red.shade700
                    : Colors.lightBlue.shade700,
            filled: status == CheckInStatus.waiting,
            onTap: status == CheckInStatus.waiting
                ? () => onSetStatus(appointment, CheckInStatus.checkedIn)
                : null,
          ),
        ],
      ),
    );
  }
}

/// 진료관리 리스트의 상태 뱃지/버튼 — 크기를 통일해서 보여줌.
class _StatusPill extends StatefulWidget {
  final String label;
  final Color color;
  final bool filled; // true면 꽉 채운 버튼(액션), false면 옅은 배경 뱃지(상태표시)
  final VoidCallback? onTap;

  const _StatusPill({
    required this.label,
    required this.color,
    required this.filled,
    required this.onTap,
  });

  @override
  State<_StatusPill> createState() => _StatusPillState();
}

class _StatusPillState extends State<_StatusPill> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.filled
        ? (_isPressed ? Color.lerp(widget.color, Colors.black, 0.15)! : widget.color)
        : widget.color.withValues(alpha: 0.1);

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _isPressed = true),
      onTapUp: widget.onTap == null ? null : (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: Container(
        width: 92,
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          widget.label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: widget.filled ? Colors.white : widget.color,
          ),
        ),
      ),
    );
  }
}