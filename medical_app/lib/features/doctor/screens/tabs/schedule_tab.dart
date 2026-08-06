import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/api/appointments_api.dart';
import '../../../../core/api/auth_api.dart';
import '../../../../core/auth/session_controller.dart';
import '../../../../core/lifecycle/app_resume_notifier.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../main.dart';
import '../../models/appointment.dart';
import '../doctor_off_day_screen.dart';
import '../patient_detail_screen.dart';

/// 탭 2: 진료스케줄 확인. 실제 API(GET /api/appointments/mine/) 연동됨.
/// - 캘린더뷰: 월간/주간 전환, 예약 있는 날짜 점표시
/// - 날짜 선택시 해당일 시간순 예약목록(환자명, 시간, 상태)
/// - 휴진일정 등록 버튼
/// - 포그라운드 푸시 수신 + 앱 재개(resume) 시 새로고침으로 자동 반영
class ScheduleTab extends StatefulWidget {
  const ScheduleTab({super.key});

  @override
  State<ScheduleTab> createState() => _ScheduleTabState();
}

enum _CalendarMode { month, week }

/// 특정 날짜의 휴진 여부. half는 오전/오후 중 한쪽만 휴진.
enum _OffStatus { none, half, full }

const _weekdayCodes = {
  DateTime.monday: 'mon',
  DateTime.tuesday: 'tue',
  DateTime.wednesday: 'wed',
  DateTime.thursday: 'thu',
  DateTime.friday: 'fri',
  DateTime.saturday: 'sat',
};

class _ScheduleTabState extends State<ScheduleTab> {
  _CalendarMode _mode = _CalendarMode.month;
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  // 주간뷰가 어느 주를 보여줄지 기준이 되는 날짜. 선택 해제해도 이 값은 유지됨.
  DateTime _anchorDate = DateTime.now();
  DateTime? _selectedDate = DateTime.now();

  List<Appointment> _appointments = [];
  List<WeeklyScheduleSlot> _weeklySchedule = [];
  List<DoctorOffDay> _offDays = [];
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

  /// 폴링/푸시 수신 시 배경에서 조용히 새로고침 — 실패해도 기존 상태 유지, 로딩/에러 화면 안 건드림.
  Future<void> _silentRefresh() async {
    final token = context.read<SessionController>().accessToken;
    if (token == null) return;

    try {
      final rawList = await fetchMyAppointmentsRaw(token);
      if (!mounted) return;
      setState(() => _appointments = rawList.map(Appointment.fromJson).toList());
    } on ApiException catch (_) {
      // 조용히 무시
    }

    try {
      final weekly = await fetchDoctorWeeklySchedule(token);
      final offDays = await fetchDoctorOffDays(token);
      if (!mounted) return;
      setState(() {
        _weeklySchedule = weekly;
        _offDays = offDays;
      });
    } on ApiException catch (_) {
      // 조용히 무시
    }
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final token = context.read<SessionController>().accessToken;
    if (token == null) return;

    try {
      final rawList = await fetchMyAppointmentsRaw(token);
      if (!mounted) return;
      setState(() {
        _appointments = rawList.map(Appointment.fromJson).toList();
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    }

    try {
      final weekly = await fetchDoctorWeeklySchedule(token);
      final offDays = await fetchDoctorOffDays(token);
      if (!mounted) return;
      setState(() {
        _weeklySchedule = weekly;
        _offDays = offDays;
      });
    } on ApiException catch (_) {
      // 휴진 정보 로드 실패는 조용히 무시 — 예약 목록 자체는 계속 보여줘야 함
    }
  }

  ({bool amOff, bool pmOff}) _offDetailsFor(DateTime day) {
    if (day.weekday == DateTime.sunday) return (amOff: true, pmOff: true);

    var amOff = false;
    var pmOff = false;

    final code = _weekdayCodes[day.weekday];
    if (code != null) {
      amOff = _weeklySchedule.any((s) => s.dayOfWeek == code && s.period == 'am' && !s.available);
      pmOff = _weeklySchedule.any((s) => s.dayOfWeek == code && s.period == 'pm' && !s.available);
    }

    for (final o in _offDays) {
      if (o.date.year == day.year && o.date.month == day.month && o.date.day == day.day) {
        amOff = amOff || o.isMorningOff;
        pmOff = pmOff || o.isAfternoonOff;
      }
    }

    return (amOff: amOff, pmOff: pmOff);
  }

  _OffStatus _offStatusFor(DateTime day) {
    final details = _offDetailsFor(day);
    if (details.amOff && details.pmOff) return _OffStatus.full;
    if (details.amOff || details.pmOff) return _OffStatus.half;
    return _OffStatus.none;
  }

  String? get _selectedDayOffLabel {
    final selected = _selectedDate;
    if (selected == null) return null;
    final details = _offDetailsFor(selected);
    if (details.amOff && details.pmOff) return '종일 휴진';
    if (details.amOff) return '오전 휴진';
    if (details.pmOff) return '오후 휴진';
    return null;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _hasAppointment(DateTime day) {
    return _appointments.any((a) =>
        a.dateTime.year == day.year &&
        a.dateTime.month == day.month &&
        a.dateTime.day == day.day);
  }

  List<Appointment> get _selectedDayAppointments {
    final selected = _selectedDate;
    if (selected == null) return const [];
    final list = _appointments.where((a) => _isSameDay(a.dateTime, selected)).toList();
    list.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return list;
  }

  void _changeMonth(int delta) {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + delta);
    });
  }

  /// 날짜를 탭했을 때 — 이미 선택된 날짜를 다시 탭하면 선택 해제.
  void _onSelectDate(DateTime date) {
    setState(() {
      _anchorDate = date; // 주간뷰는 선택 해제해도 이 날짜가 속한 주를 계속 보여줌
      if (_selectedDate != null && _isSameDay(_selectedDate!, date)) {
        _selectedDate = null;
      } else {
        _selectedDate = date;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: _CalendarModeToggle(
                    selected: _mode,
                    onChanged: (m) => setState(() => _mode = m),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(onPressed: _load, icon: const Icon(Icons.refresh, size: 20)),
                TextButton.icon(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DoctorOffDayScreen()),
                    );
                    _load(); // 휴진 등록/취소하고 돌아왔을 수 있으니 새로고침
                  },
                  icon: const Icon(Icons.event_busy, size: 18),
                  label: const Text('휴진등록'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (_mode == _CalendarMode.month) _MonthGrid(
            focusedMonth: _focusedMonth,
            selectedDate: _selectedDate,
            hasAppointment: _hasAppointment,
            offStatusFor: _offStatusFor,
            onMonthChange: _changeMonth,
            onSelectDate: _onSelectDate,
          ) else _WeekRow(
            anchorDate: _anchorDate,
            selectedDate: _selectedDate,
            hasAppointment: _hasAppointment,
            offStatusFor: _offStatusFor,
            onSelectDate: _onSelectDate,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                _LegendDot(color: Colors.blue, label: '예약 있음'),
                const SizedBox(width: 16),
                _LegendDot(color: Colors.orange, label: '휴진'),
              ],
            ),
          ),
          const Divider(height: 24),
          if (_selectedDayOffLabel != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.event_busy, size: 16, color: Colors.orange.shade700),
                    const SizedBox(width: 6),
                    Text(
                      _selectedDayOffLabel!,
                      style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildList() {
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
    if (_selectedDate == null) {
      return const Center(child: Text('날짜를 선택해주세요'));
    }
    if (_selectedDayAppointments.isEmpty) {
      return const Center(child: Text('이 날짜엔 예약이 없어요'));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _selectedDayAppointments.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final a = _selectedDayAppointments[index];
        return _AppointmentTile(appointment: a);
      },
    );
  }
}

class _CalendarModeToggle extends StatelessWidget {
  final _CalendarMode selected;
  final ValueChanged<_CalendarMode> onChanged;

  const _CalendarModeToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(child: _pill(context, '월간', _CalendarMode.month)),
          Expanded(child: _pill(context, '주간', _CalendarMode.week)),
        ],
      ),
    );
  }

  Widget _pill(BuildContext context, String label, _CalendarMode mode) {
    final isSelected = selected == mode;
    return GestureDetector(
      onTap: () => onChanged(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.gradientEnd : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime? selectedDate;
  final bool Function(DateTime) hasAppointment;
  final _OffStatus Function(DateTime) offStatusFor;
  final void Function(int delta) onMonthChange;
  final void Function(DateTime) onSelectDate;

  const _MonthGrid({
    required this.focusedMonth,
    required this.selectedDate,
    required this.hasAppointment,
    required this.offStatusFor,
    required this.onMonthChange,
    required this.onSelectDate,
  });

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final daysInMonth = DateTime(focusedMonth.year, focusedMonth.month + 1, 0).day;
    final leadingBlanks = firstDayOfMonth.weekday % 7;

    final cells = <Widget>[];
    for (int i = 0; i < leadingBlanks; i++) {
      cells.add(const SizedBox());
    }
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(focusedMonth.year, focusedMonth.month, day);
      final selected = selectedDate;
      final isSelected = selected != null &&
          date.year == selected.year &&
          date.month == selected.month &&
          date.day == selected.day;
      final today = DateTime.now();
      final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
      final isPast = date.isBefore(DateTime(today.year, today.month, today.day));
      final isSunday = date.weekday == DateTime.sunday;
      cells.add(_DayCell(
        day: day,
        isSelected: isSelected,
        isToday: isToday,
        hasDot: hasAppointment(date),
        offStatus: offStatusFor(date),
        isPast: isPast || isSunday,
        onTap: () => onSelectDate(date),
      ));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => onMonthChange(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                '${focusedMonth.year}년 ${focusedMonth.month}월',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              IconButton(
                onPressed: () => onMonthChange(1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const Row(
            children: [
              _WeekdayLabel('일'), _WeekdayLabel('월'), _WeekdayLabel('화'),
              _WeekdayLabel('수'), _WeekdayLabel('목'), _WeekdayLabel('금'),
              _WeekdayLabel('토'),
            ],
          ),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: cells,
          ),
        ],
      ),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  final String text;
  const _WeekdayLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          text,
          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool isSelected;
  final bool isToday;
  final bool hasDot;
  final _OffStatus offStatus;
  final bool isPast;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.isSelected,
    required this.isToday,
    required this.hasDot,
    required this.offStatus,
    required this.isPast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isFullOff = offStatus == _OffStatus.full;
    final isHalfOff = offStatus == _OffStatus.half;

    final Color cellColor;
    if (isSelected) {
      cellColor = colorScheme.onSurface;
    } else if (isFullOff) {
      cellColor = Colors.orange.withValues(alpha: isPast ? 0.08 : 0.18);
    } else {
      cellColor = Colors.transparent;
    }

    final Color textColor;
    if (isPast) {
      textColor = colorScheme.onSurface.withValues(alpha: 0.38);
    } else if (isSelected) {
      textColor = colorScheme.surface;
    } else if (isToday) {
      textColor = AppTheme.gradientEnd;
    } else if (isFullOff) {
      textColor = Colors.orange.shade800;
    } else {
      textColor = colorScheme.onSurface;
    }

    return GestureDetector(
      onTap: isPast ? null : onTap,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: cellColor,
          shape: BoxShape.circle,
          border: (isToday && !isSelected) ? Border.all(color: AppTheme.gradientEnd, width: 1.5) : null,
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                color: textColor,
                fontWeight: (isSelected || isToday) ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (hasDot || isHalfOff)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasDot) ...[
                      _dot(isPast || isSelected ? textColor : Colors.blue),
                      if (isHalfOff) const SizedBox(width: 2),
                    ],
                    if (isHalfOff) _dot(isPast || isSelected ? textColor : Colors.orange),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _dot(Color color) {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _WeekRow extends StatelessWidget {
  final DateTime anchorDate;
  final DateTime? selectedDate;
  final bool Function(DateTime) hasAppointment;
  final _OffStatus Function(DateTime) offStatusFor;
  final void Function(DateTime) onSelectDate;

  const _WeekRow({
    required this.anchorDate,
    required this.selectedDate,
    required this.hasAppointment,
    required this.offStatusFor,
    required this.onSelectDate,
  });

  @override
  Widget build(BuildContext context) {
    final startOfWeek =
        anchorDate.subtract(Duration(days: anchorDate.weekday % 7));
    final days = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));
    const labels = ['일', '월', '화', '수', '목', '금', '토'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(7, (i) {
          final date = days[i];
          final selected = selectedDate;
          final isSelected = selected != null &&
              date.year == selected.year &&
              date.month == selected.month &&
              date.day == selected.day;
          final today = DateTime.now();
          final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
          final isPast = date.isBefore(DateTime(today.year, today.month, today.day));
          final isSunday = date.weekday == DateTime.sunday;
          return Expanded(
            child: Column(
              children: [
                Text(
                  labels[i],
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                _DayCell(
                  day: date.day,
                  isSelected: isSelected,
                  isToday: isToday,
                  hasDot: hasAppointment(date),
                  offStatus: offStatusFor(date),
                  isPast: isPast || isSunday,
                  onTap: () => onSelectDate(date),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _AppointmentTile extends StatelessWidget {
  final Appointment appointment;

  const _AppointmentTile({required this.appointment});

  @override
  Widget build(BuildContext context) {
    String two(int n) => n.toString().padLeft(2, '0');
    final time =
        '${two(appointment.dateTime.hour)}:${two(appointment.dateTime.minute)}';

    final Color statusColor = switch (appointment.status) {
      AppointmentStatus.checkedIn => Colors.green,
      AppointmentStatus.completed => Colors.green,
      AppointmentStatus.noShow => Colors.red,
      AppointmentStatus.cancelled => Colors.grey,
      _ => Colors.blue,
    };

    return Card(
      child: ListTile(
        leading: Text(time, style: const TextStyle(fontWeight: FontWeight.w600)),
        title: Text(appointment.patientName),
        trailing: Chip(
          label: Text(appointment.status.label),
          backgroundColor: statusColor.withValues(alpha: 0.15),
          labelStyle: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
          side: BorderSide.none,
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PatientDetailScreen(patientName: appointment.patientName),
            ),
          );
        },
      ),
    );
  }
}