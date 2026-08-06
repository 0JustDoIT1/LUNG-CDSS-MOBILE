import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/auth_api.dart';
import '../../../core/api/medications_api.dart';
import '../../../core/auth/session_controller.dart';
import '../../../core/theme/app_theme.dart';

/// 복약스케줄 설정 (간호사용). POST /api/medications/schedules/ 연동.
/// times_per_day는 "HH:MM" 복용시각 목록, start_date/end_date 둘 다 필수.
/// 조회(GET) API가 아직 없어서, 등록 목록은 이번 세션에 저장한 것만 낙관적으로 표시.
class CarePlanMedicationScreen extends StatefulWidget {
  final String patientId;
  final String patientName;

  const CarePlanMedicationScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<CarePlanMedicationScreen> createState() => _CarePlanMedicationScreenState();
}

class _SavedSchedule {
  final String drugName;
  final String dosage;
  final List<TimeOfDay> times;
  final DateTime startDate;
  final DateTime endDate;

  const _SavedSchedule({
    required this.drugName,
    required this.dosage,
    required this.times,
    required this.startDate,
    required this.endDate,
  });

  String get summary => '$drugName · $dosage · 1일${times.length}회';
}

class _CarePlanMedicationScreenState extends State<CarePlanMedicationScreen> {
  final _drugNameController = TextEditingController();
  final _dosageController = TextEditingController();
  final List<TimeOfDay> _times = [];
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;

  final List<_SavedSchedule> _registered = [];
  bool _isSaving = false;

  @override
  void dispose() {
    _drugNameController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  Future<void> _addTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked == null) return;
    if (_times.any((t) => t.hour == picked.hour && t.minute == picked.minute)) return;
    setState(() {
      _times.add(picked);
      _times.sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
    });
  }

  void _removeTime(TimeOfDay time) {
    setState(() => _times.remove(time));
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked == null) return;
    setState(() {
      _startDate = picked;
      // 종료일이 시작일보다 빠르면 같이 밀어줌
      if (_endDate != null && _endDate!.isBefore(_startDate)) _endDate = _startDate;
    });
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

  String _dateLabel(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  String _timeLabel(TimeOfDay t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.hour)}:${two(t.minute)}';
  }

  Future<void> _saveSchedule() async {
    final drugName = _drugNameController.text.trim();
    final dosage = _dosageController.text.trim();
    final endDate = _endDate;

    if (drugName.isEmpty || dosage.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('약물명과 용량을 입력해주세요')),
      );
      return;
    }
    if (_times.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('복용 시간을 하나 이상 추가해주세요')),
      );
      return;
    }
    if (endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('종료일을 선택해주세요')),
      );
      return;
    }

    final token = context.read<SessionController>().accessToken;
    if (token == null) return;

    setState(() => _isSaving = true);

    try {
      await createMedicationSchedule(
        patientId: widget.patientId,
        drugName: drugName,
        dosage: dosage,
        times: _times.map(_timeLabel).toList(),
        startDate: _startDate,
        endDate: endDate,
        accessToken: token,
      );

      if (!mounted) return;
      setState(() {
        _registered.add(_SavedSchedule(
          drugName: drugName,
          dosage: dosage,
          times: List.of(_times),
          startDate: _startDate,
          endDate: endDate,
        ));
        _drugNameController.clear();
        _dosageController.clear();
        _times.clear();
        _startDate = DateTime.now();
        _endDate = null;
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('복약스케줄이 저장됐어요')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _removeEntry(_SavedSchedule entry) {
    setState(() => _registered.remove(entry));
  }

  @override
  Widget build(BuildContext context) {
    final labelColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(title: Text('${widget.patientName} · 복약스케줄')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('약물명', style: TextStyle(color: labelColor, fontSize: 13)),
          const SizedBox(height: 6),
          TextField(
            controller: _drugNameController,
            decoration: const InputDecoration(border: OutlineInputBorder(), hintText: '예: 살부타몰'),
          ),
          const SizedBox(height: 16),
          Text('용량', style: TextStyle(color: labelColor, fontSize: 13)),
          const SizedBox(height: 6),
          TextField(
            controller: _dosageController,
            decoration: const InputDecoration(border: OutlineInputBorder(), hintText: '예: 1정'),
          ),
          const SizedBox(height: 16),
          Text('복용 시간', style: TextStyle(color: labelColor, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._times.map((t) => Chip(
                    label: Text(_timeLabel(t)),
                    onDeleted: () => _removeTime(t),
                  )),
              ActionChip(
                onPressed: _addTime,
                avatar: const Icon(Icons.add, size: 16),
                label: const Text('시간 추가'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Theme.of(context).dividerColor),
                ),
                backgroundColor: Colors.transparent,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('시작일', style: TextStyle(color: labelColor, fontSize: 13)),
                    const SizedBox(height: 6),
                    OutlinedButton(onPressed: _pickStartDate, child: Text(_dateLabel(_startDate))),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('종료일', style: TextStyle(color: labelColor, fontSize: 13)),
                    const SizedBox(height: 6),
                    OutlinedButton(
                      onPressed: _pickEndDate,
                      child: Text(_endDate == null ? '선택' : _dateLabel(_endDate!)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 8),
          Text('이번 세션에 등록한 스케줄', style: TextStyle(color: labelColor, fontSize: 13)),
          const SizedBox(height: 8),
          if (_registered.isEmpty)
            const Text('등록된 스케줄이 없어요')
          else
            ..._registered.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(child: Text(e.summary)),
                      IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => _removeEntry(e)),
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
              onPressed: _isSaving ? null : _saveSchedule,
              child: _isSaving
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('저장'),
            ),
          ),
        ],
      ),
    );
  }
}
