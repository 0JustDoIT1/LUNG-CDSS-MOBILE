import 'package:flutter/material.dart';

/// 오늘 복약 한 회차 체크 상태. 환자앱에서 체크한 데이터가 넘어오는 지점.
class MedicationDoseStatus {
  final TimeOfDay time;
  final bool taken;

  const MedicationDoseStatus({required this.time, required this.taken});
}

/// 담당환자 개요(오늘 복약체크 상태). 담당환자 목록/상세 화면에서 사용.
/// TODO: 실제 연결 시 fromJson() 추가하고 API 응답으로 교체.
class NursePatientOverview {
  final String name;
  final bool needsAttention;
  final List<MedicationDoseStatus> todayDoses; // 비어있으면 복약스케줄 미설정

  const NursePatientOverview({
    required this.name,
    required this.needsAttention,
    required this.todayDoses,
  });

  bool get hasSchedule => todayDoses.isNotEmpty;
  int get takenCount => todayDoses.where((d) => d.taken).length;
  int get totalCount => todayDoses.length;

  String get subtitle =>
      hasSchedule ? '오늘 복약 $takenCount/$totalCount 완료' : '복약스케줄 미설정';
}