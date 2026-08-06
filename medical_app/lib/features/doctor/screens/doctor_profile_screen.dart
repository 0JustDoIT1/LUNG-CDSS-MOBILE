import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/auth_api.dart';
import '../../../core/auth/session_controller.dart';
import '../models/doctor_profile.dart';

/// 내 프로필 설정. GET /api/auth/doctor/profile/ + GET /api/auth/hospital/ 연동됨.
/// - 프로필사진: 업로드/변경 (GCS → DoctorProfile.photo_url)
/// - 전문분야 태그: 자유 태그 추가/삭제 (DoctorProfile.specialty_tags)
/// - 기본정보: 이름(로그인응답), 소속병원, 진료과·면허번호(서버 조회만 가능, 읽기전용)
///
/// TODO: 실제 연결 시 사진 업로드는 image_picker + GCS 업로드 API 연결.
class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  DoctorProfile? _profile;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final session = context.read<SessionController>();
    final token = session.accessToken;
    if (token == null) return;

    try {
      final results = await Future.wait([fetchDoctorProfile(token), fetchHospital(token)]);
      final profileData = results[0] as DoctorProfileData;
      final hospital = results[1] as Hospital;
      if (!mounted) return;
      setState(() {
        _profile = DoctorProfile(
          name: session.name,
          hospital: hospital.name,
          department: profileData.department,
          licenseNumber: profileData.licenseNumber,
          photoUrl: profileData.photoUrl,
          specialtyTags: profileData.specialtyTags,
        );
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addTag() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('태그 추가'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '예: 폐암클리닉'),
          onSubmitted: (v) => Navigator.of(context).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('추가'),
          ),
        ],
      ),
    );

    final text = result?.trim();
    if (text == null || text.isEmpty) return;
    final profile = _profile;
    if (profile == null || profile.specialtyTags.contains(text)) return;

    setState(() {
      _profile = profile.copyWith(specialtyTags: [...profile.specialtyTags, text]);
    });
  }

  void _removeTag(String tag) {
    final profile = _profile;
    if (profile == null) return;
    setState(() {
      _profile = profile.copyWith(
        specialtyTags: profile.specialtyTags.where((t) => t != tag).toList(),
      );
    });
  }

  void _changePhoto() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('사진 변경은 API 연결 후 지원돼요')),
    );
    // TODO: image_picker로 사진 선택 → GCS 업로드 → photo_url 갱신
  }

  Future<void> _save() async {
    final profile = _profile;
    final token = context.read<SessionController>().accessToken;
    if (profile == null || token == null) return;

    setState(() => _isSaving = true);
    try {
      await updateDoctorProfile(
        accessToken: token,
        specialtyTags: profile.specialtyTags,
        photoUrl: profile.photoUrl,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('프로필이 저장됐어요')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null || _profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('내 프로필 설정')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorMessage ?? '프로필을 불러오지 못했어요.',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              TextButton(onPressed: _load, child: const Text('다시 시도')),
            ],
          ),
        ),
      );
    }

    final profile = _profile!;

    return Scaffold(
      appBar: AppBar(title: const Text('내 프로필 설정')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Center(
                    child: Column(
                      children: [
                        _ProfilePhoto(onTap: _changePhoto),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _changePhoto,
                          child: const Text('사진 변경'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _InfoRow(label: '이름', value: profile.name),
                        const SizedBox(height: 12),
                        _InfoRow(label: '소속병원', value: profile.hospital),
                        const SizedBox(height: 12),
                        _InfoRow(label: '진료과', value: profile.department, muted: true),
                        const SizedBox(height: 12),
                        _InfoRow(label: '면허번호', value: profile.licenseNumber, muted: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('전문분야 태그',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...profile.specialtyTags.map(
                        (tag) => Chip(
                          label: Text(tag),
                          onDeleted: () => _removeTag(tag),
                        ),
                      ),
                      ActionChip(
                        onPressed: _addTag,
                        avatar: const Icon(Icons.add, size: 16),
                        label: const Text('추가'),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.outlineVariant,
                            style: BorderStyle.solid,
                          ),
                        ),
                        backgroundColor: Colors.transparent,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('저장'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfilePhoto extends StatelessWidget {
  final VoidCallback onTap;

  const _ProfilePhoto({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: Colors.blue.shade50,
            child: Icon(Icons.person, size: 48, color: Colors.blue.shade200),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: CircleAvatar(
              radius: 14,
              backgroundColor: Colors.black,
              child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool muted;

  const _InfoRow({required this.label, required this.value, this.muted = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: colorScheme.onSurfaceVariant)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: muted ? colorScheme.onSurfaceVariant : colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}