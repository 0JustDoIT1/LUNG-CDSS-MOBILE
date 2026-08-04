import 'package:flutter/material.dart';

import '../models/patient_overview.dart';

/// 화면 확인용 mock 데이터.
NursePatientOverview mockNursePatientOverview(String name) {
  final overviews = {
    '홍길동': const NursePatientOverview(
      name: '홍길동',
      needsAttention: true,
      todayDoses: [
        MedicationDoseStatus(time: TimeOfDay(hour: 9, minute: 0), taken: false),
        MedicationDoseStatus(time: TimeOfDay(hour: 18, minute: 0), taken: false),
      ],
    ),
    '이순신': const NursePatientOverview(
      name: '이순신',
      needsAttention: false,
      todayDoses: [
        MedicationDoseStatus(time: TimeOfDay(hour: 9, minute: 0), taken: true),
      ],
    ),
    '최민수': const NursePatientOverview(
      name: '최민수',
      needsAttention: false,
      todayDoses: [], // 복약스케줄 미설정
    ),
  };

  return overviews[name] ??
      NursePatientOverview(name: name, needsAttention: false, todayDoses: const []);
}