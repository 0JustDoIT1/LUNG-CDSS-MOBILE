import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/session_controller.dart';
import '../../../core/constants/user_role.dart';
import '../../../core/theme/app_theme.dart';
import 'signup_screen.dart';

/// 로그인 화면.
///
/// TODO;의사는 면허번호 API 검증(건강보험심사평가원 등) 연동 필요.
/// 지금은 실제 인증 전이라, 역할 선택 카드로 임시 로그인 처리한다.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  UserRole? _selectedRole;

  @override
  Widget build(BuildContext context) {
    final session = context.read<SessionController>();

    return Scaffold(
      body: Stack(
        children: [
          Container(width: double.infinity, height: double.infinity, color: Colors.white),
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
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/images/logo_full.png', width: 220),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.seed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.seed.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        '의료진용',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.seed,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _LoginCard(
                      selectedRole: _selectedRole,
                      onSelectRole: (role) => setState(() {
                        _selectedRole = _selectedRole == role ? null : role;
                      }),
                      onSubmit: () {
                        if (_selectedRole == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('의사 또는 간호사를 선택해주세요')),
                          );
                          return;
                        }
                        session.logIn(_selectedRole!);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 배경에 은은하게 깔리는 흐린 그라데이션 원.
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

/// 로그인 유형(의사/간호사) 선택 + 로그인 버튼을 담은 카드.
class _LoginCard extends StatelessWidget {
  final UserRole? selectedRole;
  final ValueChanged<UserRole> onSelectRole;
  final VoidCallback onSubmit;

  const _LoginCard({
    required this.selectedRole,
    required this.onSelectRole,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            '로그인 유형 선택',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _RoleTile(
                  label: '의사',
                  icon: Icons.medical_services_outlined,
                  isSelected: selectedRole == UserRole.doctor,
                  onTap: () => onSelectRole(UserRole.doctor),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _RoleTile(
                  label: '간호사',
                  icon: Icons.favorite_outline,
                  isSelected: selectedRole == UserRole.nurse,
                  onTap: () => onSelectRole(UserRole.nurse),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '아이디',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            decoration: InputDecoration(
              hintText: '아이디를 입력하세요',
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppTheme.seed, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '비밀번호',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            obscureText: true,
            decoration: InputDecoration(
              hintText: '비밀번호를 입력하세요',
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppTheme.seed, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.seed.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.seed,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: onSubmit,
              child: const Text('로그인'),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SignUpScreen()),
                );
              },
              child: RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  children: [
                    const TextSpan(text: '계정이 없으신가요? '),
                    TextSpan(
                      text: '회원가입',
                      style: TextStyle(
                        color: AppTheme.seed,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleTile extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleTile({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_RoleTile> createState() => _RoleTileState();
}

class _RoleTileState extends State<_RoleTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isSelected;

    final Color bgColor = active
        ? (_isPressed ? AppTheme.seed.withValues(alpha: 0.16) : AppTheme.seed.withValues(alpha: 0.1))
        : (_isPressed ? Colors.grey.shade100 : Colors.grey.shade50);

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? AppTheme.seed : Colors.grey.shade200,
            width: active ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              widget.icon,
              size: 24,
              color: active ? AppTheme.seed : Colors.grey.shade500,
            ),
            const SizedBox(width: 12),
            Text(
              widget.label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: active ? AppTheme.seed : Colors.grey.shade700,
              ),
            ),
            const Spacer(),
            if (active) Icon(Icons.check_circle, size: 20, color: AppTheme.seed),
          ],
        ),
      ),
    );
  }
}