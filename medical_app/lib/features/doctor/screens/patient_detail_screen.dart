import 'package:flutter/material.dart';

import '../mock/patient_profile_mock.dart';
import '../models/patient_profile.dart';

/// 환자 상세정보 확인.
/// - 기본정보: 이름, 생년월일
/// - 진단정보: 최근 확정 ConfirmedFinding.final_subtype
/// - 증상/검사추이: SymptomCheck, 검사수치 그래프
/// - 문진표: IntakeForm 요약 (읽기전용 조회)
///
/// TODO: 실제 연결 시 mockPatientProfile() 대신 API로 교체.
class PatientDetailScreen extends StatelessWidget {
  final String patientName;

  const PatientDetailScreen({super.key, required this.patientName});

  @override
  Widget build(BuildContext context) {
    final profile = mockPatientProfile(patientName);

    return Scaffold(
      appBar: AppBar(title: const Text('상세 정보')),
      body: ListView(
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
                  Text('이름  ${profile.name}'),
                  const SizedBox(height: 4),
                  Text('생년월일  ${profile.birthDate}'),
                  const SizedBox(height: 4),
                  Text('환자번호  ${profile.patientId}'),
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
              child: Row(
                children: [
                  const Text('최근 확정 아형  '),
                  Chip(
                    label: Text(profile.finalSubtype),
                    backgroundColor: Colors.blue.shade50,
                    labelStyle: TextStyle(color: Colors.blue.shade700),
                    side: BorderSide.none,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          // TODO: 문진표는 환자앱에서 작성한 데이터를 API로 가져올 예정 (지금은 mock)
          const Text('문진표 (읽기전용)', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(profile.intakeSummary),
          ),
        ],
      ),
    );
  }
}

