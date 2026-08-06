import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthState();
    });
  }

  Future<void> _checkAuthState() async {
    await Future<void>.delayed(const Duration(seconds: 4));

    if (!mounted) {
      return;
    }

    final authState = await ref.read(authProvider.future);
    if (!mounted) return;
    if (!authState.isLoggedIn) {
      context.go(RouteNames.login);
      return;
    }
    if (authState.isNewUser || !authState.isPhoneVerified) {
      context.go(RouteNames.phoneVerification);
      return;
    }
    final homeRoute = RouteNames.homeForRole(authState.role);
    context.go(homeRoute ?? RouteNames.login);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFF4FBFF), Color(0xFFEAF7FF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),

              FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 290,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF5AAEFF,
                          ).withValues(alpha: 0.12),
                          blurRadius: 35,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/soomit_logo2.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 34),

              const Text(
                '오늘도 편안한 호흡을 함께합니다',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF667085),
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.2,
                ),
              ),

              const Spacer(flex: 2),

              SizedBox(
                width: 56,
                height: 5,
                child: LinearProgressIndicator(
                  borderRadius: BorderRadius.circular(20),
                  backgroundColor: Color(0xFFDDEEFF),
                  color: Color(0xFF56B8FF),
                ),
              ),

              const SizedBox(height: 42),
            ],
          ),
        ),
      ),
    );
  }
}
