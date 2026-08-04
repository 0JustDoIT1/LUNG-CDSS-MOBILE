import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// 앱 전체 화면표시/알림 설정. 기기 로컬(SharedPreferences)에 저장.
/// TODO: 알림설정은 나중에 NotificationPreference API와도 동기화 필요.
class AppSettingsController extends ChangeNotifier {
  static const _keyKeepScreenOn = 'settings.keepScreenOn';
  static const _keyThemeMode = 'settings.themeMode'; // 0=light,1=system,2=dark
  static const _keyFontScale = 'settings.fontScale';
  static const _keyNotifPrefix = 'settings.notif.';

  bool _keepScreenOn = false;
  ThemeMode _themeMode = ThemeMode.system;
  double _fontScale = 1.0;
  final Map<String, bool> _notifications = {
    '예약': true,
    '채팅': true,
    '증상위험도(트리아지)': true,
    '케이스검토': true,
  };

  bool get keepScreenOn => _keepScreenOn;
  ThemeMode get themeMode => _themeMode;
  double get fontScale => _fontScale;
  Map<String, bool> get notifications => Map.unmodifiable(_notifications);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _keepScreenOn = prefs.getBool(_keyKeepScreenOn) ?? false;
    _themeMode = ThemeMode.values[prefs.getInt(_keyThemeMode) ?? 1];
    _fontScale = prefs.getDouble(_keyFontScale) ?? 1.0;
    for (final category in _notifications.keys) {
      final saved = prefs.getBool('$_keyNotifPrefix$category');
      if (saved != null) _notifications[category] = saved;
    }
    if (_keepScreenOn) {
      await WakelockPlus.enable();
    }
    notifyListeners();
  }

  Future<void> setKeepScreenOn(bool value) async {
    _keepScreenOn = value;
    notifyListeners();
    if (value) {
      await WakelockPlus.enable();
    } else {
      await WakelockPlus.disable();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyKeepScreenOn, value);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyThemeMode, mode.index);
  }

  Future<void> setFontScale(double scale) async {
    _fontScale = scale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyFontScale, scale);
  }

  Future<void> setNotification(String category, bool enabled) async {
    _notifications[category] = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_keyNotifPrefix$category', enabled);
    // TODO: 서버 NotificationPreference API로도 전송해야 함
  }
}