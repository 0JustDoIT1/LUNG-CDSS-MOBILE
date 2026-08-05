import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/models/appointment_booking.dart';
import '../providers/appointment_provider.dart';

class AppointmentCreateScreen extends ConsumerStatefulWidget {
  const AppointmentCreateScreen({super.key});

  @override
  ConsumerState<AppointmentCreateScreen> createState() =>
      _AppointmentCreateScreenState();
}

class _AppointmentCreateScreenState
    extends ConsumerState<AppointmentCreateScreen> {
  final _purposeController = TextEditingController();

  @override
  void dispose() {
    _purposeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 1, now.month, now.day),
      helpText: '예약 날짜 선택',
      cancelText: '취소',
      confirmText: '선택',
    );
    if (selected != null) {
      await ref.read(appointmentBookingProvider.notifier).selectDate(selected);
    }
  }

  Future<void> _submit() async {
    final state = ref.read(appointmentBookingProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('선택한 일정으로 예약을 신청하시겠습니까?'),
        content: Text(
          '${state.selectedDepartment!.name}\n'
          '${state.selectedDoctor!.name}\n'
          '${_date(state.selectedDate!)} ${state.selectedSlot!.time}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('신청'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final success = await ref
        .read(appointmentBookingProvider.notifier)
        .submit();
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('예약이 신청되었습니다.')));
      context.pop();
      return;
    }
    final error = ref.read(appointmentBookingProvider).lastError;
    if (error is ApiException && error.statusCode == 409) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('선택한 시간이 마감되었습니다.'),
          content: const Text('다른 사용자가 먼저 예약했을 수 있습니다. 다른 시간을 선택해 주세요.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('확인'),
            ),
          ],
        ),
      );
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(_error(error))));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appointmentBookingProvider);
    final canSubmit =
        state.selectedDepartment != null &&
        state.selectedDoctor != null &&
        state.selectedDate != null &&
        state.selectedSlot?.status == 'available' &&
        !state.isSubmitting;

    return Scaffold(
      appBar: AppBar(title: const Text('새 예약 신청')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          children: [
            const Text('예약 정보를 입력해주세요.', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 8),
            Text(
              '진료과와 의료진, 희망 일정을 선택해주세요.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 28),
            const _SectionTitle(number: 1, title: '진료과 선택'),
            const SizedBox(height: 12),
            state.departments.when(
              loading: () => const _LoadingBox(),
              error: (_, _) => _RetryBox(
                label: '진료과를 불러오지 못했습니다.',
                onRetry: ref
                    .read(appointmentBookingProvider.notifier)
                    .loadDepartments,
              ),
              data: (items) => items.isEmpty
                  ? const _MessageBox('선택 가능한 진료과가 없습니다.')
                  : DropdownButtonFormField<AppointmentDepartment>(
                      initialValue: state.selectedDepartment,
                      hint: const Text('진료과를 선택해주세요.'),
                      items: items
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          ref
                              .read(appointmentBookingProvider.notifier)
                              .selectDepartment(value);
                        }
                      },
                    ),
            ),
            const SizedBox(height: 24),
            const _SectionTitle(number: 2, title: '의료진 선택'),
            const SizedBox(height: 12),
            if (state.selectedDepartment == null)
              const _MessageBox('진료과를 먼저 선택해주세요.')
            else
              state.doctors.when(
                loading: () => const _LoadingBox(),
                error: (_, _) => _RetryBox(
                  label: '의료진을 불러오지 못했습니다.',
                  onRetry: () => ref
                      .read(appointmentBookingProvider.notifier)
                      .selectDepartment(state.selectedDepartment!),
                ),
                data: (items) => items.isEmpty
                    ? const _MessageBox('선택 가능한 의료진이 없습니다.')
                    : Column(
                        children: items
                            .map(
                              (doctor) => _DoctorCard(
                                doctor: doctor,
                                selected: state.selectedDoctor?.id == doctor.id,
                                onTap: () => ref
                                    .read(appointmentBookingProvider.notifier)
                                    .selectDoctor(doctor),
                              ),
                            )
                            .toList(),
                      ),
              ),
            const SizedBox(height: 24),
            const _SectionTitle(number: 3, title: '예약 날짜'),
            const SizedBox(height: 12),
            InkWell(
              onTap: state.selectedDoctor == null ? null : _selectDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.calendar_month_outlined),
                  suffixIcon: Icon(Icons.chevron_right_rounded),
                ),
                child: Text(
                  state.selectedDate == null
                      ? '예약 날짜를 선택해주세요.'
                      : _date(state.selectedDate!),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const _SectionTitle(number: 4, title: '예약 시간'),
            const SizedBox(height: 12),
            if (state.selectedDate == null)
              const _MessageBox('날짜를 먼저 선택해주세요.')
            else
              state.slots.when(
                loading: () => const _LoadingBox(),
                error: (_, _) => _RetryBox(
                  label: '예약 시간을 불러오지 못했습니다.',
                  onRetry: () => ref
                      .read(appointmentBookingProvider.notifier)
                      .selectDate(state.selectedDate!),
                ),
                data: (result) => result == null || result.slots.isEmpty
                    ? const _MessageBox('선택 가능한 예약 시간이 없습니다.')
                    : Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: result.slots.map((slot) {
                          final available = slot.status == 'available';
                          return ChoiceChip(
                            label: Text(
                              available ? slot.time : '${slot.time} 마감',
                            ),
                            selected:
                                state.selectedSlot?.dateTime == slot.dateTime,
                            onSelected: available
                                ? (_) => ref
                                      .read(appointmentBookingProvider.notifier)
                                      .selectSlot(slot)
                                : null,
                          );
                        }).toList(),
                      ),
              ),
            const SizedBox(height: 24),
            const _SectionTitle(number: 5, title: '진료 목적'),
            const SizedBox(height: 12),
            TextField(
              controller: _purposeController,
              maxLines: 4,
              maxLength: 200,
              decoration: const InputDecoration(
                hintText: '예: 검사 결과 상담, 치료 경과 확인',
                helperText: '현재 예약 API 요청에는 포함되지 않습니다.',
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: FilledButton(
            onPressed: canSubmit ? _submit : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: state.isSubmitting
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('예약 신청하기'),
            ),
          ),
        ),
      ),
    );
  }

  static String _date(DateTime date) =>
      '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  static String _error(Object? error) {
    if (error is ApiException) {
      if (error.statusCode == 400) return '예약 정보를 확인해 주세요.';
      if (error.statusCode == 403) return '예약을 신청할 권한이 없습니다.';
      if (error.code == 'TIMEOUT') return '요청 시간이 초과되었습니다.';
      if (error.code == 'CONNECTION_ERROR') return '네트워크 연결을 확인해 주세요.';
    }
    return '예약을 신청하지 못했습니다.';
  }
}

class _DoctorCard extends StatelessWidget {
  const _DoctorCard({
    required this.doctor,
    required this.selected,
    required this.onTap,
  });
  final AppointmentDoctor doctor;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      onTap: onTap,
      selected: selected,
      leading: const CircleAvatar(child: Icon(Icons.person_outline)),
      title: Row(
        children: [
          Text(doctor.name),
          if (doctor.isAssigned) ...[
            const SizedBox(width: 8),
            const Chip(label: Text('담당 의료진')),
          ],
        ],
      ),
      subtitle: Text([doctor.department, ...doctor.specialtyTags].join(' · ')),
      trailing: selected
          ? const Icon(Icons.check_circle, color: AppColors.primary)
          : null,
    ),
  );
}

class _LoadingBox extends StatelessWidget {
  const _LoadingBox();
  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 64,
    child: Center(child: CircularProgressIndicator()),
  );
}

class _MessageBox extends StatelessWidget {
  const _MessageBox(this.message);
  final String message;
  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.all(16), child: Text(message));
}

class _RetryBox extends StatelessWidget {
  const _RetryBox({required this.label, required this.onRetry});
  final String label;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(label)),
      TextButton(onPressed: onRetry, child: const Text('다시 시도')),
    ],
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.number, required this.title});
  final int number;
  final String title;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      CircleAvatar(
        radius: 14,
        backgroundColor: AppColors.primary,
        child: Text('$number', style: const TextStyle(color: Colors.white)),
      ),
      const SizedBox(width: 10),
      Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
      ),
    ],
  );
}
