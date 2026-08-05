import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../auth/data/models/patient_gender.dart';
import '../../../auth/data/models/patient_profile.dart';
import '../../../home/presentation/providers/patient_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  bool _isEditing = false;
  PatientGender? _editedGender;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _startEditing(PatientProfile profile) {
    setState(() {
      _isEditing = true;
      _nameController.text = profile.name;
      _editedGender = _genderFromApi(profile.gender);
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _editedGender = null;
    });
  }

  bool _hasChanges(PatientProfile profile) {
    final name = _nameController.text.trim();
    return name != profile.name ||
        _editedGender?.apiValue != profile.gender;
  }

  Future<void> _save(PatientProfile profile) async {
    final trimmedName = _nameController.text.trim();
    if (trimmedName.isEmpty) {
      _showMessage('이름을 입력해 주세요.');
      return;
    }
    if (!_hasChanges(profile)) {
      _showMessage('변경된 정보가 없습니다.');
      return;
    }

    final name = trimmedName == profile.name ? null : trimmedName;
    final gender = _editedGender?.apiValue == profile.gender
        ? null
        : _editedGender?.apiValue;

    final success = await ref
        .read(patientProfileUpdateProvider.notifier)
        .saveProfile(name: name, gender: gender);
    if (!mounted) return;

    if (success) {
      setState(() => _isEditing = false);
      _showMessage('프로필이 수정되었습니다.');
      return;
    }
    _showMessage(
      profileUpdateErrorMessage(ref.read(patientProfileUpdateProvider).error),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(patientProfileProvider);
    final isSaving = ref.watch(patientProfileUpdateProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('내 프로필')),
      body: SafeArea(
        child: profileState.when(
          loading: () => const AppLoadingView(message: '프로필 정보를 불러오는 중입니다.'),
          error: (error, stackTrace) => AppErrorView(
            message: _loadErrorMessage(error),
            onRetry: () => ref.invalidate(patientProfileProvider),
          ),
          data: (profile) => _isEditing
              ? _EditProfileView(
                  profile: profile,
                  nameController: _nameController,
                  selectedGender: _editedGender,
                  isSaving: isSaving,
                  canSave:
                      _nameController.text.trim().isNotEmpty &&
                      _hasChanges(profile) &&
                      !isSaving,
                  onNameChanged: (_) => setState(() {}),
                  onGenderSelected: (gender) {
                    setState(() => _editedGender = gender);
                  },
                  onCancel: isSaving ? null : _cancelEditing,
                  onSave: isSaving ? null : () => _save(profile),
                )
              : _ProfileView(
                  profile: profile,
                  onEdit: () => _startEditing(profile),
                ),
        ),
      ),
    );
  }

  static PatientGender? _genderFromApi(String? gender) {
    for (final value in PatientGender.values) {
      if (value.apiValue == gender) return value;
    }
    return null;
  }

  static String _loadErrorMessage(Object error) {
    if (error is FormatException) return '프로필 정보 형식을 확인할 수 없습니다.';
    if (error is ApiException) {
      if (error.statusCode == 401) return '인증 정보가 만료됐거나 유효하지 않습니다.';
      if (error.statusCode == 403) return '프로필 정보를 조회할 권한이 없습니다.';
      if (error.statusCode == 404) return '환자 프로필을 찾을 수 없습니다.';
      if (error.code == 'TIMEOUT') return '서버 응답 시간이 초과되었습니다.';
      if (error.code == 'CONNECTION_ERROR') return '네트워크 연결을 확인해주세요.';
    }
    return '프로필 정보를 불러오지 못했습니다.';
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({required this.profile, required this.onEdit});
  final PatientProfile profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        _ProfileHeader(profile: profile),
        const SizedBox(height: 28),
        _InfoCard(
          children: [
            _InfoRow(label: '이름', value: profile.name, isLocked: false),
            _InfoRow(
              label: '생년월일',
              value: _displayDate(profile.birthDate),
            ),
            _InfoRow(
              label: '성별',
              value: profileGenderLabel(profile.gender),
              isLocked: false,
            ),
            if (profile.phoneNumber?.isNotEmpty == true)
              _InfoRow(label: '전화번호', value: profile.phoneNumber!),
            _InfoRow(label: '환자번호', value: profile.patientNumber),
            _InfoRow(label: '소속병원', value: profile.hospitalName),
            _InfoRow(
              label: '담당 의료진',
              value: profile.assignedDoctorId?.isNotEmpty == true
                  ? '등록됨'
                  : '미등록',
            ),
          ],
        ),
        const SizedBox(height: 24),
        AppButton(
          key: const ValueKey('patient-profile-edit-button'),
          text: '프로필 수정',
          icon: Icons.edit_outlined,
          onPressed: onEdit,
        ),
      ],
    );
  }
}

class _EditProfileView extends StatelessWidget {
  const _EditProfileView({
    required this.profile,
    required this.nameController,
    required this.selectedGender,
    required this.isSaving,
    required this.canSave,
    required this.onNameChanged,
    required this.onGenderSelected,
    required this.onCancel,
    required this.onSave,
  });

  final PatientProfile profile;
  final TextEditingController nameController;
  final PatientGender? selectedGender;
  final bool isSaving;
  final bool canSave;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<PatientGender> onGenderSelected;
  final VoidCallback? onCancel;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        TextField(
          key: const ValueKey('patient-profile-name-field'),
          controller: nameController,
          onChanged: onNameChanged,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(labelText: '이름'),
        ),
        const SizedBox(height: 18),
        InputDecorator(
          key: const ValueKey('patient-profile-birth-date-field'),
          decoration: const InputDecoration(
            labelText: '생년월일',
            suffixIcon: Icon(Icons.lock_outline_rounded),
          ),
          child: Text(_displayDate(profile.birthDate)),
        ),
        const SizedBox(height: 18),
        Text('성별', style: AppTextStyles.bodyMedium),
        const SizedBox(height: 10),
        Row(
          children: PatientGender.values
              .map((gender) {
                final selected = gender == selectedGender;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: gender == PatientGender.female ? 6 : 0,
                      left: gender == PatientGender.male ? 6 : 0,
                    ),
                    child: OutlinedButton(
                      key: ValueKey(
                        'patient-profile-gender-${gender.apiValue}',
                      ),
                      onPressed: () => onGenderSelected(gender),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: selected
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : null,
                        side: BorderSide(
                          color: selected
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      child: Text(gender.label),
                    ),
                  ),
                );
              })
              .toList(growable: false),
        ),
        const SizedBox(height: 24),
        _InfoCard(
          children: [
            if (profile.phoneNumber?.isNotEmpty == true)
              _InfoRow(label: '전화번호', value: profile.phoneNumber!),
            _InfoRow(label: '환자번호', value: profile.patientNumber),
            _InfoRow(label: '소속병원', value: profile.hospitalName),
            _InfoRow(
              label: '담당 의료진',
              value: profile.assignedDoctorId?.isNotEmpty == true
                  ? '등록됨'
                  : '미등록',
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: AppButton(
                text: '취소',
                isOutlined: true,
                onPressed: onCancel,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton(
                key: const ValueKey('patient-profile-save-button'),
                text: '저장',
                isLoading: isSaving,
                onPressed: canSave ? onSave : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});
  final PatientProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 38,
            backgroundColor: AppColors.surfaceSoft,
            child: Icon(
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
    );
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
      child: Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index < children.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.isLocked = true,
  });
  final String label;
  final String value;
  final bool isLocked;

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
          if (isLocked) ...[
            const SizedBox(width: 8),
            const Icon(
              Icons.lock_outline_rounded,
              size: 18,
              color: AppColors.textDisabled,
            ),
          ],
        ],
      ),
    );
  }
}

String _displayDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}.$month.$day';
}

String profileGenderLabel(String? gender) {
  switch (gender) {
    case 'male':
      return '남성';
    case 'female':
      return '여성';
    default:
      return '미등록';
  }
}

String profileUpdateErrorMessage(Object? error) {
  if (error is ApiException) {
    if (error.statusCode == 400) return '입력한 정보를 확인해 주세요.';
    if (error.statusCode == 403) return '프로필을 수정할 권한이 없습니다.';
    if (error.statusCode == 404) return '환자 프로필을 찾을 수 없습니다.';
    if (error.code == 'TIMEOUT') return '서버 응답 시간이 초과되었습니다.';
    if (error.code == 'CONNECTION_ERROR') return '네트워크 연결을 확인해주세요.';
  }
  if (error is FormatException) return '프로필 정보 형식을 확인할 수 없습니다.';
  return '프로필을 수정하지 못했습니다.';
}
