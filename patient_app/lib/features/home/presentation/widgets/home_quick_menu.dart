import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../intake/presentation/providers/intake_form_provider.dart';

class HomeQuickMenu extends ConsumerWidget {
  const HomeQuickMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIntakeCompleted = ref.watch(
      intakeFormProvider.select(
        (state) => state.maybeWhen(
          data: (form) => form.isCompleted,
          orElse: () => false,
        ),
      ),
    );

    final items = [
      _QuickMenuItem(
        icon: isIntakeCompleted
            ? Icons.check_circle_outline_rounded
            : Icons.assignment_outlined,
        label: isIntakeCompleted
            ? '문진 완료'
            : '문진 작성',
        route: RouteNames.intakeForm,
        isCompleted: isIntakeCompleted,
      ),
      const _QuickMenuItem(
        icon: Icons.qr_code_rounded,
        label: '환자 QR',
        route: RouteNames.patientQr,
      ),
      const _QuickMenuItem(
        icon: Icons.notifications_none_rounded,
        label: '알림',
        route: RouteNames.notifications,
      ),
      const _QuickMenuItem(
        icon: Icons.smart_toy_outlined,
        label: 'AI 챗봇',
        route: RouteNames.chatbot,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '빠른 메뉴',
          style: AppTextStyles.headlineMedium,
        ),
        const SizedBox(height: 14),
        GridView.builder(
          itemCount: items.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.8,
          ),
          itemBuilder: (context, index) {
            final item = items[index];

            return Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  context.push(item.route);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: item.isCompleted
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                        child: Icon(
                          item.icon,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.label,
                          style:
                              AppTextStyles.bodyMedium.copyWith(
                            color: item.isCompleted
                                ? AppColors.primary
                                : null,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _QuickMenuItem {
  const _QuickMenuItem({
    required this.icon,
    required this.label,
    required this.route,
    this.isCompleted = false,
  });

  final IconData icon;
  final String label;
  final String route;
  final bool isCompleted;
}