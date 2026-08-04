import 'package:flutter/material.dart';

import '../../mock/patient_overview_mock.dart';
import '../../models/patient_overview.dart';
import '../nurse_patient_detail_screen.dart';

/// 탭 2: 담당환자 목록.
/// 디자인 시안 반영 — 상단 소속과/인원수 + 환자별 카드(오늘 복약체크 상태, 확인필요 뱃지).
/// TODO: 실제 연결 시 mock 데이터 대신 API로 교체.
class NursePatientsTab extends StatelessWidget {
  const NursePatientsTab({super.key});

  static const _patientNames = ['홍길동', '이순신', '최민수'];

  @override
  Widget build(BuildContext context) {
    final patients = _patientNames.map(mockNursePatientOverview).toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            '담당환자 목록',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '호흡기내과 · ${patients.length}명',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          ...patients.map((p) => _PatientCard(patient: p)),
        ],
      ),
    );
  }
}

class _PatientCard extends StatefulWidget {
  final NursePatientOverview patient;

  const _PatientCard({required this.patient});

  @override
  State<_PatientCard> createState() => _PatientCardState();
}

class _PatientCardState extends State<_PatientCard> {
  bool _isPressed = false;

  Color get _subtitleColor {
    final p = widget.patient;
    if (!p.hasSchedule) return Colors.grey.shade400;
    if (p.takenCount == p.totalCount) return Colors.lightBlue.shade400; // 복약 완료 → 하늘색
    return Colors.orange.shade700;
  }

  @override
  Widget build(BuildContext context) {
    final patient = widget.patient;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => NursePatientDetailScreen(patientName: patient.name),
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
                  Text(
                    patient.subtitle,
                    style: TextStyle(fontSize: 12, color: _subtitleColor),
                  ),
                ],
              ),
            ),
            if (patient.needsAttention)
              Chip(
                label: const Text('확인필요'),
                backgroundColor: Colors.orange.shade50,
                labelStyle: TextStyle(
                  color: Colors.orange.shade800,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                side: BorderSide.none,
              ),
          ],
        ),
      ),
    );
  }
}