import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/settings/app_settings_controller.dart';

/// 앱 설정 — 화면표시(테마/화면항상켜짐/글자크기) + 알림 + 위젯 + 약관 및 정책
class NurseAppSettingsScreen extends StatelessWidget {
  const NurseAppSettingsScreen({super.key});

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
    final cardColor = theme.cardColor;
    final borderColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    final iconBgColor = isDark ? Colors.grey.shade800 : const Color(0xFFF1F5F9);

    return Scaffold(
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
          const SizedBox(height: 24),

          // 4. 약관 및 정책 섹션
          _buildSectionHeader(context, '약관 및 정책'),
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
                  leading: _buildIconBox(Icons.description_outlined, iconBgColor: iconBgColor),
                  title: const Text('서비스 이용약관', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
                  onTap: () => _showPolicyModal(context, '서비스 이용약관', _termsOfServiceContent),
                ),
                Divider(height: 1, indent: 16, endIndent: 16, color: borderColor),
                ListTile(
                  leading: _buildIconBox(Icons.privacy_tip_outlined, iconBgColor: iconBgColor),
                  title: const Text('개인정보 처리방침', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
                  onTap: () => _showPolicyModal(context, '개인정보 처리방침', _privacyPolicyContent),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
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

  /// 약관 및 정책 내용 보기 모달
  void _showPolicyModal(BuildContext context, String title, String content) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      content,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: isDark ? Colors.grey.shade300 : Colors.black87,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
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
          color: isSelected ? pointColor : null,
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

  // --- 약관 및 정책 텍스트 데이터 ---

  static const String _termsOfServiceContent = '''
제 1 조 (목적)
본 약관은 의사 전용 케이스 검토 및 모니터링 애플리케이션(이하 "서비스")이 제공하는 의료 지원 관련 제반 서비스의 이용 조건 및 절차, 이용자와 회사의 권리, 의무 및 책임사항을 규정함을 목적으로 합니다.

제 2 조 (회원의 자격 및 면허 확인)
1. 본 서비스는 대한민국 의료법에 따라 면허를 취득한 전문 의료인(의사 및 치과의사 등)에 한해 이용할 수 있습니다.
2. 회사는 회원의 자격 확인을 위해 면허번호 및 관련 증빙 서류 제출을 요구할 수 있으며, 허위 정보를 입력한 경우 서비스 이용이 즉시 정지될 수 있습니다.

제 3 조 (의료적 판단에 대한 책임의 한계)
1. 본 서비스가 제공하는 케이스 검토, 데이터 분석 및 AI 기반 보조 정보는 의료인의 진단 및 치료 결정을 보조하기 위한 참고 자료일 뿐입니다.
2. 환자에 대한 최종 진단, 처방 및 치료에 대한 책임은 전적으로 서비스를 이용하는 담당 의료인(회원)에게 있습니다. 회사는 회원의 의료적 판단 결과에 대해 법적 책임을 지지 않습니다.

제 4 조 (환자 정보 보호 및 익명화)
1. 회원은 케이스 등록 시 환자의 개인식별정보(성명, 주민등록번호, 상세 주소 등)가 포함되지 않도록 완벽히 익명화(De-identification)하여 업로드하여야 합니다.
2. 회원이 관련 법령(개인정보 보호법, 의료법 등)을 위반하여 환자 정보를 식별 가능한 상태로 유출한 경우, 그에 따른 모든 법적 책임은 회원 본인에게 있습니다.

제 5 조 (서비스의 변경 및 중지)
회사는 시스템 점검, 교체 또는 천재지변 등 불가피한 사유가 발생한 경우 서비스의 제공을 일시적으로 중단할 수 있습니다.
''';

  static const String _privacyPolicyContent = '''
1. 수집하는 개인정보 항목
회사는 전문 의료인 회원가입 및 서비스 제공을 위해 아래와 같은 개인정보를 수집하고 있습니다.
- 필수항목: 성명, 이메일 주소, 비밀번호, 소속 병원/기관명, 진료 과목, 의사 면허 번호
- 서비스 이용 과정에서 생성되는 정보: 접속 로그, IP 주소, 쿠키, 서비스 이용 기록, 기기 식별 정보

2. 개인정보의 수집 및 이용 목적
수집된 개인정보는 다음의 목적을 위해 활용됩니다.
- 회원 자격 확인: 의사 면허 유효성 확인 및 보건의료인 자격 검증
- 서비스 제공: 의료 케이스 검토, 데이터 연동, 알림 서비스 제공
- 서비스 개선: 신규 기능 개발 및 이용 형태 분석을 통한 서비스 고도화

3. 환자 데이터 처리 및 비식별화
본 서비스에 등록되는 케이스 및 의료 영상 데이터는 개인정보 보호법 및 의료법에 따라 개인을 식별할 수 없도록 철저히 비식별 조치되어 처리됩니다. 회사는 식별 가능한 환자 데이터를 서버에 저장하지 않습니다.

4. 개인정보의 보유 및 이용 기간
원칙적으로 개인정보 수집 및 이용 목적이 달성된 후에는 해당 정보를 지체 없이 파기합니다. 단, 관계 법령의 규정에 의하여 보존할 필요가 있는 경우 법령에서 정한 일정 기간 동안 회원 정보를 보관합니다.
- 회원 탈퇴 시: 지체 없이 파기 (단, 법령 위반 조사를 위한 보관 필요 시 최대 30일)

5. 개인정보의 제3자 제공
회사는 이용자의 동의 없이 개인정보를 외부에 제공하지 않습니다. 단, 법령의 규정에 의거하거나 수사 목적으로 법령에 정해진 절차와 방법에 따라 수사기관의 요구가 있는 경우는 예외로 합니다.
''';
}