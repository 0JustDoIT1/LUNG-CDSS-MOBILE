import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../models/appointment.dart';
import '../../models/review_case.dart';
import '../case_detail_screen.dart';
import '../patient_detail_screen.dart';

/// 탭 3(중앙): 홈 대시보드.
/// 디자인 시안 반영 — 인사말 + 요약카드 2개 + 즐겨찾기 케이스 + 최근 검토대기.
/// TODO: 실제 연결 시 아래 mock 데이터를 실데이터로 교체.

class DoctorHomeTab extends StatelessWidget {
  final ValueChanged<int> onNavigateToTab;

  const DoctorHomeTab({super.key, required this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GreetingHeader(),
            const SizedBox(height: 16),
            _SummaryRow(onNavigateToTab: onNavigateToTab),
            const SizedBox(height: 16),
            const _NextAppointmentCard(),
            const SizedBox(height: 24),
            _SectionTitle('즐겨찾기 케이스', icon: Icons.star, color: AppTheme.gradientStart),
            const SizedBox(height: 8),
            _FavoriteCaseTile(name: '홍길동', type: 'LUAD'),
            const SizedBox(height: 8),
            _FavoriteCaseTile(name: '이순신', type: 'LUSC'),
            const SizedBox(height: 24),
            _SectionTitle('최근 검토대기', icon: Icons.pending_actions, color: AppTheme.gradientEnd),
            const SizedBox(height: 8),
            _RecentCaseTile(
              name: '최민수',
              confidence: 68,
              urgent: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.medical_services, color: const Color.fromARGB(255, 0, 110, 255), size: 22),
            const SizedBox(width: 6),
            const Text(
              '김의사님',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '오늘의 검토대기·예약 현황',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final ValueChanged<int> onNavigateToTab;

  const _SummaryRow({required this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _SummaryCard(
              title: '검토대기',
              value: '7건',
              subtitle: '긴급 2건 포함',
              cardColor: AppTheme.gradientEnd,
              onTap: () => onNavigateToTab(0), // 케이스(검토대기) 탭
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SummaryCard(
              title: '오늘 예약',
              value: '12건',
              subtitle: null,
              cardColor: AppTheme.gradientStart,
              onTap: () => onNavigateToTab(1), // 일정 탭
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final Color cardColor;
  final VoidCallback onTap;

  const _SummaryCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.cardColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cardColor, // 색을 여기(Material)에 줘야 그 위에 리플/호버가 보임
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      shadowColor: cardColor.withValues(alpha: 0.5),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        hoverColor: Colors.white.withValues(alpha: 0.12),
        splashColor: Colors.white.withValues(alpha: 0.2),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle ?? ' ',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
              const Positioned(
                top: 0,
                right: 0,
                child: Icon(Icons.chevron_right, color: Colors.white70, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 오늘의 다음 진료 — 가장 가까운 예약 1건만 크게 강조해서 보여줌.
/// TODO: 실제 연결 시 _mockNextAppointment 대신 오늘 예약 중 가장 가까운 건으로 교체.

class _NextAppointmentCard extends StatelessWidget {
  const _NextAppointmentCard();

  DateTime get _mockNextAppointment => DateTime.now().add(const Duration(minutes: 30));

  String _countdownLabel(DateTime target) {
    final diff = target.difference(DateTime.now());
    if (diff.isNegative) return '진행중';
    if (diff.inMinutes < 1) return '곧 시작';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 후';
    final hours = diff.inMinutes ~/ 60;
    final mins = diff.inMinutes % 60;
    return mins == 0 ? '$hours시간 후' : '$hours시간 $mins분 후';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final appointment = _mockNextAppointment;
    final dateLabel =
        '${appointment.month}월 ${appointment.day}일 (${weekdays[appointment.weekday - 1]})';
    String two(int n) => n.toString().padLeft(2, '0');
    final timeLabel = '${two(appointment.hour)}:${two(appointment.minute)}';

    // 간호사 쪽과 동일한 연한 배경 및 톤온톤 컬러 설정
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
          // 1. 상단 연한 헤더 띠
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
                  '오늘의 다음 진료',
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
                    _countdownLabel(appointment),
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

          // 2. 카드 본문 (시간 & 환자명)
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
                      '진료 환자',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '홍길동 님',
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
class _SectionTitle extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;

  const _SectionTitle(this.text, {required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _FavoriteCaseTile extends StatelessWidget {
  final String name;
  final String type;

  const _FavoriteCaseTile({required this.name, required this.type});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: ListTile(
        leading: const Icon(Icons.star, color: Colors.amber, size: 22),
        title: Text(name),
        trailing: Chip(
          label: Text(type),
          backgroundColor: Colors.blue.shade50,
          labelStyle: TextStyle(color: Colors.blue.shade700, fontSize: 12),
          side: BorderSide.none,
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PatientDetailScreen(patientName: name),
            ),
          );
        },
      ),
    );
  }
}

class _RecentCaseTile extends StatelessWidget {
  final String name;
  final int confidence;
  final bool urgent;

  const _RecentCaseTile({
    required this.name,
    required this.confidence,
    required this.urgent,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: ListTile(
        leading: Icon(Icons.pending_actions, color: AppTheme.gradientEnd, size: 22),
        title: Text(name),
        subtitle: Text('신뢰도 $confidence%'),
        trailing: urgent
            ? Chip(
                label: const Text('긴급'),
                backgroundColor: Colors.red.shade50,
                labelStyle: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                side: BorderSide.none,
              )
            : null,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CaseDetailScreen(
                reviewCase: ReviewCase(
                  id: 'home-recent',
                  patientName: name,
                  type: CaseType.luad,
                  confidence: confidence / 100,
                  aiSummary: 'LUAD(폐선암) 의심',
                  status: CaseStatus.pending,
                  submittedAt: DateTime.now(),
                  aiOpinion: '신뢰도가 낮아 재검토가 필요합니다.',
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}