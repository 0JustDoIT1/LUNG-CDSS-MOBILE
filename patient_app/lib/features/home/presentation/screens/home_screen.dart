import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
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
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => _ErrorView(
          onRetry: () {
            ref.invalidate(patientProfileProvider);
            ref.invalidate(homeSummaryProvider);
          },
        ),
        data: (patient) {
          return summaryState.when(
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, stackTrace) => _ErrorView(
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

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.onRetry,
  });

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 52,
              color: AppColors.danger,
            ),
            const SizedBox(height: 16),
            const Text(
              '홈 정보를 불러오지 못했습니다.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}