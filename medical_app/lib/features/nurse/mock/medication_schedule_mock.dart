import 'package:flutter/material.dart';

import '../models/medication_schedule.dart';

/// 화면 확인용 mock 등록 스케줄 목록.
List<MedicationEntry> mockMedicationEntries() {
  return [
    MedicationEntry(
      timesPerDay: 1,
      times: const [TimeOfDay(hour: 9, minute: 0)],
      startDate: DateTime(2026, 8, 1),
    ),
  ];
}