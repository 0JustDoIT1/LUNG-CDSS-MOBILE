import '../models/home_summary.dart';

class MockHomeData {
  const MockHomeData._();

  static final HomeSummary summary = HomeSummary(
    latestTestTitle: '폐암 유전자 변이 검사',
    latestTestDate: DateTime(2026, 7, 30),
    latestTestStatus: '결과 확인 가능',
    todayMedicationCount: 4,
    completedMedicationCount: 2,
    hasSymptomRecordToday: false,
    nextAppointmentDepartment: '호흡기내과',
    nextAppointmentDoctor: '김호흡',
    nextAppointmentDateTime: DateTime(
      2026,
      8,
      5,
      10,
      30,
    ),
    unreadNotificationCount: 3,
  );
}