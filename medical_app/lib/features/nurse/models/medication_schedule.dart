import 'package:flutter/material.dart';

/// 복약 스케줄 하나. 약물명/용량 없이 복용횟수·시간·기간만 관리.
/// TODO: 실제 연결 시 fromJson() 추가하고 API로 교체.
class MedicationEntry {
  final int timesPerDay; // 1일 횟수
  final List<TimeOfDay> times; // 복용시간
  final DateTime startDate;
  final DateTime? endDate; // null이면 '미정'

  const MedicationEntry({
    required this.timesPerDay,
    required this.times,
    required this.startDate,
    this.endDate,
  });

  String get summary => '1일$timesPerDay회 · ${times.length}개 시간대';
}