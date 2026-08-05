import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';

class AppointmentCreateScreen extends StatefulWidget {
  const AppointmentCreateScreen({super.key});

  @override
  State<AppointmentCreateScreen> createState() =>
      _AppointmentCreateScreenState();
}

class _AppointmentCreateScreenState
    extends State<AppointmentCreateScreen> {
  final TextEditingController _purposeController =
      TextEditingController();

  final List<String> _departments = [
    '호흡기내과',
    '종양내과',
    '영상의학과',
  ];

  final Map<String, List<String>> _doctors = {
    '호흡기내과': [
      '김호흡 의료진',
      '이정민 의료진',
    ],
    '종양내과': [
      '박종양 의료진',
      '최은서 의료진',
    ],
    '영상의학과': [
      '정영상 의료진',
      '한유진 의료진',
    ],
  };

  final List<String> _availableTimes = [
  '09:00',
  '09:30',
  '10:00',
  '10:30',
  '11:00',
  '11:30',
  '13:00',
  '13:30',
  '14:00',
  '14:30',
  '15:00',
  '15:30',
  '16:00',
  '16:30',
];

  String? _selectedDepartment;
  String? _selectedDoctor;
  DateTime? _selectedDate;
  String? _selectedTime;

  bool get _canSubmit {
    return _selectedDepartment != null &&
        _selectedDoctor != null &&
        _selectedDate != null &&
        _selectedTime != null &&
        _purposeController.text.trim().isNotEmpty;
  }

  @override
  void dispose() {
    _purposeController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}.$month.$day';
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(
        now.year + 1,
        now.month,
        now.day,
      ),
      helpText: '예약 날짜 선택',
      cancelText: '취소',
      confirmText: '선택',
    );

    if (selectedDate == null) {
      return;
    }

    setState(() {
      _selectedDate = selectedDate;
    });
  }

  Future<void> _submitAppointment() async {
    if (!_canSubmit) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('예약을 신청하시겠습니까?'),
          content: Text(
            '$_selectedDepartment\n'
            '$_selectedDoctor\n'
            '${_formatDate(_selectedDate!)} $_selectedTime',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('신청'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('예약 신청이 완료되었습니다.'),
      ),
    );

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final doctors = _selectedDepartment == null
        ? <String>[]
        : _doctors[_selectedDepartment] ?? <String>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('새 예약 신청'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            120,
          ),
          children: [
            const Text(
              '예약 정보를 입력해주세요.',
              style: AppTextStyles.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '진료과와 의료진, 희망 일정을 선택해주세요.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 28),

            _SectionTitle(
              number: 1,
              title: '진료과 선택',
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedDepartment,
              decoration: const InputDecoration(
                hintText: '진료과를 선택해주세요.',
                prefixIcon: Icon(
                  Icons.local_hospital_outlined,
                ),
              ),
              items: _departments.map((department) {
                return DropdownMenuItem(
                  value: department,
                  child: Text(department),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDepartment = value;
                  _selectedDoctor = null;
                });
              },
            ),
            const SizedBox(height: 24),

            _SectionTitle(
              number: 2,
              title: '의료진 선택',
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedDoctor,
              decoration: const InputDecoration(
                hintText: '의료진을 선택해주세요.',
                prefixIcon: Icon(
                  Icons.person_outline_rounded,
                ),
              ),
              items: doctors.map((doctor) {
                return DropdownMenuItem(
                  value: doctor,
                  child: Text(doctor),
                );
              }).toList(),
              onChanged: _selectedDepartment == null
                  ? null
                  : (value) {
                      setState(() {
                        _selectedDoctor = value;
                      });
                    },
            ),
            const SizedBox(height: 24),

            _SectionTitle(
              number: 3,
              title: '예약 날짜',
            ),
            const SizedBox(height: 12),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _selectDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  prefixIcon: Icon(
                    Icons.calendar_month_outlined,
                  ),
                  suffixIcon: Icon(
                    Icons.chevron_right_rounded,
                  ),
                ),
                child: Text(
                  _selectedDate == null
                      ? '예약 날짜를 선택해주세요.'
                      : _formatDate(_selectedDate!),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: _selectedDate == null
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            _SectionTitle(
              number: 4,
              title: '예약 시간',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _availableTimes.map((time) {
                return ChoiceChip(
                  label: Text(time),
                  selected: _selectedTime == time,
                  onSelected: (selected) {
                    setState(() {
                      _selectedTime = selected ? time : null;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            _SectionTitle(
              number: 5,
              title: '진료 목적',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _purposeController,
              maxLines: 4,
              maxLength: 200,
              decoration: const InputDecoration(
                hintText: '예: 검사 결과 상담, 치료 경과 확인',
                alignLabelWithHint: true,
              ),
              onChanged: (_) {
                setState(() {});
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(
                color: AppColors.border,
              ),
            ),
          ),
          child: FilledButton(
            onPressed:
                _canSubmit ? _submitAppointment : null,
            child: const Padding(
              padding: EdgeInsets.symmetric(
                vertical: 15,
              ),
              child: Text('예약 신청하기'),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.number,
    required this.title,
  });

  final int number;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}