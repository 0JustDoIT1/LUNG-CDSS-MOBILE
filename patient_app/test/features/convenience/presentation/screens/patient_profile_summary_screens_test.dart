import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/features/auth/data/models/patient_profile.dart';
import 'package:patient_app/features/convenience/presentation/screens/more_screen.dart';
import 'package:patient_app/features/home/presentation/providers/patient_provider.dart';

void main() {
  testWidgets('more screen shows the profile name and patient number', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const MoreScreen(), _profile));
    await tester.pumpAndSettle();

    expect(find.text('홍길동'), findsOneWidget);
    expect(find.text('환자번호 P-1234'), findsOneWidget);
    expect(find.textContaining('2026080301'), findsNothing);
  });

  testWidgets('more screen shows profile loading state', (tester) async {
    final completer = Completer<PatientProfile>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          patientProfileProvider.overrideWith((ref) => completer.future),
        ],
        child: const MaterialApp(home: MoreScreen()),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('more screen shows profile error and retry', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          patientProfileProvider.overrideWith(
            (ref) async => throw Exception('test error'),
          ),
        ],
        child: const MaterialApp(home: MoreScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('프로필 정보를 불러오지 못했습니다.'), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);
  });
}

Widget _app(Widget screen, PatientProfile profile) {
  return ProviderScope(
    overrides: [patientProfileProvider.overrideWithValue(AsyncData(profile))],
    child: MaterialApp(home: screen),
  );
}

final _profile = PatientProfile(
  patientNumber: 'P-1234',
  birthDate: DateTime(2000),
  gender: 'female',
  hospitalName: '병원',
  assignedDoctorId: null,
  name: '홍길동',
  phoneNumber: null,
);
