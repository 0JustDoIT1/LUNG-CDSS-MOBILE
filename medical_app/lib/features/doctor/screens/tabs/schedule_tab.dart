import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/api/appointments_api.dart';
import '../../../../core/api/auth_api.dart';
import '../../../../core/auth/session_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../models/appointment.dart';
import '../doctor_off_day_screen.dart';
import '../patient_detail_screen.dart';

/// 탭 2: 진료스케줄 확인. 실제 API(GET /api/appointments/mine/) 연동됨.
/// - 캘린더뷰: 월간/주간 전환, 예약 있는 날짜 점표시
/// - 날짜 선택시 해당일 시간순 예약목록(환자명, 시간, 상태)
/// - 휴진일정 등록 버튼
class ScheduleTab extends StatefulWidget {
  const ScheduleTab({super.key});

  @override
  State<ScheduleTab> createState() => _ScheduleTabState();
}

enum _CalendarMode { month, week }

class _ScheduleTabState extends State<ScheduleTab> {
  _CalendarMode _mode = _CalendarMode.month;
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDate = DateTime.now();

  List<Appointment> _appointments = [];
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
  }

  bool _hasAppointment(DateTime day) {
    return _appointments.any((a) =>
        a.dateTime.year == day.year &&
        a.dateTime.month == day.month &&
        a.dateTime.day == day.day);
  }

  List<Appointment> get _selectedDayAppointments {
    final list = _appointments
        .where((a) =>
            a.dateTime.year == _selectedDate.year &&
            a.dateTime.month == _selectedDate.month &&
            a.dateTime.day == _selectedDate.day)
        .toList();
    list.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return list;
  }

  void _changeMonth(int delta) {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + delta);
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
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DoctorOffDayScreen()),
                    );
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
            onMonthChange: _changeMonth,
            onSelectDate: (d) => setState(() => _selectedDate = d),
          ) else _WeekRow(
            selectedDate: _selectedDate,
            hasAppointment: _hasAppointment,
            onSelectDate: (d) => setState(() => _selectedDate = d),
          ),
          const Divider(height: 24),
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
            Text(_errorMessage!, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            TextButton(onPressed: _load, child: const Text('다시 시도')),
          ],
        ),
      );
    }
    if (_selectedDayAppointments.isEmpty) {
      return const Center(child: Text('이 날짜엔 예약이 없어요'));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _selectedDayAppointments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
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
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(child: _pill('월간', _CalendarMode.month)),
          Expanded(child: _pill('주간', _CalendarMode.week)),
        ],
      ),
    );
  }

  Widget _pill(String label, _CalendarMode mode) {
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
            color: isSelected ? Colors.white : Colors.grey.shade600,
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
  final DateTime selectedDate;
  final bool Function(DateTime) hasAppointment;
  final void Function(int delta) onMonthChange;
  final void Function(DateTime) onSelectDate;

  const _MonthGrid({
    required this.focusedMonth,
    required this.selectedDate,
    required this.hasAppointment,
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
      final isSelected = date.year == selectedDate.year &&
          date.month == selectedDate.month &&
          date.day == selectedDate.day;
      final today = DateTime.now();
      final isPast = date.isBefore(DateTime(today.year, today.month, today.day));
      final isSunday = date.weekday == DateTime.sunday;
      cells.add(_DayCell(
        day: day,
        isSelected: isSelected,
        hasDot: hasAppointment(date),
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
        child: Text(text, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool isSelected;
  final bool hasDot;
  final bool isPast;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.isSelected,
    required this.hasDot,
    required this.isPast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isPast ? null : onTap,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.transparent,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                color: isPast
                    ? Colors.black26
                    : (isSelected ? Colors.white : Colors.black87),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (hasDot)
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: isPast
                      ? Colors.black26
                      : (isSelected ? Colors.white : Colors.blue),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WeekRow extends StatelessWidget {
  final DateTime selectedDate;
  final bool Function(DateTime) hasAppointment;
  final void Function(DateTime) onSelectDate;

  const _WeekRow({
    required this.selectedDate,
    required this.hasAppointment,
    required this.onSelectDate,
  });

  @override
  Widget build(BuildContext context) {
    final startOfWeek =
        selectedDate.subtract(Duration(days: selectedDate.weekday % 7));
    final days = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));
    const labels = ['일', '월', '화', '수', '목', '금', '토'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(7, (i) {
          final date = days[i];
          final isSelected = date.year == selectedDate.year &&
              date.month == selectedDate.month &&
              date.day == selectedDate.day;
          final today = DateTime.now();
          final isPast = date.isBefore(DateTime(today.year, today.month, today.day));
          final isSunday = date.weekday == DateTime.sunday;
          return Expanded(
            child: Column(
              children: [
                Text(labels[i], style: const TextStyle(fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 4),
                _DayCell(
                  day: date.day,
                  isSelected: isSelected,
                  hasDot: hasAppointment(date),
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