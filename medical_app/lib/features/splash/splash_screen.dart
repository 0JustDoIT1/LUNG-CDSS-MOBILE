import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';

/// 앱 켜지면 로그인 화면 전에 잠깐 뜨는 스플래시(로고) 화면.
/// TODO: 실제 연결 시 이 시간 동안 자동로그인 토큰 확인 등을 넣을 수 있음.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) context.go('/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Theme.of(context).colorScheme.surface,
          ),
          Positioned(
            top: -80,
            left: -60,
            child: _BlurBlob(color: AppTheme.gradientStart, size: 240),
          ),
          Positioned(
            bottom: -100,
            right: -80,
            child: _BlurBlob(color: AppTheme.gradientEnd, size: 280),
          ),
          Positioned(
            top: 160,
            right: -60,
            child: _BlurBlob(color: AppTheme.seed, size: 160),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/images/logo_full.png', width: 300, height: 300),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 배경에 은은하게 깔리는 흐린 그라데이션 원. (login_screen.dart와 동일한 구성)
class _BlurBlob extends StatelessWidget {
  final Color color;
  final double size;

  const _BlurBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}