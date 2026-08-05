import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../home/presentation/providers/patient_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(patientProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('내 프로필')),
      body: SafeArea(
        child: profileState.when(
          loading: () => const AppLoadingView(message: '프로필 정보를 불러오는 중입니다.'),
          error: (error, stackTrace) => AppErrorView(
            message: _errorMessage(error),
            onRetry: () => ref.invalidate(patientProfileProvider),
          ),
          data: (profile) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_outline_rounded,
                        size: 42,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(profile.name, style: AppTextStyles.headlineLarge),
                    const SizedBox(height: 6),
                    Text(
                      '환자번호 ${profile.patientNumber}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              _InfoCard(
                children: [
                  _InfoRow(label: '이름', value: profile.name),
                  const Divider(height: 1),
                  _InfoRow(
                    label: '생년월일',
                    value: _formatDate(profile.birthDate),
                  ),
                  const Divider(height: 1),
                  _InfoRow(label: '성별', value: _genderLabel(profile.gender)),
                  const Divider(height: 1),
                  _InfoRow(label: '환자번호', value: profile.patientNumber),
                  const Divider(height: 1),
                  _InfoRow(label: '소속병원', value: profile.hospitalName),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}.$month.$day';
  }

  static String _genderLabel(String? gender) {
    switch (gender) {
      case 'male':
        return '남성';
      case 'female':
        return '여성';
      case null:
        return '-';
      default:
        return gender;
    }
  }

  static String _errorMessage(Object error) {
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

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.lock_outline_rounded,
            size: 18,
            color: AppColors.textDisabled,
          ),
        ],
      ),
    );
  }
}
