import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/features/appointment/data/models/patient_appointment.dart';
import 'package:patient_app/features/appointment/presentation/providers/appointment_provider.dart';
import 'package:patient_app/features/appointment/presentation/screens/appointment_detail_screen.dart';

void main() {
  testWidgets('shows the real appointment whose id matches the route id', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        appointmentId: 'real-appointment-uuid',
        appointments: [_appointment],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('호흡기내과'), findsOneWidget);
    expect(find.text('김의사'), findsAtLeastNWidgets(1));
    expect(find.text('예약 확정'), findsOneWidget);
    expect(find.text('2026.08.07 00:30'), findsOneWidget);
    expect(find.text('예약 정보를 찾을 수 없습니다.'), findsNothing);
  });

  testWidgets('shows not found when the route id does not match', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(appointmentId: 'different-id', appointments: [_appointment]),
    );
    await tester.pumpAndSettle();

    expect(find.text('예약 정보를 찾을 수 없습니다.'), findsOneWidget);
  });

  testWidgets('shows loading while the real appointment list is loading', (
    tester,
  ) async {
    final completer = Completer<List<PatientAppointment>>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myAppointmentsProvider.overrideWith((ref) => completer.future),
        ],
        child: const MaterialApp(
          home: AppointmentDetailScreen(appointmentId: 'real-appointment-uuid'),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows an error and retries the real appointment list', (
    tester,
  ) async {
    var loadCount = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myAppointmentsProvider.overrideWith((ref) async {
            loadCount += 1;
            throw Exception('test error');
          }),
        ],
        child: const MaterialApp(
          home: AppointmentDetailScreen(appointmentId: 'real-appointment-uuid'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('예약 상세정보를 불러오지 못했습니다.'), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);

    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();

    expect(loadCount, 2);
  });
}

Widget _app({
  required String appointmentId,
  required List<PatientAppointment> appointments,
}) {
  return ProviderScope(
    overrides: [
      myAppointmentsProvider.overrideWith((ref) async => appointments),
    ],
    child: MaterialApp(
      home: AppointmentDetailScreen(appointmentId: appointmentId),
    ),
  );
}

final _appointment = PatientAppointment(
  id: 'real-appointment-uuid',
  patientName: '환자',
  doctorName: '김의사',
  department: '호흡기내과',
  requestedAtSlot: DateTime(2026, 8, 7),
  confirmedSlot: DateTime(2026, 8, 7, 0, 30),
  status: 'confirmed',
  createdAt: DateTime(2026, 8, 5, 10),
);
