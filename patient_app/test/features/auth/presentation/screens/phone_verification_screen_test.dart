import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/auth/token_storage.dart';
import 'package:patient_app/core/network/api_client.dart';
import 'package:patient_app/core/widgets/app_button.dart';
import 'package:patient_app/features/auth/data/auth_api.dart';
import 'package:patient_app/features/auth/data/auth_repository.dart';
import 'package:patient_app/features/auth/data/models/hospital.dart';
import 'package:patient_app/features/auth/presentation/providers/auth_dependency_providers.dart';
import 'package:patient_app/features/auth/presentation/screens/phone_verification_screen.dart';

void main() {
  testWidgets('requires an explicit gender selection', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeRepository()),
        ],
        child: const MaterialApp(home: PhoneVerificationScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('성별을 선택해 주세요.'), findsOneWidget);
    const submitButtonKey = ValueKey('patient-register-submit-button');
    final submitButton = find.byKey(submitButtonKey);
    expect(submitButton, findsOneWidget);
    expect(tester.widget<AppButton>(submitButton).onPressed, isNull);

    await tester.tap(find.text('여성'));
    await tester.pump();

    expect(find.text('성별을 선택해 주세요.'), findsNothing);
    final selectedGender = find.byWidgetPredicate(
      (widget) =>
          widget is Semantics &&
          widget.properties.label == '여성 선택' &&
          widget.properties.selected == true,
    );
    expect(selectedGender, findsOneWidget);
  });
}

class _FakeRepository extends AuthRepository {
  _FakeRepository()
    : super(
        authApi: AuthApi(apiClient: ApiClient(dio: Dio())),
        tokenStorage: TokenStorage(),
      );

  @override
  Future<Hospital> getHospital() async {
    return const Hospital(
      id: 'hospital-uuid',
      name: '테스트 병원',
      address: '',
      phone: '',
    );
  }
}
