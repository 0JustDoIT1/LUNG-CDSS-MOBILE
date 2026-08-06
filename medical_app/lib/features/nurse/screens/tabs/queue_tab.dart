import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/api/appointments_api.dart';
import '../../../../core/api/auth_api.dart';
import '../../../../core/auth/session_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../models/reservation.dart';

/// 탭 1: 예약요청 큐 관리 + 진료관리(방문/미방문 처리).
/// 실제 API(GET .../queue/, .../today-visits/, POST .../process/ 등) 연동됨.
class QueueTab extends StatefulWidget {
  const QueueTab({super.key});

  @override
  State<QueueTab> createState() => _QueueTabState();
}

class _QueueTabState extends State<QueueTab> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: AppTheme.gradientEnd,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
          indicatorColor: AppTheme.gradientEnd,
          tabs: const [
            Tab(text: '예약요청'),
            Tab(text: '진료관리'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _RequestQueueView(),
              _TodayVisitsView(),
            ],
          ),
        ),
      ],
    );
  }
}

/// 예약요청 탭 — status=requested인 예약들, 승인/반려.
class _RequestQueueView extends StatefulWidget {
  const _RequestQueueView();

  @override
  State<_RequestQueueView> createState() => _RequestQueueViewState();
}

class _RequestQueueViewState extends State<_RequestQueueView> {
  List<Appointment>? _appointments;
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
      final list = await fetchAppointmentQueue(token);
      if (!mounted) return;
      setState(() {
        _appointments = list;
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

  Future<void> _approve(Appointment a) async {
    final token = context.read<SessionController>().accessToken;
    if (token == null) return;
    try {
      await approveAppointment(a.id, token);
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _reject(Appointment a) async {
    final token = context.read<SessionController>().accessToken;
    if (token == null) return;
    try {
      await cancelAppointment(a.id, token);
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  String _fmtDate(DateTime d) => '${d.month}월 ${d.day}일';

  String _fmtTime(DateTime d) {
    final isAm = d.hour < 12;
    final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final minute = d.minute.toString().padLeft(2, '0');
    return '${isAm ? '오전' : '오후'} $hour12:$minute';
  }

  String _fmtRequestedAt(DateTime d) => '${_fmtDate(d)} ${_fmtTime(d)}';

  @override
  Widget build(BuildContext context) {
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

    final requests = _appointments ?? [];
    if (requests.isEmpty) {
      return const Center(child: Text('대기 중인 예약요청이 없어요'));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final r = requests[index];
          final colorScheme = Theme.of(context).colorScheme;
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(r.patientName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(width: 8),
                    Text(
                      '신청 ${_fmtRequestedAt(r.createdAt)}',
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${r.department} · ${r.doctorName}',
                  style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                Text(
                  '예약 일정',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_fmtDate(r.requestedAtSlot)} ${_fmtTime(r.requestedAtSlot)}',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        label: '승인',
                        color: Colors.lightGreen.shade700,
                        onTap: () => _approve(r),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ActionButton(
                        label: '반려',
                        color: Colors.red.shade600,
                        onTap: () => _reject(r),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// 진료관리 탭 — 오늘 예약들, 방문처리/미방문처리.
class _TodayVisitsView extends StatefulWidget {
  const _TodayVisitsView();

  @override
  State<_TodayVisitsView> createState() => _TodayVisitsViewState();
}

class _TodayVisitsViewState extends State<_TodayVisitsView> {
  List<Appointment>? _appointments;
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
      final list = await fetchTodayVisits(token);
      if (!mounted) return;
      setState(() {
        _appointments = list;
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

  Future<void> _checkIn(Appointment a) async {
    final token = context.read<SessionController>().accessToken;
    if (token == null) return;
    try {
      await checkInAppointment(a.id, token);
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _noShow(Appointment a) async {
    final token = context.read<SessionController>().accessToken;
    if (token == null) return;
    try {
      await markNoShow(a.id, token);
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
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

    final List<Appointment> all = List<Appointment>.of(_appointments ?? <Appointment>[])
      ..sort((a, b) => a.displaySlot.compareTo(b.displaySlot));

    final List<Appointment> pending = all
        .where((a) => a.status == AppointmentStatus.confirmed ||
            a.status == AppointmentStatus.remindedD7 ||
            a.status == AppointmentStatus.remindedD1)
        .toList();
    final List<Appointment> done = all.where((a) => !pending.contains(a)).toList();

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            labelColor: AppTheme.gradientEnd,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
            indicatorColor: AppTheme.gradientEnd,
            tabs: [
              Tab(text: '대기중 (${pending.length})'),
              Tab(text: '처리완료 (${done.length})'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _AppointmentList(
                  appointments: pending,
                  onCheckIn: _checkIn,
                  onNoShow: _noShow,
                  emptyText: '대기 중인 환자가 없어요',
                ),
                _AppointmentList(
                  appointments: done,
                  onCheckIn: _checkIn,
                  onNoShow: _noShow,
                  emptyText: '처리완료된 환자가 없어요',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentList extends StatelessWidget {
  final List<Appointment> appointments;
  final void Function(Appointment) onCheckIn;
  final void Function(Appointment) onNoShow;
  final String emptyText;

  const _AppointmentList({
    required this.appointments,
    required this.onCheckIn,
    required this.onNoShow,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    if (appointments.isEmpty) {
      return Center(
        child: Text(emptyText, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: appointments.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return _AppointmentRow(
          appointment: appointments[index],
          onCheckIn: onCheckIn,
          onNoShow: onNoShow,
        );
      },
    );
  }
}

class _AppointmentRow extends StatelessWidget {
  final Appointment appointment;
  final void Function(Appointment) onCheckIn;
  final void Function(Appointment) onNoShow;

  const _AppointmentRow({
    required this.appointment,
    required this.onCheckIn,
    required this.onNoShow,
  });

  @override
  Widget build(BuildContext context) {
    String two(int n) => n.toString().padLeft(2, '0');
    final slot = appointment.displaySlot;
    final time = '${two(slot.hour)}:${two(slot.minute)}';
    final isPending = appointment.status == AppointmentStatus.confirmed ||
        appointment.status == AppointmentStatus.remindedD7 ||
        appointment.status == AppointmentStatus.remindedD1;

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(appointment.patientName, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(time, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          if (isPending)
            _StatusPill(
              label: '방문처리',
              color: Colors.lightBlue.shade700,
              filled: true,
              onTap: () => onCheckIn(appointment),
            )
          else if (appointment.status == AppointmentStatus.checkedIn ||
              appointment.status == AppointmentStatus.completed)
            _StatusPill(label: '방문완료', color: Colors.green.shade700, filled: false, onTap: null)
          else if (appointment.status == AppointmentStatus.noShow)
            _StatusPill(label: '미방문', color: Colors.red.shade700, filled: false, onTap: null)
          else
            _StatusPill(label: '취소됨', color: colorScheme.onSurfaceVariant, filled: false, onTap: null),
          if (isPending) ...[
            const SizedBox(width: 6),
            _StatusPill(
              label: '미방문처리',
              color: Colors.red.shade600,
              filled: true,
              onTap: () => onNoShow(appointment),
            ),
          ],
        ],
      ),
    );
  }
}

/// 진료관리 리스트의 상태 뱃지/버튼 — 크기를 통일해서 보여줌.
class _StatusPill extends StatefulWidget {
  final String label;
  final Color color;
  final bool filled;
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
        width: 88,
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          widget.label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: widget.filled ? Colors.white : widget.color,
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.label, required this.color, required this.onTap});

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