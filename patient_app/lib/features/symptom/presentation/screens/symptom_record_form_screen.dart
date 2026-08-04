import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../data/models/symptom_record.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/symptom_medication_provider.dart';

class SymptomRecordFormScreen extends ConsumerStatefulWidget {
  const SymptomRecordFormScreen({super.key});

  @override
  ConsumerState<SymptomRecordFormScreen> createState() =>
      _SymptomRecordFormScreenState();
}

class _SymptomRecordFormScreenState
    extends ConsumerState<SymptomRecordFormScreen> {
  final TextEditingController _memoController = TextEditingController();

  final Map<String, int> _selectedSymptoms = {
    '기침': 0,
    '호흡곤란': 0,
    '가슴 통증': 0,
    '피로': 0,
    '발열': 0,
    '가래': 0,
  };

  int _overallSeverity = 0;
  bool _isSaving = false;

  bool get _hasSelectedSymptom {
    return _selectedSymptoms.values.any(
      (severity) => severity > 0,
    );
  }

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  String _severityText(int severity) {
    switch (severity) {
      case 1:
        return '경미';
      case 2:
        return '보통';
      case 3:
        return '심함';
      default:
        return '없음';
    }
  }

  Future<void> _saveRecord() async {
    if (!_hasSelectedSymptom) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('한 가지 이상의 증상을 선택해주세요.'),
        ),
      );
      return;
    }

    if (_overallSeverity == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('전반적인 증상 정도를 선택해주세요.'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final symptoms = _selectedSymptoms.entries
        .where((entry) => entry.value > 0)
        .map(
          (entry) => SymptomItem(
            name: entry.key,
            severity: entry.value,
          ),
        )
        .toList();

    final record = SymptomRecord(
      id: 'symptom-${DateTime.now().millisecondsSinceEpoch}',
      recordedAt: DateTime.now(),
      symptoms: symptoms,
      overallSeverity: _overallSeverity,
      memo: _memoController.text.trim(),
    );

    await ref
        .read(symptomRecordsProvider.notifier)
        .addRecord(record);

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });

    final resultState = ref.read(symptomRecordsProvider);

    if (resultState.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('증상 기록 저장에 실패했습니다.'),
        ),
      );
      return;
    }

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('증상 기록'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            40,
          ),
          children: [
            const Text(
              '오늘 느낀 증상을 선택해주세요',
              style: AppTextStyles.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '증상별로 느낀 정도를 선택할 수 있습니다.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            ..._selectedSymptoms.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _SymptomSelectionCard(
                  symptomName: entry.key,
                  selectedSeverity: entry.value,
                  severityText: _severityText,
                  onChanged: (severity) {
                    setState(() {
                      _selectedSymptoms[entry.key] = severity;
                    });
                  },
                ),
              );
            }),

            const SizedBox(height: 16),

            const Text(
              '전반적인 증상 정도',
              style: AppTextStyles.headlineMedium,
            ),
            const SizedBox(height: 14),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(3, (index) {
                final severity = index + 1;
                final isSelected = _overallSeverity == severity;

                return ChoiceChip(
                  label: Text(_severityText(severity)),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      _overallSeverity = severity;
                    });
                  },
                );
              }),
            ),

            const SizedBox(height: 28),

            const Text(
              '메모',
              style: AppTextStyles.headlineMedium,
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _memoController,
              minLines: 4,
              maxLines: 6,
              maxLength: 300,
              decoration: const InputDecoration(
                hintText: '증상이 시작된 시간이나 특이사항을 입력해주세요.',
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 24),

            AppButton(
              text: '기록 저장',
              isLoading: _isSaving,
              onPressed: _isSaving ? null : _saveRecord,
            ),
          ],
        ),
      ),
    );
  }
}

class _SymptomSelectionCard extends StatelessWidget {
  const _SymptomSelectionCard({
    required this.symptomName,
    required this.selectedSeverity,
    required this.severityText,
    required this.onChanged,
  });

  final String symptomName;
  final int selectedSeverity;
  final String Function(int severity) severityText;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selectedSeverity > 0
              ? AppColors.primary
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            symptomName,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(4, (index) {
              final severity = index;
              final isSelected = selectedSeverity == severity;

              return ChoiceChip(
                label: Text(severityText(severity)),
                selected: isSelected,
                onSelected: (_) {
                  onChanged(severity);
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}