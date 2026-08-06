import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../core/network/api_exception.dart';
import '../../../appointment/presentation/providers/appointment_provider.dart';
import '../../../results/presentation/providers/test_result_provider.dart';
import '../../../symptom/presentation/providers/symptom_medication_provider.dart';
import '../providers/home_summary_provider.dart';
import '../providers/patient_provider.dart';
import '../widgets/home_header.dart';
import '../widgets/today_health_summary.dart';
import '../widgets/latest_test_card.dart';
import '../widgets/medication_appointment_cards.dart';
import '../widgets/home_quick_menu.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/route_names.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientState = ref.watch(patientProfileProvider);
    final summaryState = ref.watch(homeSummaryProvider);

    return SafeArea(
      child: patientState.when(
        loading: () => const AppLoadingView(message: '홈 정보를 불러오는 중입니다.'),
        error: (error, stackTrace) => AppErrorView(
          message: _profileErrorMessage(error),
          onRetry: () {
            ref.invalidate(patientProfileProvider);
            ref.invalidate(homeSummaryProvider);
          },
        ),
        data: (patient) {
          return summaryState.when(
            loading: () => const AppLoadingView(message: '홈 정보를 불러오는 중입니다.'),
            error: (error, stackTrace) => AppErrorView(
              message: '건강 요약 정보를 다시 불러와주세요.',
              onRetry: () {
                ref.invalidate(homeSummaryProvider);
              },
            ),
            data: (summary) {
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(patientProfileProvider);
                  ref.invalidate(todayMedicationLogsProvider);
                  ref.invalidate(symptomRecordsProvider);
                  ref.invalidate(testResultsProvider);
                  ref.invalidate(myAppointmentsProvider);

                  await Future.wait([
                    ref.read(patientProfileProvider.future),
                    ref.read(todayMedicationLogsProvider.future),
                    ref.read(symptomRecordsProvider.future),
                    ref.read(testResultsProvider.future),
                    ref.read(myAppointmentsProvider.future),
                  ]);
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                  children: [
                    HomeHeader(patient: patient),
                    const SizedBox(height: 32),

                    TodayHealthSummary(
                      summary: summary,
                      onMedicationTap: () {
                        context.go(RouteNames.symptoms);
                      },
                      onSymptomTap: () {
                        context.push(RouteNames.symptomRecordForm);
                      },
                    ),
                    const SizedBox(height: 32),

                    LatestTestCard(summary: summary),
                    const SizedBox(height: 32),

                    HomeAppointmentCard(summary: summary),
                    const SizedBox(height: 32),

                    const HomeQuickMenu(),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  static String _profileErrorMessage(Object error) {
    if (error is FormatException) {
      return '프로필 정보 형식을 확인할 수 없습니다.';
    }
    if (error is ApiException) {
      if (error.statusCode == 401) {
        return '인증 정보가 만료됐거나 유효하지 않습니다.';
      }
      if (error.statusCode == 403) {
        return '프로필 정보를 조회할 권한이 없습니다.';
      }
      if (error.statusCode == 404) {
        return '환자 프로필을 찾을 수 없습니다.';
      }
      if (error.code == 'TIMEOUT') {
        return '서버 응답 시간이 초과되었습니다.';
      }
      if (error.code == 'CONNECTION_ERROR') {
        return '네트워크 연결을 확인해주세요.';
      }
    }
    return '프로필 정보를 불러오지 못했습니다.';
  }
}
