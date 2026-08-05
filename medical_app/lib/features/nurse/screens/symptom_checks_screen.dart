import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/auth_api.dart';
import '../../../core/api/symptoms_api.dart';
import '../../../core/auth/session_controller.dart';

/// 증상 위험 신호 목록. 실제 API(GET /api/symptoms/checks/nurse-visible/) 연동됨.
/// RED/YELLOW 등급 + 열람허용된 항목이 옴. "확인" 누르면 서버에 확인처리 기록.
class SymptomChecksScreen extends StatefulWidget {
  const SymptomChecksScreen({super.key});

  @override
  State<SymptomChecksScreen> createState() => _SymptomChecksScreenState();
}

class _SymptomChecksScreenState extends State<SymptomChecksScreen> {
  List<SymptomCheck>? _checks;
  String? _errorMessage;
  bool _isLoading = true;

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
      final list = await fetchNurseVisibleSymptomChecks(token);
      list.sort((a, b) {
        // RED 먼저, 그다음 안읽은 것 먼저, 그다음 최신순
        if (a.isRed != b.isRed) return a.isRed ? -1 : 1;
        if (a.nurseReviewed != b.nurseReviewed) return a.nurseReviewed ? 1 : -1;
        return b.checkedAt.compareTo(a.checkedAt);
      });
      if (!mounted) return;
      setState(() {
        _checks = list;
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

  Future<void> _review(SymptomCheck c) async {
    final token = context.read<SessionController>().accessToken;
    if (token == null) return;
    try {
      await reviewSymptomCheck(c.id, token);
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Color _riskColor(SymptomCheck c) {
    if (c.isRed) return Colors.red;
    if (c.isYellow) return Colors.orange;
    return Colors.green;
  }

  String _riskLabel(SymptomCheck c) {
    if (c.isRed) return 'RED';
    if (c.isYellow) return 'YELLOW';
    return 'GREEN';
  }

  String _timeLabel(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.month}월 ${t.day}일 ${two(t.hour)}:${two(t.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('증상 위험 신호')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_errorMessage!, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            TextButton(onPressed: _load, child: const Text('다시 시도')),
          ],
        ),
      );
    }

    final checks = _checks ?? [];
    if (checks.isEmpty) {
      return const Center(child: Text('위험 신호가 있는 환자가 없어요'));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: checks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final c = checks[index];
          final color = _riskColor(c);
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.nurseReviewed ? Colors.grey.shade50 : color.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: c.nurseReviewed ? Colors.grey.shade200 : color.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _riskLabel(c),
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.patientName, style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        _timeLabel(c.checkedAt),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                if (c.nurseReviewed)
                  Text('확인완료', style: TextStyle(fontSize: 12, color: Colors.grey.shade500))
                else
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: color),
                    onPressed: () => _review(c),
                    child: const Text('확인'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}