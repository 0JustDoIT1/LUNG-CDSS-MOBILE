import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/api/auth_api.dart';
import '../../../../core/api/symptoms_api.dart';
import '../../../../core/auth/session_controller.dart';
import '../../mock/patient_overview_mock.dart';
import '../../models/patient_overview.dart';
import '../../models/staff_patient.dart';
import '../nurse_patient_detail_screen.dart';
import '../symptom_checks_screen.dart';

/// 탭 2: 담당환자 목록.
/// 환자 명단은 실제 API(GET /api/auth/staff/patients/) 기반.
/// "확인필요" 표시는 증상위험도 API(GET /api/symptoms/checks/nurse-visible/) 기반.
/// 복약현황(오늘 복약 X/N)은 조회 API 미확정이라 아직 mock 유지.
class NursePatientsTab extends StatefulWidget {
  const NursePatientsTab({super.key});

  @override
  State<NursePatientsTab> createState() => _NursePatientsTabState();
}

class _NursePatientsTabState extends State<NursePatientsTab> {
  List<StaffPatient> _patients = [];
  List<SymptomCheck> _riskChecks = [];
  bool _isLoading = true;
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
      final patients = await fetchStaffPatients(token);
      if (!mounted) return;
      setState(() => _patients = patients);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    }

    try {
      final checks = await fetchNurseVisibleSymptomChecks(token);
      if (!mounted) return;
      setState(() => _riskChecks = checks);
    } on ApiException catch (_) {
      // 위험도 정보 로드 실패는 조용히 무시 (목록 자체는 계속 보여줘야 하니까)
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  bool _needsAttention(String name) =>
      _riskChecks.any((c) => c.patientName == name && !c.nurseReviewed);

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
            Text(_errorMessage!, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            TextButton(onPressed: _load, child: const Text('다시 시도')),
          ],
        ),
      );
    }

    final unreadRiskCount = _riskChecks.where((c) => !c.nurseReviewed).length;

    return RefreshIndicator(
      onRefresh: _load,
      child: SafeArea(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              '담당환자 목록',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '호흡기내과 · ${_patients.length}명',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            if (unreadRiskCount > 0)
              GestureDetector(
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SymptomChecksScreen()),
                  );
                  _load();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.priority_high, color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '증상 위험 신호 $unreadRiskCount건 — 확인이 필요해요',
                          style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Colors.red.shade700, size: 18),
                    ],
                  ),
                ),
              ),
            ..._patients.map((p) {
              final overview = mockNursePatientOverview(p.name);
              final displayOverview = NursePatientOverview(
                name: overview.name,
                needsAttention: _needsAttention(p.name),
                todayDoses: overview.todayDoses,
              );
              return _PatientCard(patient: displayOverview, patientId: p.id);
            }),
          ],
        ),
      ),
    );
  }
}

class _PatientCard extends StatefulWidget {
  final NursePatientOverview patient;
  final String patientId;

  const _PatientCard({required this.patient, required this.patientId});

  @override
  State<_PatientCard> createState() => _PatientCardState();
}

class _PatientCardState extends State<_PatientCard> {
  bool _isPressed = false;

  Color get _subtitleColor {
    final p = widget.patient;
    if (!p.hasSchedule) return Colors.grey.shade400;
    if (p.takenCount == p.totalCount) return Colors.lightBlue.shade400;
    return Colors.orange.shade700;
  }

  @override
  Widget build(BuildContext context) {
    final patient = widget.patient;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => NursePatientDetailScreen(
              patientId: widget.patientId,
              patientName: patient.name,
            ),
          ),
        );
      },
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _isPressed ? Colors.grey.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: patient.needsAttention
                  ? Colors.orange.shade50
                  : (patient.hasSchedule && patient.takenCount == patient.totalCount)
                      ? Colors.lightBlue.shade50
                      : Colors.grey.shade200,
              child: Text(
                patient.name.substring(0, 1),
                style: TextStyle(
                  color: patient.needsAttention
                      ? Colors.orange.shade700
                      : (patient.hasSchedule && patient.takenCount == patient.totalCount)
                          ? Colors.lightBlue.shade700
                          : Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(patient.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(patient.subtitle, style: TextStyle(fontSize: 12, color: _subtitleColor)),
                ],
              ),
            ),
            if (patient.needsAttention)
              Chip(
                label: const Text('확인필요'),
                backgroundColor: Colors.orange.shade50,
                labelStyle: TextStyle(color: Colors.orange.shade800, fontSize: 12, fontWeight: FontWeight.w600),
                side: BorderSide.none,
              ),
          ],
        ),
      ),
    );
  }
}