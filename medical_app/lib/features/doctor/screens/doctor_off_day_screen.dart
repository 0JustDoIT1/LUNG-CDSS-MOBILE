import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// 휴진일정 등록.
/// - 단발 휴진: 날짜선택 + 사유입력 → DoctorOffDay
/// - 정기 휴진(주간): 요일별 오전/오후 토글 → DoctorWeeklySchedule
///
/// TODO: 실제 저장은 API 붙을 때 연결. 지금은 스낵바로 결과만 확인.
class DoctorOffDayScreen extends StatefulWidget {
  const DoctorOffDayScreen({super.key});

  @override
  State<DoctorOffDayScreen> createState() => _DoctorOffDayScreenState();
}

class _DoctorOffDayScreenState extends State<DoctorOffDayScreen>
    with SingleTickerProviderStateMixin {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('휴진일정 등록'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.gradientEnd,
          unselectedLabelColor: Colors.grey.shade500,
          indicatorColor: AppTheme.gradientEnd,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: '단발 휴진'),
            Tab(text: '정기 휴진(주간)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _SingleOffDayForm(),
          _WeeklyOffScheduleForm(),
        ],
      ),
    );
  }
}

/// 선택 시 채워지는 토글 칩. 마우스 올리면 살짝 떠오르는 호버 효과.
class _OffChip extends StatefulWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final ValueChanged<bool>? onChanged;

  const _OffChip({
    required this.label,
    required this.selected,
    this.enabled = true,
    this.onChanged,
  });

  @override
  State<_OffChip> createState() => _OffChipState();
}

class _OffChipState extends State<_OffChip> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.selected && widget.enabled;

    final Color bgColor = active
        ? (_isPressed ? AppTheme.seed.withValues(alpha: 0.85) : AppTheme.seed)
        : (_isPressed ? Colors.grey.shade200 : Colors.grey.shade100);

    return GestureDetector(
      onTap: widget.enabled ? () => widget.onChanged?.call(!widget.selected) : null,
      onTapDown: widget.enabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.enabled ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          widget.label,
          style: TextStyle(
            color: active ? Colors.white : Colors.grey.shade500,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _SingleOffDayForm extends StatefulWidget {
  const _SingleOffDayForm();

  @override
  State<_SingleOffDayForm> createState() => _SingleOffDayFormState();
}

class _SingleOffDayFormState extends State<_SingleOffDayForm> {
  DateTime? _selectedDate;
  bool _offMorning = false;
  bool _offAfternoon = false;
  final TextEditingController _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  bool get _isSaturday => _selectedDate?.weekday == DateTime.saturday;

  Future<void> _pickDate() async {
    // 오늘이 일요일이면 초기 날짜로 못 쓰니, 선택 가능한 가장 가까운 날짜로 보정.
    var initial = DateTime.now();
    if (initial.weekday == DateTime.sunday) {
      initial = initial.add(const Duration(days: 1));
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      // 일요일은 애초에 휴진일이라 날짜 선택 자체를 막음
      selectableDayPredicate: (date) => date.weekday != DateTime.sunday,
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        // 토요일은 오후 진료가 없으니 오후 선택은 자동 해제
        if (picked.weekday == DateTime.saturday) _offAfternoon = false;
      });
    }
  }

  bool get _canSubmit =>
      _selectedDate != null && (_offMorning || _offAfternoon);

  String get _timeRangeLabel {
    if (_offMorning && _offAfternoon) return '종일';
    if (_offMorning) return '오전';
    if (_offAfternoon) return '오후';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    String two(int n) => n.toString().padLeft(2, '0');
    final dateLabel = _selectedDate == null
        ? '날짜 선택'
        : '${_selectedDate!.year}-${two(_selectedDate!.month)}-${two(_selectedDate!.day)}';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today, size: 18),
              label: Text(dateLabel),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.gradientEnd,
                side: BorderSide(color: AppTheme.gradientEnd),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('휴진 시간대', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _OffChip(
                  label: '오전 휴진',
                  selected: _offMorning,
                  onChanged: (v) => setState(() => _offMorning = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _OffChip(
                  label: '오후 휴진',
                  selected: _isSaturday ? false : _offAfternoon,
                  enabled: !_isSaturday,
                  onChanged: (v) => setState(() => _offAfternoon = v),
                ),
              ),
            ],
          ),
          if (_isSaturday) ...[
            const SizedBox(height: 4),
            Text(
              '※ 토요일은 오후 진료가 없어 선택할 수 없어요.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
          const SizedBox(height: 16),
          const Text('사유', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _reasonController,
            maxLines: 3,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '휴진 사유를 입력하세요',
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.gradientEnd,
              ),
              onPressed: !_canSubmit
                  ? null
                  : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$dateLabel ($_timeRangeLabel) 휴진 등록 완료'),
                        ),
                      );
                      // TODO: DoctorOffDay 저장 API 연결 (date, morning, afternoon, reason)
                    },
              child: const Text('등록'),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyOffScheduleForm extends StatefulWidget {
  const _WeeklyOffScheduleForm();

  @override
  State<_WeeklyOffScheduleForm> createState() => _WeeklyOffScheduleFormState();
}

class _WeeklyOffScheduleFormState extends State<_WeeklyOffScheduleForm> {
  static const _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

  // 요일별 [오전off, 오후off]
  final Map<String, List<bool>> _offMap = {
    for (final d in _weekdays) d: [false, false],
  };

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final day in _weekdays)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(width: 32, child: Text(day, style: const TextStyle(fontWeight: FontWeight.w600))),
                const SizedBox(width: 8),
                Expanded(
                  child: _OffChip(
                    label: '오전 휴진',
                    selected: day == '일' ? true : _offMap[day]![0],
                    enabled: day != '일',
                    onChanged: (v) => setState(() => _offMap[day]![0] = v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _OffChip(
                    label: '오후 휴진',
                    // 일요일은 휴진, 토요일은 오후 진료 없음 → 둘 다 선택 고정 + 비활성화
                    selected: (day == '일' || day == '토') ? true : _offMap[day]![1],
                    enabled: day != '일' && day != '토',
                    onChanged: (v) => setState(() => _offMap[day]![1] = v),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Text(
          '※ 일요일은 휴진, 토요일 오후는 진료하지 않아 선택할 수 없어요.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.gradientEnd,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('정기 휴진 일정 저장 완료')),
              );
              // TODO: DoctorWeeklySchedule 저장 API 연결
            },
            child: const Text('저장'),
          ),
        ),
      ],
    );
  }
}