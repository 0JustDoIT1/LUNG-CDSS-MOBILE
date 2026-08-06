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

  final String? latestTestTitle;
  final DateTime? latestTestDate;
  final String? latestTestStatus;

  final int todayMedicationCount;
  final int completedMedicationCount;

  final bool hasSymptomRecordToday;

  final String? nextAppointmentDepartment;
  final String? nextAppointmentDoctor;
  final DateTime? nextAppointmentDateTime;

  final int unreadNotificationCount;

  double get medicationProgress {
    if (todayMedicationCount == 0) {
      return 0;
    }

    return completedMedicationCount / todayMedicationCount;
  }

  bool get hasLatestTest {
    return latestTestTitle != null &&
        latestTestTitle!.trim().isNotEmpty &&
        latestTestDate != null;
  }

  bool get hasUpcomingAppointment {
    final appointmentDateTime = nextAppointmentDateTime;

    if (appointmentDateTime == null) {
      return false;
    }

    return appointmentDateTime.isAfter(DateTime.now());
  }

  HomeSummary copyWith({
    String? latestTestTitle,
    DateTime? latestTestDate,
    String? latestTestStatus,
    int? todayMedicationCount,
    int? completedMedicationCount,
    bool? hasSymptomRecordToday,
    String? nextAppointmentDepartment,
    String? nextAppointmentDoctor,
    DateTime? nextAppointmentDateTime,
    bool replaceNextAppointment = false,
    int? unreadNotificationCount,
  }) {
    return HomeSummary(
      latestTestTitle: latestTestTitle ?? this.latestTestTitle,
      latestTestDate: latestTestDate ?? this.latestTestDate,
      latestTestStatus: latestTestStatus ?? this.latestTestStatus,
      todayMedicationCount: todayMedicationCount ?? this.todayMedicationCount,
      completedMedicationCount:
          completedMedicationCount ?? this.completedMedicationCount,
      hasSymptomRecordToday:
          hasSymptomRecordToday ?? this.hasSymptomRecordToday,
      nextAppointmentDepartment: replaceNextAppointment
          ? nextAppointmentDepartment
          : nextAppointmentDepartment ?? this.nextAppointmentDepartment,
      nextAppointmentDoctor: replaceNextAppointment
          ? nextAppointmentDoctor
          : nextAppointmentDoctor ?? this.nextAppointmentDoctor,
      nextAppointmentDateTime: replaceNextAppointment
          ? nextAppointmentDateTime
          : nextAppointmentDateTime ?? this.nextAppointmentDateTime,
      unreadNotificationCount:
          unreadNotificationCount ?? this.unreadNotificationCount,
    );
  }
}
