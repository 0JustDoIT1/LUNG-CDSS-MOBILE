import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/appointments_api.dart';
import '../../../core/api/auth_api.dart';
import '../../../core/auth/session_controller.dart';
import '../../../core/theme/app_theme.dart';

/// 휴진일정 등록.
/// - 단발 휴진: 날짜선택 + 사유입력 → POST /api/appointments/doctor/off-days/
/// - 정기 휴진(주간): 요일별 오전/오후 토글 → GET/PUT /api/appointments/doctor/weekly-schedule/
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
          unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
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
    final colorScheme = Theme.of(context).colorScheme;

    final Color bgColor = active
        ? (_isPressed ? AppTheme.seed.withValues(alpha: 0.85) : AppTheme.seed)
        : (_isPressed ? colorScheme.surfaceContainerHigh : colorScheme.surfaceContainerHighest);

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
            color: active ? Colors.white : colorScheme.onSurfaceVariant,
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
  bool _isSaving = false;
  final TextEditingController _reasonController = TextEditingController();

  List<DoctorOffDay> _offDays = [];
  bool _isLoadingList = true;
  String? _listErrorMessage;
  String? _deletingId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadList());
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadList() async {
    setState(() {
      _isLoadingList = true;
      _listErrorMessage = null;
    });
    final token = context.read<SessionController>().accessToken;
    if (token == null) return;

    try {
      final offDays = await fetchDoctorOffDays(token);
      offDays.sort((a, b) => a.date.compareTo(b.date));
      if (!mounted) return;
      setState(() {
        _offDays = offDays;
        _isLoadingList = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingList = false;
        _listErrorMessage = e.message;
      });
    }
  }

  Future<void> _deleteOffDay(DoctorOffDay offDay) async {
    final token = context.read<SessionController>().accessToken;
    if (token == null) return;

    setState(() => _deletingId = offDay.id);
    try {
      await deleteDoctorOffDay(offDay.id, token);
      if (!mounted) return;
      setState(() => _offDays.remove(offDay));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _deletingId = null);
    }
  }

  String _offDayLabel(DoctorOffDay offDay) {
    if (offDay.isMorningOff && offDay.isAfternoonOff) return '종일';
    if (offDay.isMorningOff) return '오전';
    if (offDay.isAfternoonOff) return '오후';
    return '';
  }

  String _offDayDateLabel(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)}';
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
      _selectedDate != null && (_offMorning || _offAfternoon) && !_isSaving;

  String get _timeRangeLabel {
    if (_offMorning && _offAfternoon) return '종일';
    if (_offMorning) return '오전';
    if (_offAfternoon) return '오후';
    return '';
  }

  Future<void> _submit() async {
    final date = _selectedDate;
    if (date == null) return;
    final token = context.read<SessionController>().accessToken;
    if (token == null) return;

    setState(() => _isSaving = true);
    try {
      await createDoctorOffDay(
        accessToken: token,
        date: date,
        isMorningOff: _offMorning,
        isAfternoonOff: _isSaturday ? false : _offAfternoon,
        reason: _reasonController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$_dateLabel ($_timeRangeLabel) 휴진 등록 완료')),
      );
      setState(() {
        _selectedDate = null;
        _offMorning = false;
        _offAfternoon = false;
        _reasonController.clear();
      });
      _loadList();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String get _dateLabel {
    final date = _selectedDate;
    if (date == null) return '날짜 선택';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
          Center(
            child: OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today, size: 18),
              label: Text(_dateLabel),
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
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
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
              onPressed: !_canSubmit ? null : _submit,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('등록'),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 8),
          const Text('등록된 단발 휴진', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (_isLoadingList)
            const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
          else if (_listErrorMessage != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_listErrorMessage!, style: TextStyle(color: colorScheme.onSurfaceVariant)),
                TextButton(onPressed: _loadList, child: const Text('다시 시도')),
              ],
            )
          else if (_offDays.isEmpty)
            Text('등록된 휴진일이 없어요', style: TextStyle(color: colorScheme.onSurfaceVariant))
          else
            ..._offDays.map((offDay) {
              final isDeleting = _deletingId == offDay.id;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(_offDayDateLabel(offDay.date), style: const TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(width: 6),
                              Text(
                                _offDayLabel(offDay),
                                style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                          if (offDay.reason.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              offDay.reason,
                              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (isDeleting)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => _deleteOffDay(offDay),
                      ),
                  ],
                ),
              );
            }),
      ],
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

  // 서버 day_of_week 코드. 일요일은 API에 없어 항상 휴진 고정 UI로만 표시.
  static const _dayCodes = {
    '월': 'mon', '화': 'tue', '수': 'wed', '목': 'thu', '금': 'fri', '토': 'sat',
  };

  // 요일별 [오전off, 오후off]
  final Map<String, List<bool>> _offMap = {
    for (final d in _weekdays) d: [false, false],
  };

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

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
      final slots = await fetchDoctorWeeklySchedule(token);
      if (!mounted) return;
      setState(() {
        for (final slot in slots) {
          final day = _dayCodes.entries
              .firstWhere((e) => e.value == slot.dayOfWeek, orElse: () => const MapEntry('', ''))
              .key;
          if (day.isEmpty) continue;
          final periodIndex = slot.period == 'am' ? 0 : 1;
          _offMap[day]![periodIndex] = !slot.available;
        }
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    final token = context.read<SessionController>().accessToken;
    if (token == null) return;

    setState(() => _isSaving = true);
    try {
      final slots = <WeeklyScheduleSlot>[
        for (final entry in _dayCodes.entries) ...[
          WeeklyScheduleSlot(
            dayOfWeek: entry.value,
            period: 'am',
            available: !_offMap[entry.key]![0],
          ),
          WeeklyScheduleSlot(
            dayOfWeek: entry.value,
            period: 'pm',
            // 토요일 오후는 진료가 없어 항상 휴진으로 고정.
            available: entry.key == '토' ? false : !_offMap[entry.key]![1],
          ),
        ],
      ];
      await updateDoctorWeeklySchedule(accessToken: token, slots: slots);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('정기 휴진 일정 저장 완료')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.gradientEnd,
            ),
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('저장'),
          ),
        ),
      ],
    );
  }
}