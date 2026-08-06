import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/auth_api.dart';
import '../../../core/api/communication_api.dart';
import '../../../core/auth/session_controller.dart';
import '../../../core/lifecycle/app_resume_notifier.dart';
import '../../../core/qr/qr_scan_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../main.dart';
import '../models/notification.dart';
import 'notification_screen.dart';
import 'tabs/cases_tab.dart';
import 'tabs/chat_tab.dart';
import 'tabs/home_tab.dart';
import 'tabs/schedule_tab.dart';
import 'tabs/settings_tab.dart';

/// 의사 홈 셸(shell). 하단 네비게이션으로 5개 탭을 전환한다.
/// 순서: 케이스 / 일정 / 홈(중앙) / 채팅 / 메뉴
///
/// 상단바는 탭이 바뀌어도 고정 — 좌측 로고+앱이름, 우측 QR/알림 아이콘.
/// 채팅/알림 안읽음 개수는 실제 API 기반 — 포그라운드 푸시 수신 시 즉시 갱신 +
/// 앱이 백그라운드에서 돌아올 때(resume)도 갱신(놓친 푸시 보정).
class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> with WidgetsBindingObserver {
  int _tabIndex = 2; // 앱 시작 시 홈 탭이 기본으로 보이도록
  int _unreadChatCount = 0;
  int _unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshBadges());
    fcmService.incomingMessage.addListener(_refreshBadges);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    fcmService.incomingMessage.removeListener(_refreshBadges);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshBadges();
      appResumeNotifier.value++; // 각 탭이 백그라운드 동안 놓친 변경사항 보정
    }
  }

  Future<void> _refreshBadges() async {
    final token = context.read<SessionController>().accessToken;
    if (token == null) return;

    try {
      final threads = await fetchChatThreads(token);
      final notifications = await fetchNotifications(token, AppNotification.fromJson);
      if (!mounted) return;
      setState(() {
        _unreadChatCount = threads.fold(0, (sum, t) => sum + t.unreadCount);
        // chat 알림은 알림함 목록에서 제외돼 있어서(채팅탭 뱃지로 따로 표시) 여기서도 빼야 개수가 맞음.
        _unreadNotificationCount =
            notifications.where((n) => !n.isRead && n.type != NotificationType.chat).length;
      });
    } on ApiException catch (_) {
      // 뱃지 갱신 실패는 조용히 무시 (화면 자체는 계속 써야 하니까)
    }
  }

  List<Widget> get _tabs => [
        const CasesTab(),
        const ScheduleTab(),
        DoctorHomeTab(onNavigateToTab: (i) => setState(() => _tabIndex = i)),
        ChatTab(onUnreadChanged: _refreshBadges),
        const SettingsTab(),
      ];

  void _scanQr() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const QrScanScreen()),
    );
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
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => NotificationScreen(
                    onNavigateToTab: (i) => setState(() => _tabIndex = i),
                  ),
                ),
              );
              _refreshBadges();
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
        onDestinationSelected: (i) {
          setState(() => _tabIndex = i);
          if (i == 3) _refreshBadges(); // 채팅탭 들어갈 때 뱃지 갱신
        },
        destinations: [
          NavigationDestination(icon: Icon(Icons.fact_check), label: '검토대기'),
          NavigationDestination(icon: Icon(Icons.calendar_month), label: '일정'),
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
            icon: _unreadChatCount > 0
                ? Badge(
                    label: Text('$_unreadChatCount'),
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