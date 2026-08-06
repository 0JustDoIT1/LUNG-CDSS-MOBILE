class GuardianInvite {
  const GuardianInvite({
    required this.id,
    required this.inviteCode,
    required this.invitedAt,
    required this.guardianName,
    required this.acceptedAt,
  });

  factory GuardianInvite.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final inviteCode = json['invite_code'];
    final guardianName = json['guardian_name'];
    final invitedAtValue = json['invited_at'];
    final acceptedAtValue = json['accepted_at'];

    if (id is! String || id.isEmpty) {
      throw const FormatException('id 필드가 올바르지 않습니다.');
    }
    if (inviteCode is! String || inviteCode.isEmpty) {
      throw const FormatException('invite_code 필드가 올바르지 않습니다.');
    }
    if (guardianName != null && guardianName is! String) {
      throw const FormatException('guardian_name 필드가 올바르지 않습니다.');
    }
    if (invitedAtValue is! String) {
      throw const FormatException('invited_at 필드가 올바르지 않습니다.');
    }
    final invitedAt = DateTime.tryParse(invitedAtValue);
    if (invitedAt == null) {
      throw const FormatException('invited_at 날짜가 올바르지 않습니다.');
    }
    DateTime? acceptedAt;
    if (acceptedAtValue != null) {
      if (acceptedAtValue is! String) {
        throw const FormatException('accepted_at 필드가 올바르지 않습니다.');
      }
      acceptedAt = DateTime.tryParse(acceptedAtValue);
      if (acceptedAt == null) {
        throw const FormatException('accepted_at 날짜가 올바르지 않습니다.');
      }
    }

    return GuardianInvite(
      id: id,
      inviteCode: inviteCode,
      guardianName: guardianName as String?,
      invitedAt: invitedAt,
      acceptedAt: acceptedAt,
    );
  }

  final String id;
  final String inviteCode;
  final String? guardianName;
  final DateTime invitedAt;
  final DateTime? acceptedAt;
}
