import 'package:flutter/material.dart';

import '../mock/doctor_profile_mock.dart';
import '../models/doctor_profile.dart';

/// 내 프로필 설정.
/// - 프로필사진: 업로드/변경 (GCS → DoctorProfile.photo_url)
/// - 전문분야 태그: 자유 태그 추가/삭제 (DoctorProfile.specialty_tags)
/// - 기본정보: 이름, 소속병원, 과, 면허번호(확인 상태만 표시, 읽기전용)
///
/// TODO: 실제 연결 시 사진 업로드는 image_picker + GCS 업로드 API 연결,
/// 태그/저장은 DoctorProfile 수정 API 연결.
class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  late DoctorProfile _profile = mockDoctorProfile();

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
    if (_profile.specialtyTags.contains(text)) return;

    setState(() {
      _profile = _profile.copyWith(
        specialtyTags: [..._profile.specialtyTags, text],
      );
    });
  }

  void _removeTag(String tag) {
    setState(() {
      _profile = _profile.copyWith(
        specialtyTags: _profile.specialtyTags.where((t) => t != tag).toList(),
      );
    });
  }

  void _changePhoto() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('사진 변경은 API 연결 후 지원돼요')),
    );
    // TODO: image_picker로 사진 선택 → GCS 업로드 → photo_url 갱신
  }

  void _save() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('프로필이 저장됐어요')),
    );
    // TODO: DoctorProfile 저장 API 연결
  }

  @override
  Widget build(BuildContext context) {
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
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _InfoRow(label: '이름', value: _profile.name),
                        const SizedBox(height: 12),
                        _InfoRow(label: '소속병원', value: _profile.hospital),
                        const SizedBox(height: 12),
                        _InfoRow(label: '진료과', value: _profile.department),
                        const SizedBox(height: 12),
                        _InfoRow(label: '면허번호', value: '확인완료', muted: true),
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
                      ..._profile.specialtyTags.map(
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
                            color: Colors.grey.shade400,
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
                  onPressed: _save,
                  child: const Text('저장'),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: muted ? Colors.grey.shade500 : Colors.black87,
          ),
        ),
      ],
    );
  }
}