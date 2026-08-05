import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/app_button.dart';
import '../../data/models/symptom_submit_request.dart';
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
  final Map<String, String?> _values = <String, String?>{
    'cough': null,
    'dyspnea': null,
    'hemoptysis': null,
    'chestPain': null,
    'fever': null,
    'weightLoss': null,
    'appetite': null,
    'fatigue': null,
  };

  bool get _isComplete => _values.values.every((value) => value != null);

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_isComplete) {
      return;
    }

    final request = SymptomSubmitRequest(
      cough: _values['cough']!,
      dyspnea: _values['dyspnea']!,
      hemoptysis: _values['hemoptysis']!,
      chestPain: _values['chestPain']!,
      fever: _values['fever']!,
      weightLoss: _values['weightLoss']!,
      appetite: _values['appetite']!,
      fatigue: _values['fatigue']!,
    );

    try {
      await ref.read(symptomSubmitProvider.notifier).submit(request);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('증상 정보가 제출되었습니다.')));
      context.pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage(error))));
    }
  }

  static String _errorMessage(Object error) {
    if (error is ApiException) {
      if (error.statusCode == 400) {
        return '입력한 증상 정보를 확인해 주세요.';
      }
      if (error.statusCode == 401) {
        return '인증 정보가 만료됐거나 유효하지 않습니다.';
      }
      if (error.statusCode == 403) {
        return '증상 정보를 제출할 권한이 없습니다.';
      }
      if (error.code == 'TIMEOUT') {
        return '요청 시간이 초과되었습니다.';
      }
      if (error.code == 'CONNECTION_ERROR') {
        return '네트워크 연결을 확인해 주세요.';
      }
    }
    return '증상 정보를 제출하지 못했습니다.';
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref.watch(symptomSubmitProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('증상 체크')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            const Text('현재 증상을 모두 선택해주세요', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 8),
            Text(
              '각 항목은 서버에서 허용하는 선택지로 제출됩니다.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            _selection('기침', 'cough', SymptomSubmitRequest.coughValues),
            _selection('호흡곤란', 'dyspnea', SymptomSubmitRequest.dyspneaValues),
            _selection(
              '객혈',
              'hemoptysis',
              SymptomSubmitRequest.hemoptysisValues,
            ),
            _selection('흉통', 'chestPain', SymptomSubmitRequest.chestPainValues),
            _selection('발열', 'fever', SymptomSubmitRequest.feverValues),
            _selection(
              '체중 감소',
              'weightLoss',
              SymptomSubmitRequest.weightLossValues,
            ),
            _selection('식욕', 'appetite', SymptomSubmitRequest.appetiteValues),
            _selection('피로', 'fatigue', SymptomSubmitRequest.fatigueValues),
            const SizedBox(height: 12),
            const Text('메모', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 8),
            Text(
              '메모는 이번 증상 제출 API에 포함되지 않습니다.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _memoController,
              minLines: 3,
              maxLines: 5,
              maxLength: 300,
              decoration: const InputDecoration(hintText: '개인 메모를 입력할 수 있습니다.'),
            ),
            const SizedBox(height: 24),
            AppButton(
              text: '증상 제출',
              isLoading: isSubmitting,
              onPressed: !_isComplete || isSubmitting ? null : _submit,
            ),
            if (!_isComplete) ...[
              const SizedBox(height: 10),
              Text(
                '모든 증상 항목을 선택해 주세요.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _selection(String title, String key, Set<String> options) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _values[key] == null ? AppColors.border : AppColors.primary,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options.map((option) {
                return ChoiceChip(
                  label: Text(option),
                  selected: _values[key] == option,
                  onSelected: (_) => setState(() => _values[key] = option),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
