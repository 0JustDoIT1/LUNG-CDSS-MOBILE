import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/auth_api.dart';
import '../../../core/api/cases_api.dart';
import '../../../core/api/intake_api.dart';
import '../../../core/auth/session_controller.dart';
import '../../nurse/models/staff_patient.dart';
import '../models/review_case.dart';

/// 환자 상세정보(의사용). 실제 API 연동:
/// - 기본정보: GET /api/auth/staff/patients/ 목록에서 이름으로 매칭
/// - 진단정보: GET /api/cases/?search=이름 중 최근 확정(confirmed) 케이스의 final_subtype/final_note
/// - 문진표: GET /api/intake/patient/{id}/ (읽기전용, 미제출이면 404 → null)
class PatientDetailScreen extends StatefulWidget {
  final String patientName;

  const PatientDetailScreen({super.key, required this.patientName});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  StaffPatient? _patient;
  ReviewCase? _latestConfirmedCase;
  PatientIntake? _intake;
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
      final staffPatients = await fetchStaffPatients(token);
      StaffPatient? patient;
      for (final p in staffPatients) {
        if (p.name == widget.patientName) {
          patient = p;
          break;
        }
      }
      if (patient == null) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = '환자 정보를 찾을 수 없어요.';
        });
        return;
      }

      final cases = await fetchCasesByPatientName(widget.patientName, token);
      final confirmedCases = cases.where((c) => c.status == CaseStatus.confirmed && c.finalSubtype != null).toList()
        ..sort((a, b) => (b.completedAt ?? b.uploadedAt).compareTo(a.completedAt ?? a.uploadedAt));

      PatientIntake? intake;
      try {
        intake = await fetchPatientIntake(patient.id, token);
      } on ApiException catch (_) {
        // 문진표 조회 실패는 조용히 무시 — 나머지 정보는 계속 보여줘야 함
      }

      if (!mounted) return;
      setState(() {
        _patient = patient;
        _latestConfirmedCase = confirmedCases.isNotEmpty ? confirmedCases.first : null;
        _intake = intake;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('상세 정보')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
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

    final patient = _patient!;
    final colorScheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('기본정보', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('이름  ${patient.name}'),
                  const SizedBox(height: 4),
                  Text('생년월일  ${patient.birthDate}'),
                  const SizedBox(height: 4),
                  Text('환자번호  ${patient.patientNumber}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('진단정보', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _latestConfirmedCase == null
                  ? Text(
                      '아직 확정된 진단이 없어요',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('최근 확정 아형  '),
                            Chip(
                              label: Text(_latestConfirmedCase!.finalSubtype!),
                              backgroundColor: Colors.blue.shade50,
                              labelStyle: TextStyle(color: Colors.blue.shade700),
                              side: BorderSide.none,
                            ),
                          ],
                        ),
                        if ((_latestConfirmedCase!.finalNote ?? '').isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(_latestConfirmedCase!.finalNote!),
                        ],
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('문진표 (읽기전용)', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: (_intake == null || _intake!.answers.isEmpty)
                ? Text(
                    '아직 제출된 문진표가 없어요',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final answer in _intake!.answers) ...[
                        Text(
                          answer.questionText,
                          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 2),
                        Text(answer.answerText),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
