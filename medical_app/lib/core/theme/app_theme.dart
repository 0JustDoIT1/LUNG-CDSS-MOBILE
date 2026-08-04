import 'package:flutter/material.dart';

/// 라이트/다크모드 — 시스템설정 연동 또는 앱 내 수동전환(설정화면에서 선택) 대응.
///
/// '숨-잇(Soom-it)' 로고의 청록→블루 그라데이션 톤에 맞춰 시드컬러 설정.
class AppTheme {
  AppTheme._();

  // 로고의 청록-블루 그라데이션 중간톤
  static const Color seed = Color(0xFF2AA8B0);
  static const Color gradientStart = Color(0xFF2EC4B6); // 청록
  static const Color gradientEnd = Color(0xFF3A86FF); // 블루

  static const LinearGradient brandGradient = LinearGradient(
    colors: [gradientStart, gradientEnd],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFF7FBFB),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: gradientStart.withValues(alpha: 0.15),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: gradientEnd);
        }
        return IconThemeData(color: Colors.grey.shade500);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: gradientEnd,
          );
        }
        return TextStyle(fontSize: 12, color: Colors.grey.shade500);
      }),
    ),
  );

  static ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    ),
  );
}