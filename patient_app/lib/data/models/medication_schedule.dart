class MedicationSchedule {
  const MedicationSchedule({
    required this.id,
    required this.medicationName,
    required this.dosage,
    required this.instructions,
    required this.scheduledAt,
    required this.isTaken,
    this.takenAt,
  });

  final String id;
  final String medicationName;
  final String dosage;
  final String instructions;
  final DateTime scheduledAt;
  final bool isTaken;
  final DateTime? takenAt;

  MedicationSchedule copyWith({
    String? id,
    String? medicationName,
    String? dosage,
    String? instructions,
    DateTime? scheduledAt,
    bool? isTaken,
    DateTime? takenAt,
    bool clearTakenAt = false,
  }) {
    return MedicationSchedule(
      id: id ?? this.id,
      medicationName: medicationName ?? this.medicationName,
      dosage: dosage ?? this.dosage,
      instructions: instructions ?? this.instructions,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      isTaken: isTaken ?? this.isTaken,
      takenAt: clearTakenAt ? null : takenAt ?? this.takenAt,
    );
  }
}