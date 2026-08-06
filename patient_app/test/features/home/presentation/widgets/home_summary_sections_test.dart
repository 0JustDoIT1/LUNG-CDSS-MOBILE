import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/data/models/home_summary.dart';
import 'package:patient_app/features/home/presentation/widgets/medication_appointment_cards.dart';
import 'package:patient_app/features/home/presentation/widgets/today_health_summary.dart';

void main() {
  testWidgets('appointment section contains no duplicate medication card', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: HomeAppointmentCard(summary: _summary)),
      ),
    );

    expect(find.text('예약'), findsOneWidget);
    expect(find.text('다음 진료 예약'), findsOneWidget);
    expect(find.text('오늘 복약'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('today health shows safe empty medication state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TodayHealthSummary(
            summary: _summary,
            onMedicationTap: () {},
            onSymptomTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('0%'), findsOneWidget);
    expect(find.textContaining('등록된 복약 일정이 없습니다.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

const _summary = HomeSummary(
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
