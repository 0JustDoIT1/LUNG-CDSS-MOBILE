import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/guardian.dart';

class GuardianState {
  const GuardianState({
    required this.inviteCode,
    required this.linkedGuardians,
  });

  final GuardianInviteCode inviteCode;
  final List<Guardian> linkedGuardians;

  GuardianState copyWith({
    GuardianInviteCode? inviteCode,
    List<Guardian>? linkedGuardians,
  }) {
    return GuardianState(
      inviteCode: inviteCode ?? this.inviteCode,
      linkedGuardians: linkedGuardians ?? this.linkedGuardians,
    );
  }
}

class GuardianNotifier extends Notifier<GuardianState> {
  static const String _characters =
      'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  @override
  GuardianState build() {
    return GuardianState(
      inviteCode: GuardianInviteCode(
        code: _generateCode(),
        expiresAt: DateTime.now().add(
          const Duration(hours: 24),
        ),
      ),
      linkedGuardians: const [],
    );
  }

  String _generateCode() {
    final random = Random.secure();

    return List.generate(
      6,
      (_) => _characters[
          random.nextInt(_characters.length)],
    ).join();
  }

  void createNewInviteCode() {
    state = state.copyWith(
      inviteCode: GuardianInviteCode(
        code: _generateCode(),
        expiresAt: DateTime.now().add(
          const Duration(hours: 24),
        ),
      ),
    );
  }

  bool validateInviteCode(String code) {
    final normalizedCode = code.trim().toUpperCase();

    if (state.inviteCode.isExpired) {
      return false;
    }

    return state.inviteCode.code == normalizedCode;
  }

  void registerGuardian({
    required String name,
    required String patientName,
  }) {
    final guardian = Guardian(
      id: DateTime.now()
          .microsecondsSinceEpoch
          .toString(),
      name: name.trim(),
      patientName: patientName,
      linkedAt: DateTime.now(),
    );

    state = state.copyWith(
      linkedGuardians: [
        ...state.linkedGuardians,
        guardian,
      ],
    );
  }

  void unlinkGuardian(String guardianId) {
    state = state.copyWith(
      linkedGuardians: state.linkedGuardians
          .where(
            (guardian) => guardian.id != guardianId,
          )
          .toList(),
    );
  }
}

final guardianProvider =
    NotifierProvider<GuardianNotifier, GuardianState>(
  GuardianNotifier.new,
);