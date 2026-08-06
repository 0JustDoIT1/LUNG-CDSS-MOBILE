import '../models/home_summary.dart';

class MockHomeData {
  const MockHomeData._();

  static const HomeSummary summary = HomeSummary(
    latestTestTitle: null,
    latestTestDate: null,
    latestTestStatus: null,
    todayMedicationCount: 0,
    completedMedicationCount: 0,
    hasSymptomRecordToday: false,
    nextAppointmentDepartment: null,
    nextAppointmentDoctor: null,
    nextAppointmentDateTime: null,
    unreadNotificationCount: 0,
  );
}