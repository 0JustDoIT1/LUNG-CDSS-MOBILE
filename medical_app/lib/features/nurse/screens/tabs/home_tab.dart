import 'package:flutter/material.dart';

import '../../mock/patient_overview_mock.dart';
import '../../models/patient_overview.dart';
import '../../../../core/theme/app_theme.dart';
import '../care_plan_medication_screen.dart';

/// 탭 3(중앙): 홈 대시보드.
class NurseHomeTab extends StatelessWidget {
  const NurseHomeTab({super.key});
   // '케어' 탭이랑 같은 mock 소스 사용 — 복약확인 필요(needsAttention)한 환자만 필터링
  List<NursePatientOverview> get _needsAttentionPatients =>
      ['홍길동', '이순신', '최민수']
          .map(mockNursePatientOverview)
          .where((o) => o.needsAttention)
          .toList();
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _GreetingHeader(),
            const SizedBox(height: 20),
            const _SummaryRow(),
            const SizedBox(height: 20),
            const _NextVisitCard(),
            const SizedBox(height: 28),
            _buildSectionHeader(context, '케어플랜 처리 필요', icon: Icons.assignment_late_outlined),
            const SizedBox(height: 12),
            const _CarePlanTile(name: '홍길동', subtitle: '치료계획 확정 · 복약설정 대기'),
            const _CarePlanTile(name: '이순신', subtitle: '치료계획 확정 · 복약설정 대기'),
            const SizedBox(height: 28),
            _buildSectionHeader(context, '환자 복약 확인', icon: Icons.warning_amber_rounded, isAlert: true),
            const SizedBox(height: 12),
            for (final overview in _needsAttentionPatients)
              _AlertPatientTile(name: overview.name, subtitle: overview.subtitle),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, {required IconData icon, bool isAlert = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isAlert ? Colors.orange.shade800 : (isDark ? Colors.white70 : Colors.black87);

    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '박간호사님',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(width: 6),
            const Text('👋', style: TextStyle(fontSize: 20)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '오늘의 예약요청·케어플랜 현황입니다.',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: '예약요청 대기',
            value: '5',
            unit: '건',
            icon: Icons.pending_actions_rounded,
            highlighted: true,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: '미방문/방문처리',
            value: '3',
            unit: '건',
            icon: Icons.transfer_within_a_station_rounded,
            highlighted: false,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final bool highlighted;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.highlighted,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 단색 기반의 미니멀 배경 & 라인
    final bgColor = isDark
        ? (highlighted ? const Color(0xFF2C2216) : const Color(0xFF1E293B))
        : (highlighted ? const Color(0xFFFFF7ED) : const Color(0xFFF8FAFC));

    final borderColor = isDark
        ? (highlighted ? Colors.orange.shade800.withOpacity(0.5) : Colors.grey.shade800)
        : (highlighted ? Colors.orange.shade200 : Colors.grey.shade200);

    final accentColor = highlighted ? Colors.orange.shade800 : AppTheme.seed;
    final iconBgColor = highlighted
        ? (isDark ? Colors.orange.shade900.withOpacity(0.3) : Colors.orange.shade100)
        : (isDark ? Colors.grey.shade800 : Colors.grey.shade200);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: accentColor),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey.shade400),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: highlighted
                      ? (isDark ? const Color.fromARGB(255, 255, 192, 105) : Colors.orange.shade900)
                      : (isDark ? Colors.white : Colors.black87),
                ),
              ),
              const SizedBox(width: 2),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 깔끔한 단색 미니멀 '다음 방문 예정' 카드
class _NextVisitCard extends StatelessWidget {
  const _NextVisitCard();

  DateTime get _mockNextVisit => DateTime.now().add(const Duration(minutes: 20));

  String _countdownLabel(DateTime target) {
    final diff = target.difference(DateTime.now());
    if (diff.isNegative) return '진행중';
    if (diff.inMinutes < 1) return '곧 도착';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 후 도착';
    final hours = diff.inMinutes ~/ 60;
    final mins = diff.inMinutes % 60;
    return mins == 0 ? '$hours시간 후' : '$hours시간 $mins분 후';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final visit = _mockNextVisit;
    final dateLabel = '${visit.month}월 ${visit.day}일 (${weekdays[visit.weekday - 1]})';
    String two(int n) => n.toString().padLeft(2, '0');
    final timeLabel = '${two(visit.hour)}:${two(visit.minute)}';

    final cardBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final headerBgColor = isDark ? AppTheme.seed.withOpacity(0.15) : AppTheme.seed.withOpacity(0.08);
    final borderColor = isDark ? AppTheme.seed.withOpacity(0.4) : AppTheme.seed.withOpacity(0.3);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        children: [
          // 1. 헤더 영역
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: headerBgColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time_filled_rounded, color: AppTheme.seed, size: 18),
                const SizedBox(width: 6),
                const Text(
                  '다음 방문 예정',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.seed,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.seed,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    _countdownLabel(visit),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. 본문 영역
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timeLabel,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '방문 대상',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '이순신 님',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CarePlanTile extends StatelessWidget {
  final String name;
  final String subtitle;

  const _CarePlanTile({required this.name, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          width: 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CarePlanMedicationScreen(patientName: name),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade500,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AlertPatientTile extends StatelessWidget {
  final String name;
  final String subtitle;

  const _AlertPatientTile({required this.name, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          width: 1.0,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
          child: Icon(Icons.person_rounded, size: 20, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
        ),
        title: Text(
          name,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.redAccent.shade400,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            '확인필요',
            style: TextStyle(
              color: Colors.redAccent,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}