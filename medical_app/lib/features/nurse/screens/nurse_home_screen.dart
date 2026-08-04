import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../mock/chat_mock.dart';
import '../mock/notification_mock.dart';
import 'notification_screen.dart';
import 'tabs/chat_tab.dart';
import 'tabs/home_tab.dart';
import 'tabs/patients_tab.dart';
import 'tabs/queue_tab.dart';
import 'tabs/settings_tab.dart';

/// 간호사 홈 셸(shell). 하단 네비게이션으로 5개 탭을 전환한다.
/// 순서: 예약큐 / 담당환자 / 홈(중앙) / 채팅 / 설정
///
/// 상단바는 탭이 바뀌어도 고정 — 좌측 로고+앱이름, 우측 QR/알림 아이콘.
class NurseHomeScreen extends StatefulWidget {
  const NurseHomeScreen({super.key});

  @override
  State<NurseHomeScreen> createState() => _NurseHomeScreenState();
}

class _NurseHomeScreenState extends State<NurseHomeScreen> {
  int _tabIndex = 2; // 앱 시작 시 홈 탭이 기본으로 보이도록

  int get _unreadCount =>
      mockChatThreads().fold(0, (sum, t) => sum + t.unreadCount);

  int get _unreadNotificationCount =>
      mockNotifications().where((n) => !n.isRead).length;

  static const _tabs = [

    QueueTab(),
    NursePatientsTab(),
    NurseHomeTab(),
    NurseChatTab(),
    NurseSettingsTab(),
  ];

  void _scanQr() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('QR 스캔은 카메라 연동 후 지원돼요')),
    );
    // TODO: 카메라로 QR 스캔 → Redis 토큰 검증 → 자동 checked_in 처리
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Image.asset('assets/images/logo.png', width: 22, height: 22),
            const SizedBox(width: 6),
            ShaderMask(
              shaderCallback: (bounds) => AppTheme.brandGradient.createShader(bounds),
              child: const Text(
                '숨-잇',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'QR 스캔',
            onPressed: _scanQr,
            icon: const Icon(Icons.qr_code_scanner),
          ),
          IconButton(
            tooltip: '알림',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationScreen()),
              );
            },
            icon: _unreadNotificationCount > 0
                ? Badge(
                    label: Text('$_unreadNotificationCount'),
                    child: const Icon(Icons.notifications_outlined),
                  )
                : const Icon(Icons.notifications_outlined),
          ),
        ],
      ),
      body: IndexedStack(index: _tabIndex, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: [
          NavigationDestination(icon: Icon(Icons.calendar_month), label: '예약관리'),
          NavigationDestination(icon: Icon(Icons.favorite), label: '케어'),
          NavigationDestination(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                gradient: AppTheme.brandGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.home, color: Colors.white, size: 20),
            ),
            label: '홈',
          ),
          NavigationDestination(
            icon: _unreadCount > 0
                ? Badge(
                    label: Text('$_unreadCount'),
                    child: const Icon(Icons.chat_bubble_outline),
                  )
                : const Icon(Icons.chat_bubble_outline),
            label: '채팅',
          ),
          NavigationDestination(icon: Icon(Icons.menu), label: '메뉴'),
        ],
      ),
    );
  }
}