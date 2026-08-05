class Guardian {
  const Guardian({
    required this.id,
    required this.name,
    required this.patientName,
    required this.linkedAt,
  });

  final String id;
  final String name;
  final String patientName;
  final DateTime linkedAt;

  Guardian copyWith({
    String? id,
    String? name,
    String? patientName,
    DateTime? linkedAt,
  }) {
    return Guardian(
      id: id ?? this.id,
      name: name ?? this.name,
      patientName: patientName ?? this.patientName,
      linkedAt: linkedAt ?? this.linkedAt,
    );
  }
}

class GuardianInviteCode {
  const GuardianInviteCode({
    required this.code,
    required this.expiresAt,
  });

  final String code;
  final DateTime expiresAt;

  bool get isExpired {
    return DateTime.now().isAfter(expiresAt);
  }

  GuardianInviteCode copyWith({
    String? code,
    DateTime? expiresAt,
  }) {
    return GuardianInviteCode(
      code: code ?? this.code,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}