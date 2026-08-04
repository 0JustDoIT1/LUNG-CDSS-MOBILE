import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../providers/home_summary_provider.dart';
import '../providers/patient_provider.dart';
import '../widgets/home_header.dart';
import '../widgets/today_health_summary.dart';
import '../widgets/latest_test_card.dart';
import '../widgets/medication_appointment_cards.dart';
import '../widgets/home_quick_menu.dart';



class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientState = ref.watch(patientProfileProvider);
    final summaryState = ref.watch(homeSummaryProvider);

    return SafeArea(
      child: patientState.when(
        loading: () => const AppLoadingView(
          message: '홈 정보를 불러오는 중입니다.',
        ),
        error: (error, stackTrace) => AppErrorView(
          message: '환자 정보를 다시 불러와주세요.',
          onRetry: () {
            ref.invalidate(patientProfileProvider);
            ref.invalidate(homeSummaryProvider);
          },
        ),
        data: (patient) {
          return summaryState.when(
            loading: () => const AppLoadingView(
              message: '홈 정보를 불러오는 중입니다.',
            ),
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
                  ref.invalidate(homeSummaryProvider);

                  await Future.wait([
                    ref.read(patientProfileProvider.future),
                    ref.read(homeSummaryProvider.future),
                  ]);
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    20,
                    20,
                    120,
                  ),
                  children: [
                    HomeHeader(
                      patient: patient,
                      unreadNotificationCount:
                          summary.unreadNotificationCount,
                    ),
                    const SizedBox(height: 32),

                    TodayHealthSummary(
                      summary: summary,
                    ),
                    const SizedBox(height: 32),

                    LatestTestCard(
                      summary: summary,
                    ),
                    const SizedBox(height: 32),

                    MedicationAppointmentCards(
                      summary: summary,
                    ),
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
}

