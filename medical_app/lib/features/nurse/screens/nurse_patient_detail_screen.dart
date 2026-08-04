import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../mock/patient_overview_mock.dart';
import '../models/patient_overview.dart';
import 'care_plan_medication_screen.dart';

/// 환자 상세(간호사용).
/// - 오늘 복약체크 상태 (읽기전용, 환자앱에서 체크한 데이터가 넘어오는 지점)
/// - 미복용 항목별로 환자에게 복약알림 전송 가능
/// - 복약스케줄 설정 진입 버튼
///
/// TODO: 실제 연결 시 mockNursePatientOverview() 대신 API로 교체.
class NursePatientDetailScreen extends StatelessWidget {
  final String patientName;

  const NursePatientDetailScreen({super.key, required this.patientName});

  String _timeLabel(TimeOfDay t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.hour)}:${two(t.minute)}';
  }

  Future<void> _sendReminder(BuildContext context, String name, TimeOfDay time) async {
    final timeLabel = _timeLabel(time);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('복약 알림을 보내시겠어요?'),
        content: Text('$name님에게 $timeLabel 약 복용 알림을 전송합니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.gradientEnd),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('전송'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$timeLabel 복약 알림을 보냈어요')),
      );
      // TODO: 환자 앱으로 복약알림 FCM 발송 API 연결
    }
  }

  @override
  Widget build(BuildContext context) {
    final overview = mockNursePatientOverview(patientName);

    return Scaffold(
      appBar: AppBar(title: Text('${overview.name} 상세')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('오늘 복약체크', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (!overview.hasSchedule)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                '아직 복약스케줄이 설정되지 않았어요',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            )
          else
            Column(
              children: overview.todayDoses.map((dose) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: dose.taken ? Colors.grey.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: dose.taken ? Colors.grey.shade200 : Colors.orange.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        dose.taken ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: dose.taken ? Colors.green.shade600 : Colors.orange.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(_timeLabel(dose.time), style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Text(
                        dose.taken ? '복용완료' : '미복용',
                        style: TextStyle(
                          fontSize: 12,
                          color: dose.taken ? Colors.grey.shade600 : Colors.orange.shade700,
                        ),
                      ),
                      const Spacer(),
                      if (!dose.taken)
                        TextButton.icon(
                          onPressed: () => _sendReminder(context, overview.name, dose.time),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.orange.shade800,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          ),
                          icon: const Icon(Icons.notifications_active_outlined, size: 16),
                          label: const Text('알림보내기', style: TextStyle(fontSize: 12)),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.gradientEnd,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CarePlanMedicationScreen(patientName: overview.name),
                  ),
                );
              },
              icon: const Icon(Icons.medication_outlined),
              label: const Text('복약스케줄 설정'),
            ),
          ),
        ],
      ),
    );
  }
}