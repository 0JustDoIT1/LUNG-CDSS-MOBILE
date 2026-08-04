import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/settings/app_settings_controller.dart';

/// 앱 설정 — 화면표시(테마/화면항상켜짐/글자크기) + 알림(카테고리별 on/off).
class DoctorAppSettingsScreen extends StatelessWidget {
  const DoctorAppSettingsScreen({super.key});

  // 포인트 청록 컬러
  static const Color pointColor = Color(0xFF0D9488);

  /// 알림 카테고리별 아이콘
  IconData _getNotificationIcon(String category) {
    if (category.contains('예약') || category.contains('일정')) {
      return Icons.calendar_today_rounded;
    } else if (category.contains('긴급') || category.contains('비상')) {
      return Icons.error_outline_rounded;
    } else if (category.contains('공지') || category.contains('소식')) {
      return Icons.campaign_rounded;
    } else if (category.contains('메시지') || category.contains('채팅')) {
      return Icons.chat_bubble_outline_rounded;
    }
    return Icons.notifications_none_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 다크모드 대응 dynamic 컬러 정의
    final cardColor = theme.cardColor; // 라이트: 흰색 / 다크: 어두운 그레이
    final borderColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    final iconBgColor = isDark ? Colors.grey.shade800 : const Color(0xFFF1F5F9);

    return Scaffold(
      // 다크모드일 때는 기본 테마 배경색, 라이트일 때는 F8FAFC 적용
      backgroundColor: isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('설정', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 1. 화면표시 설정 섹션
          _buildSectionHeader(context, '화면표시 설정'),
          Card(
            elevation: 0,
            color: cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: borderColor, width: 1),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  activeColor: pointColor,
                  secondary: _buildIconBox(Icons.screen_lock_portrait_rounded, iconBgColor: iconBgColor),
                  title: const Text('화면 항상켜짐', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  subtitle: const Text('케이스검토 중 화면꺼짐 방지'),
                  value: settings.keepScreenOn,
                  onChanged: (v) => settings.setKeepScreenOn(v),
                ),
                Divider(height: 1, indent: 16, endIndent: 16, color: borderColor),

                // 테마 선택 (바텀시트 호출)
                ListTile(
                  leading: _buildIconBox(Icons.brightness_6_rounded, iconBgColor: iconBgColor),
                  title: const Text('테마', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getThemeLabel(settings.themeMode),
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
                    ],
                  ),
                  onTap: () => _showThemePicker(context, settings),
                ),
                Divider(height: 1, indent: 16, endIndent: 16, color: borderColor),

                // 글자 크기 선택 (바텀시트 호출)
                ListTile(
                  leading: _buildIconBox(Icons.format_size_rounded, iconBgColor: iconBgColor),
                  title: const Text('글자 크기', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getFontScaleLabel(settings.fontScale),
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
                    ],
                  ),
                  onTap: () => _showFontScalePicker(context, settings),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 2. 알림 설정 섹션
          _buildSectionHeader(context, '알림 설정'),
          Card(
            elevation: 0,
            color: cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: borderColor, width: 1),
            ),
            child: Column(
              children: [
                for (int i = 0; i < settings.notifications.keys.length; i++) ...[
                  if (i > 0) Divider(height: 1, indent: 16, endIndent: 16, color: borderColor),
                  Builder(
                    builder: (context) {
                      final categoryKey = settings.notifications.keys.elementAt(i);
                      final isChecked = settings.notifications.values.elementAt(i);

                      return SwitchListTile(
                        activeColor: pointColor,
                        secondary: _buildIconBox(
                          _getNotificationIcon(categoryKey),
                          isActive: isChecked,
                          iconBgColor: iconBgColor,
                        ),
                        title: Text(
                          categoryKey,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        value: isChecked,
                        onChanged: (v) => settings.setNotification(categoryKey, v),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 3. 위젯 섹션
          _buildSectionHeader(context, '위젯'),
          Card(
            elevation: 0,
            color: cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: borderColor, width: 1),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: _buildIconBox(Icons.widgets_outlined, isActive: true, iconBgColor: iconBgColor),
              title: const Text('홈스크린 위젯', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              subtitle: Text(
                '검토대기 건수를 홈화면에 바로 보여줘요. 기기 홈화면에서 직접 추가할 수 있어요.',
                style: TextStyle(height: 1.4, fontSize: 13, color: isDark ? Colors.grey.shade400 : Colors.black54),
              ),
              isThreeLine: true,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // --- 도움 헬퍼 함수들 ---

  String _getThemeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return '라이트';
      case ThemeMode.dark:
        return '다크';
      case ThemeMode.system:
      default:
        return '시스템';
    }
  }

  String _getFontScaleLabel(double scale) {
    if (scale <= 0.9) return '작음';
    if (scale >= 1.15) return '크게';
    return '기본';
  }

  /// 테마 선택 바텀시트 모달
  void _showThemePicker(BuildContext context, AppSettingsController settings) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('테마 선택', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              _buildPickerTile(
                context: context,
                title: '라이트 모드',
                isSelected: settings.themeMode == ThemeMode.light,
                onTap: () {
                  settings.setThemeMode(ThemeMode.light);
                  Navigator.pop(context);
                },
              ),
              _buildPickerTile(
                context: context,
                title: '시스템 설정 적용',
                isSelected: settings.themeMode == ThemeMode.system,
                onTap: () {
                  settings.setThemeMode(ThemeMode.system);
                  Navigator.pop(context);
                },
              ),
              _buildPickerTile(
                context: context,
                title: '다크 모드',
                isSelected: settings.themeMode == ThemeMode.dark,
                onTap: () {
                  settings.setThemeMode(ThemeMode.dark);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  /// 글자 크기 선택 바텀시트 모달
  void _showFontScalePicker(BuildContext context, AppSettingsController settings) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('글자 크기 선택', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              _buildPickerTile(
                context: context,
                title: '작게 -',
                isSelected: settings.fontScale == 0.9,
                onTap: () {
                  settings.setFontScale(0.9);
                  Navigator.pop(context);
                },
              ),
              _buildPickerTile(
                context: context,
                title: '기본',
                isSelected: settings.fontScale == 1.0,
                onTap: () {
                  settings.setFontScale(1.0);
                  Navigator.pop(context);
                },
              ),
              _buildPickerTile(
                context: context,
                title: '크게 +',
                isSelected: settings.fontScale == 1.15,
                onTap: () {
                  settings.setFontScale(1.15);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  /// 바텀시트 내 목록 항목 위젯
  Widget _buildPickerTile({
    required BuildContext context,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? pointColor : null, // null 설정 시 테마 기본 글자색 사용
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check_rounded, color: pointColor) : null,
      onTap: onTap,
    );
  }

  /// 아이콘 박스
  Widget _buildIconBox(IconData icon, {bool isActive = true, required Color iconBgColor}) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isActive ? pointColor.withAlpha(20) : iconBgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon,
        size: 20,
        color: isActive ? pointColor : Colors.grey.shade500,
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