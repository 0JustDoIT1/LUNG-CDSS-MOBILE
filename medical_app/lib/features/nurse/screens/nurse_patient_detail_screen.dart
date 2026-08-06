import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/auth_api.dart';
import '../../../core/api/medications_api.dart';
import '../../../core/auth/session_controller.dart';
import '../../../core/theme/app_theme.dart';
import 'care_plan_medication_screen.dart';

/// 환자 상세(간호사용). 실제 API(GET /api/medications/logs/today/?patient_id=) 연동됨.
/// - 오늘 복약체크 상태 (읽기전용, 환자앱에서 체크한 데이터가 넘어오는 지점)
/// - 미복용 항목별로 환자에게 복약알림 전송 가능(POST /api/medications/reminders/)
/// - 복약스케줄 설정 진입 버튼
class NursePatientDetailScreen extends StatefulWidget {
  final String patientId;
  final String patientName;

  const NursePatientDetailScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<NursePatientDetailScreen> createState() => _NursePatientDetailScreenState();
}

class _NursePatientDetailScreenState extends State<NursePatientDetailScreen> {
  List<MedicationLog>? _logs;
  String? _errorMessage;
  bool _isLoading = true;
  String? _sendingLogId; // 알림 전송 중인 로그(중복 탭 방지 + 로딩 표시)
  final Set<String> _sentReminderLogIds = {}; // 이 화면에 있는 동안 전송 완료한 로그(재전송 방지 표시용)

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
    final token = context.read<SessionController>().accessToken;
    if (token == null) return;

    try {
      final logs = await fetchTodayMedicationLogs(accessToken: token, patientId: widget.patientId);
      logs.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
      if (!mounted) return;
      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    }
  }

  String _timeLabel(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.hour)}:${two(t.minute)}';
  }

  Future<void> _sendReminder(MedicationLog log) async {
    final timeLabel = _timeLabel(log.scheduledTime);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('복약 알림을 보내시겠어요?'),
        content: Text('${widget.patientName}님에게 $timeLabel ${log.drugName} 복용 알림을 전송합니다.'),
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

    if (confirmed != true || !mounted) return;

    final token = context.read<SessionController>().accessToken;
    if (token == null) return;

    setState(() => _sendingLogId = log.id);
    try {
      await sendMedicationReminder(
        patientId: widget.patientId,
        message: '$timeLabel ${log.drugName} 복용 시간이 지났습니다. 약을 복용해 주세요.',
        accessToken: token,
      );
      if (!mounted) return;
      setState(() => _sentReminderLogIds.add(log.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$timeLabel 복약 알림을 보냈어요')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _sendingLogId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.patientName} 상세')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('오늘 복약체크', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        if (_isLoading)
          const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
        else if (_errorMessage != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_errorMessage!, style: TextStyle(color: colorScheme.onSurfaceVariant)),
                const SizedBox(height: 8),
                TextButton(onPressed: _load, child: const Text('다시 시도')),
              ],
            ),
          )
        else if ((_logs ?? []).isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Text(
              '아직 복약스케줄이 설정되지 않았어요',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          )
        else
          Column(
            children: _logs!.map((log) {
              final isSending = _sendingLogId == log.id;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: log.taken ? colorScheme.surfaceContainerHighest : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: log.taken ? Theme.of(context).dividerColor : Colors.orange.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      log.taken ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: log.taken ? Colors.green.shade600 : Colors.orange.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(_timeLabel(log.scheduledTime), style: const TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${log.drugName} · ${log.dosage}',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            log.taken ? '복용완료' : '미복용',
                            style: TextStyle(
                              fontSize: 12,
                              color: log.taken ? colorScheme.onSurfaceVariant : Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!log.taken)
                      if (isSending)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else if (_sentReminderLogIds.contains(log.id))
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check, size: 14, color: colorScheme.onSurfaceVariant),
                            const SizedBox(width: 2),
                            Text(
                              '전송됨',
                              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                            ),
                          ],
                        )
                      else
                        TextButton.icon(
                          onPressed: () => _sendReminder(log),
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
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CarePlanMedicationScreen(
                    patientId: widget.patientId,
                    patientName: widget.patientName,
                  ),
                ),
              );
              _load(); // 스케줄이 새로 생겼을 수 있으니 새로고침
            },
            icon: const Icon(Icons.medication_outlined),
            label: const Text('복약스케줄 설정'),
          ),
        ),
      ],
    );
  }
}
