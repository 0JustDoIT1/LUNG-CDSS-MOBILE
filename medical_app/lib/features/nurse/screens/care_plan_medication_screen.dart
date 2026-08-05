import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/auth_api.dart';
import '../../../core/api/medications_api.dart';
import '../../../core/auth/session_controller.dart';
import '../../../core/theme/app_theme.dart';

/// 복약스케줄 설정 (간호사용). POST /api/medications/schedules/ 연동.
/// API 스펙상 patient/drug_name/dosage/times_per_day/start_date만 지원 —
/// 기존 화면에 있던 구체 복용시간(times)·종료일(end_date) 입력은 API 미지원이라 제거.
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
  final int timesPerDay;
  final DateTime startDate;

  const _SavedSchedule({
    required this.drugName,
    required this.dosage,
    required this.timesPerDay,
    required this.startDate,
  });

  String get summary => '$drugName · $dosage · 1일$timesPerDay회';
}

class _CarePlanMedicationScreenState extends State<CarePlanMedicationScreen> {
  final _drugNameController = TextEditingController();
  final _dosageController = TextEditingController();
  int _timesPerDay = 1;
  DateTime _startDate = DateTime.now();

  final List<_SavedSchedule> _registered = [];
  bool _isSaving = false;

  @override
  void dispose() {
    _drugNameController.dispose();
    _dosageController.dispose();
    super.dispose();
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

  String _dateLabel(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  Future<void> _saveSchedule() async {
    final drugName = _drugNameController.text.trim();
    final dosage = _dosageController.text.trim();

    if (drugName.isEmpty || dosage.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('약물명과 용량을 입력해주세요')),
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
        timesPerDay: _timesPerDay,
        startDate: _startDate,
        accessToken: token,
      );

      if (!mounted) return;
      setState(() {
        _registered.add(_SavedSchedule(
          drugName: drugName,
          dosage: dosage,
          timesPerDay: _timesPerDay,
          startDate: _startDate,
        ));
        _drugNameController.clear();
        _dosageController.clear();
        _timesPerDay = 1;
        _startDate = DateTime.now();
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
    return Scaffold(
      appBar: AppBar(title: Text('${widget.patientName} · 복약스케줄')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('약물명', style: TextStyle(color: Colors.black54, fontSize: 13)),
          const SizedBox(height: 6),
          TextField(
            controller: _drugNameController,
            decoration: const InputDecoration(border: OutlineInputBorder(), hintText: '예: 살부타몰'),
          ),
          const SizedBox(height: 16),
          const Text('용량', style: TextStyle(color: Colors.black54, fontSize: 13)),
          const SizedBox(height: 6),
          TextField(
            controller: _dosageController,
            decoration: const InputDecoration(border: OutlineInputBorder(), hintText: '예: 1정'),
          ),
          const SizedBox(height: 16),
          const Text('1일 횟수', style: TextStyle(color: Colors.black54, fontSize: 13)),
          const SizedBox(height: 6),
          DropdownButtonFormField<int>(
            initialValue: _timesPerDay,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: [1, 2, 3, 4].map((n) => DropdownMenuItem(value: n, child: Text('$n회'))).toList(),
            onChanged: (v) => setState(() => _timesPerDay = v ?? 1),
          ),
          const SizedBox(height: 16),
          const Text('시작일', style: TextStyle(color: Colors.black54, fontSize: 13)),
          const SizedBox(height: 6),
          OutlinedButton(onPressed: _pickStartDate, child: Text(_dateLabel(_startDate))),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 8),
          const Text('이번 세션에 등록한 스케줄', style: TextStyle(color: Colors.black54, fontSize: 13)),
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