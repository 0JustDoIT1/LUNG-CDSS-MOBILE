import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/auth/session_controller.dart';
import '../../../../core/security/security_settings_controller.dart';
import '../nurse_app_settings_screen.dart';

/// 탭 5: 메뉴 (설정 / 로그아웃 진입점).
class NurseSettingsTab extends StatelessWidget {
  const NurseSettingsTab({super.key});

  // 포인트 청록 컬러
  static const Color pointColor = Color(0xFF0D9488);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 다크모드 대응 dynamic 컬러
    final cardColor = theme.cardColor;
    final borderColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    final iconBgColor = isDark ? Colors.grey.shade800 : const Color(0xFFF1F5F9);

    return Scaffold(
      backgroundColor: isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('메뉴', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 1. 서비스 메뉴 섹션
          _buildSectionHeader(context, '서비스'),
          Card(
            elevation: 0,
            color: cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: borderColor, width: 1),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: _buildIconBox(Icons.settings_outlined, iconBgColor: iconBgColor),
                  title: const Text('설정', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  subtitle: const Text('화면, 알림 및 위젯 설정'),
                  trailing: Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const NurseAppSettingsScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. 계정 및 로그인 섹션
          _buildSectionHeader(context, '계정'),
          Card(
            elevation: 0,
            color: cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: borderColor, width: 1),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: _buildIconBox(Icons.logout_rounded, isDanger: true, iconBgColor: iconBgColor),
                  title: const Text(
                    '로그아웃',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.redAccent,
                    ),
                  ),
                  trailing: Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
                  onTap: () => _showLogoutDialog(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // 3. 앱 하단 정보
          Center(
            child: Text(
              '앱 버전 v1.0.0',
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// 로그아웃 확인 팝업 모달
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('로그아웃', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('정말 로그아웃 하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                '취소',
                style: TextStyle(color: Theme.of(dialogContext).colorScheme.onSurfaceVariant),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.read<SessionController>().logOut();
                context.read<SecuritySettingsController>().resetUnlock();
              },
              child: const Text('로그아웃', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  /// 아이콘 배경 박스 공통 위젯
  Widget _buildIconBox(IconData icon, {bool isDanger = false, required Color iconBgColor}) {
    final color = isDanger ? Colors.redAccent : pointColor;

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon,
        size: 20,
        color: color,
      ),
    );
  }

  /// 섹션 타이틀
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
      ),
    );
  }
}