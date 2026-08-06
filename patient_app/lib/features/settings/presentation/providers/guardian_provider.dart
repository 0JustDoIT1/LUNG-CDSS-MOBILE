import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/guardian.dart';

class GuardianState {
  const GuardianState({
    required this.linkedGuardians,
  });

  final List<Guardian> linkedGuardians;

  GuardianState copyWith({
    List<Guardian>? linkedGuardians,
  }) {
    return GuardianState(
      linkedGuardians: linkedGuardians ?? this.linkedGuardians,
    );
  }
}

class GuardianNotifier extends Notifier<GuardianState> {
  @override
  GuardianState build() {
    return const GuardianState(linkedGuardians: []);
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
