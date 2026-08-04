class HomeSummary {
  const HomeSummary({
    required this.latestTestTitle,
    required this.latestTestDate,
    required this.latestTestStatus,
    required this.todayMedicationCount,
    required this.completedMedicationCount,
    required this.hasSymptomRecordToday,
    required this.nextAppointmentDepartment,
    required this.nextAppointmentDoctor,
    required this.nextAppointmentDateTime,
    required this.unreadNotificationCount,
  });

  final String latestTestTitle;
  final DateTime latestTestDate;
  final String latestTestStatus;

  final int todayMedicationCount;
  final int completedMedicationCount;

  final bool hasSymptomRecordToday;

  final String nextAppointmentDepartment;
  final String nextAppointmentDoctor;
  final DateTime nextAppointmentDateTime;

  final int unreadNotificationCount;

  double get medicationProgress {
    if (todayMedicationCount == 0) {
      return 0;
    }

    return completedMedicationCount / todayMedicationCount;
  }

  bool get hasUpcomingAppointment {
    return nextAppointmentDateTime.isAfter(DateTime.now());
  }
}