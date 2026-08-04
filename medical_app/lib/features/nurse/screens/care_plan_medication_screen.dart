import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../mock/medication_schedule_mock.dart';
import '../models/medication_schedule.dart';

/// 복약스케줄 설정.
/// - 복용주기(1일 N회) → 시간대 수동 지정
/// - 기간: 시작일/종료일
/// - 저장 시: MedicationSchedule 생성 → 환자 앱 "오늘의 복약"에 즉시 반영
///
/// TODO: 실제 저장은 API 붙을 때 연결. 지금은 화면 안 mock 리스트에만 추가.
class CarePlanMedicationScreen extends StatefulWidget {
  final String patientName;

  const CarePlanMedicationScreen({super.key, required this.patientName});

  @override
  State<CarePlanMedicationScreen> createState() =>
      _CarePlanMedicationScreenState();
}

class _CarePlanMedicationScreenState extends State<CarePlanMedicationScreen> {
  int _timesPerDay = 1;
  final List<TimeOfDay> _times = [const TimeOfDay(hour: 9, minute: 0)];
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;

  late final List<MedicationEntry> _registered = mockMedicationEntries();

  Future<void> _addTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked != null) setState(() => _times.add(picked));
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  String _dateLabel(DateTime? d) {
    if (d == null) return '미정';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  String _timeLabel(TimeOfDay t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.hour)}:${two(t.minute)}';
  }

  void _saveSchedule() {
    setState(() {
      _registered.add(MedicationEntry(
        timesPerDay: _timesPerDay,
        times: List.of(_times),
        startDate: _startDate,
        endDate: _endDate,
      ));
      _timesPerDay = 1;
      _times
        ..clear()
        ..add(const TimeOfDay(hour: 9, minute: 0));
      _endDate = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('복약스케줄이 저장됐어요')),
    );
    // TODO: MedicationSchedule 생성 API 연결
  }

  void _removeEntry(MedicationEntry entry) {
    setState(() => _registered.remove(entry));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.patientName} · 복약스케줄')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('1일 횟수', style: TextStyle(color: Colors.black54, fontSize: 13)),
          const SizedBox(height: 6),
          DropdownButtonFormField<int>(
            initialValue: _timesPerDay,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: [1, 2, 3, 4]
                .map((n) => DropdownMenuItem(value: n, child: Text('$n회')))
                .toList(),
            onChanged: (v) => setState(() => _timesPerDay = v ?? 1),
          ),
          const SizedBox(height: 16),
          const Text('복용시간', style: TextStyle(color: Colors.black54, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in _times)
                Chip(
                  label: Text(_timeLabel(t)),
                  onDeleted: _times.length > 1
                      ? () => setState(() => _times.remove(t))
                      : null,
                ),
              ActionChip(
                onPressed: _addTime,
                avatar: const Icon(Icons.add, size: 16),
                label: const Text('추가'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade400),
                ),
                backgroundColor: Colors.transparent,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('시작일', style: TextStyle(color: Colors.black54, fontSize: 13)),
                    const SizedBox(height: 6),
                    OutlinedButton(
                      onPressed: _pickStartDate,
                      child: Text(_dateLabel(_startDate)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('종료일', style: TextStyle(color: Colors.black54, fontSize: 13)),
                    const SizedBox(height: 6),
                    OutlinedButton(
                      onPressed: _pickEndDate,
                      child: Text(_dateLabel(_endDate)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 8),
          const Text('등록된 스케줄', style: TextStyle(color: Colors.black54, fontSize: 13)),
          const SizedBox(height: 8),
          if (_registered.isEmpty)
            const Text('등록된 스케줄이 없어요')
          else
            ..._registered.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(child: Text(e.summary)),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => _removeEntry(e),
                      ),
                    ],
                  ),
                )),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.gradientEnd,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _saveSchedule,
              child: const Text('저장'),
            ),
          ),
        ],
      ),
    );
  }
}