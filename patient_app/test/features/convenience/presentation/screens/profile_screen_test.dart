import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/widgets/app_button.dart';
import 'package:patient_app/core/network/api_exception.dart';
import 'package:patient_app/features/auth/data/models/patient_profile.dart';
import 'package:patient_app/features/convenience/presentation/screens/profile_screen.dart';
import 'package:patient_app/features/home/presentation/providers/patient_provider.dart';

void main() {
  test('maps profile genders to patient-facing labels', () {
    expect(profileGenderLabel('male'), '남성');
    expect(profileGenderLabel('female'), '여성');
    expect(profileGenderLabel(null), '미등록');
  });

  test('maps profile update status codes to safe messages', () {
    expect(
      profileUpdateErrorMessage(
        const ApiException(message: 'validation', statusCode: 400),
      ),
      '입력한 정보를 확인해 주세요.',
    );
    expect(
      profileUpdateErrorMessage(
        const ApiException(message: 'forbidden', statusCode: 403),
      ),
      '프로필을 수정할 권한이 없습니다.',
    );
    expect(
      profileUpdateErrorMessage(
        const ApiException(message: 'not found', statusCode: 404),
      ),
      '환자 프로필을 찾을 수 없습니다.',
    );
  });

  testWidgets('shows existing profile fields and read-only phone number', (
    tester,
  ) async {
    await _pumpProfile(tester, _profile);

    expect(find.text('홍길동'), findsWidgets);
    expect(find.text('여성'), findsOneWidget);
    expect(find.text('010-1234-5678'), findsOneWidget);
    expect(find.text('서울병원'), findsOneWidget);
  });

  testWidgets('blocks saving when nothing changed or the name is empty', (
    tester,
  ) async {
    await _pumpProfile(tester, _profile);
    final profileList = find.byType(ListView);
    expect(profileList, findsOneWidget);

    final editFinder = find.byKey(
      const ValueKey('patient-profile-edit-button'),
    );
    await tester.dragUntilVisible(
      editFinder,
      profileList,
      const Offset(0, -250),
    );
    expect(editFinder, findsOneWidget);
    await tester.tap(editFinder);
    await tester.pumpAndSettle();

    final saveFinder = find.byKey(
      const ValueKey('patient-profile-save-button'),
    );
    await tester.dragUntilVisible(
      saveFinder,
      find.byType(ListView),
      const Offset(0, -250),
    );
    expect(saveFinder, findsOneWidget);
    expect(tester.widget<AppButton>(saveFinder).onPressed, isNull);

    final nameFinder = find.byKey(const ValueKey('patient-profile-name-field'));
    expect(nameFinder, findsOneWidget);
    await tester.enterText(nameFinder, '');
    await tester.pump();
    expect(tester.widget<AppButton>(saveFinder).onPressed, isNull);

    await tester.enterText(nameFinder, '김환자');
    await tester.pump();
    expect(tester.widget<AppButton>(saveFinder).onPressed, isNotNull);
  });
}

Future<void> _pumpProfile(WidgetTester tester, PatientProfile profile) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [patientProfileProvider.overrideWithValue(AsyncData(profile))],
      child: const MaterialApp(home: ProfileScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

final _profile = PatientProfile(
  patientNumber: 'P1234567',
  birthDate: DateTime(1990, 1, 1),
  gender: 'female',
  hospitalName: '서울병원',
  assignedDoctorId: null,
  name: '홍길동',
  phoneNumber: '010-1234-5678',
);
