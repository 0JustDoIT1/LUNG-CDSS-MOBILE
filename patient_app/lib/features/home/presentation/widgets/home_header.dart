import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../data/models/patient_profile.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    required this.patient,
    required this.unreadNotificationCount,
    super.key,
  });

  final PatientProfile patient;
  final int unreadNotificationCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person_outline_rounded,
            color: AppColors.primary,
            size: 28,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${patient.name}님, 안녕하세요',
                style: AppTextStyles.headlineMedium.copyWith(
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                patient.hospitalName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              tooltip: '알림',
              onPressed: () {
                context.push(RouteNames.notifications);
              },
              icon: const Icon(
                Icons.notifications_none_rounded,
                size: 28,
              ),
            ),
            if (unreadNotificationCount > 0)
              Positioned(
                top: 3,
                right: 3,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    unreadNotificationCount > 9
                        ? '9+'
                        : '$unreadNotificationCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}