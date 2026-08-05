import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../api/auth_api.dart';

/// 앱 전체 화면표시/알림 설정.
/// 화면표시(테마/화면항상켜짐/글자크기)는 기기 로컬(SharedPreferences)에만 저장.
/// 알림설정은 실제 서버(NotificationPreference API)와 동기화됨.
class AppSettingsController extends ChangeNotifier {
  static const _keyKeepScreenOn = 'settings.keepScreenOn';
  static const _keyThemeMode = 'settings.themeMode'; // 0=light,1=system,2=dark
  static const _keyFontScale = 'settings.fontScale';
  static const _keyNotifPrefix = 'settings.notif.';

  // 화면에 보여줄 한글 라벨 ↔ 서버 category 코드 매핑.
  static const _categoryServerKey = {
    '복약': 'medication',
    '예약': 'appointment',
    '채팅': 'chat',
    '증상위험도(트리아지)': 'triage',
    '케이스검토': 'case_review',
  };

  bool _keepScreenOn = false;
  ThemeMode _themeMode = ThemeMode.system;
  double _fontScale = 1.0;
  final Map<String, bool> _notifications = {
    '복약': true,
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

  /// 서버에 저장된 알림설정으로 덮어쓰기(로컬보다 서버가 최신 기준).
  Future<void> syncNotificationsFromServer(String accessToken) async {
    try {
      final serverPrefs = await fetchNotificationPreferences(accessToken);
      final serverToLabel = _categoryServerKey.map((k, v) => MapEntry(v, k));

      for (final pref in serverPrefs) {
        final label = serverToLabel[pref.category];
        if (label != null) _notifications[label] = pref.enabled;
      }

      final prefs = await SharedPreferences.getInstance();
      for (final entry in _notifications.entries) {
        await prefs.setBool('$_keyNotifPrefix${entry.key}', entry.value);
      }
      notifyListeners();
    } on ApiException catch (_) {
      // 서버 동기화 실패해도 로컬값으로 계속 쓸 수 있게 조용히 무시
    }
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

  /// accessToken을 넘기면 로컬저장과 함께 서버에도 반영됨.
  Future<void> setNotification(String category, bool enabled, {String? accessToken}) async {
    _notifications[category] = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_keyNotifPrefix$category', enabled);

    final serverKey = _categoryServerKey[category];
    if (accessToken != null && serverKey != null) {
      try {
        await updateNotificationPreference(
          accessToken: accessToken,
          category: serverKey,
          enabled: enabled,
        );
      } on ApiException catch (_) {
        // 서버 저장 실패해도 로컬엔 이미 반영됐으니 조용히 무시 (다음 동기화때 재시도됨)
      }
    }
  }
}