import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/session_controller.dart';
import '../../../core/constants/user_role.dart';
import '../../../core/theme/app_theme.dart';
import '../mock/registered_emails_mock.dart';

/// 회원가입 화면 — 단일 폼으로 통합.
/// - 역할 선택(드롭다운): 의사 → 공통정보+면허번호 인라인 인증 / 간호사 → 공통정보만
/// - 의사면허번호 인증은 같은 폼 안에서 인라인으로 처리 (별도 화면 아님)
///
/// TODO: 실제 연결 시 mock 로직(이메일 중복확인, 면허번호 검증)을 실제 API로 교체.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

enum _LicenseStatus { none, loading, success, failed }

final _passwordRule =
    RegExp(r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>_\-]).{8,16}$');

class _SignUpScreenState extends State<SignUpScreen> {
  UserRole? _role;

  final _nameController = TextEditingController();
  final _emailIdController = TextEditingController();
  final _customDomainController = TextEditingController();
  String? _selectedDomain;

  static const _domainOptions = ['naver.com', 'gmail.com', 'hospital.com', '직접 입력'];
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  final _licenseController = TextEditingController();

  String? _hospital;
  String? _doctorDept;
  String? _nurseDept;

  _LicenseStatus _licenseStatus = _LicenseStatus.none;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() => setState(() {}));
    _passwordConfirmController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailIdController.dispose();
    _customDomainController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _licenseController.dispose();
    super.dispose();
  }

  bool get _passwordValid => _passwordRule.hasMatch(_passwordController.text);
  bool get _passwordConfirmMatches =>
      _passwordConfirmController.text.isNotEmpty &&
      _passwordConfirmController.text == _passwordController.text;

  String get _domain =>
      _selectedDomain == '직접 입력' ? _customDomainController.text.trim() : (_selectedDomain ?? '');

  String get _fullEmail => '${_emailIdController.text.trim()}@$_domain';

  Future<void> _verifyLicense() async {
    if (_licenseController.text.trim().isEmpty) return;

    setState(() => _licenseStatus = _LicenseStatus.loading);

    // mock: 건강보험심사평가원 API 호출 대신 1초 지연 후 6자리 숫자면 성공 처리
    await Future.delayed(const Duration(seconds: 1));
    final isValid = RegExp(r'^\d{6}$').hasMatch(_licenseController.text.trim());

    if (!mounted) return;
    setState(() => _licenseStatus = isValid ? _LicenseStatus.success : _LicenseStatus.failed);
  }

  void _submit() {
    setState(() => _errorMessage = null);

    if (_role == null) {
      setState(() => _errorMessage = '역할을 선택해주세요');
      return;
    }

    if (_nameController.text.trim().isEmpty ||
        _emailIdController.text.trim().isEmpty ||
        _domain.isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      setState(() => _errorMessage = '모든 항목을 입력해주세요');
      return;
    }

    if (mockRegisteredEmails().contains(_fullEmail)) {
      setState(() => _errorMessage = '이미 등록된 이메일입니다');
      return;
    }

    if (!_passwordValid) {
      setState(() => _errorMessage = '비밀번호는 8~16자, 영문·숫자·특수문자를 모두 포함해야 합니다');
      return;
    }

    if (!_passwordConfirmMatches) {
      setState(() => _errorMessage = '비밀번호가 일치하지 않습니다');
      return;
    }

    if (_hospital == null) {
      setState(() => _errorMessage = '소속 병원을 선택해주세요');
      return;
    }

    if (_role == UserRole.doctor && _doctorDept == null) {
      setState(() => _errorMessage = '진료과를 선택해주세요');
      return;
    }

    if (_role == UserRole.nurse && _nurseDept == null) {
      setState(() => _errorMessage = '부서를 선택해주세요');
      return;
    }

    if (_role == UserRole.doctor && _licenseStatus != _LicenseStatus.success) {
      setState(() => _errorMessage = '의사면허번호 인증을 완료해주세요');
      return;
    }

    // TODO: 회원가입 API 연결. 지금은 임시로 바로 로그인 처리.
    final session = context.read<SessionController>();
    session.logInMock(_role!);
  }

  @override
  Widget build(BuildContext context) {
    final title = _role == null
        ? '회원가입'
        : '회원가입 · ${_role == UserRole.doctor ? '의사' : '간호사'}';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _FieldLabel('역할'),
            const SizedBox(height: 6),
            _Dropdown<UserRole>(
              value: _role,
              hintText: '역할을 선택하세요.',
              items: const [UserRole.doctor, UserRole.nurse],
              labelBuilder: (r) => r == UserRole.doctor ? '의사' : '간호사',
              onChanged: (r) => setState(() {
                _role = r;
                _licenseStatus = _LicenseStatus.none;
                _doctorDept = null;
                _nurseDept = null;
              }),
            ),
            const SizedBox(height: 16),
            _FieldLabel('이름'),
            const SizedBox(height: 6),
            _TextInput(controller: _nameController, hint: '홍길동'),
            const SizedBox(height: 16),
            _FieldLabel('이메일'),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 4,
                  child: _TextInput(controller: _emailIdController, hint: '아이디'),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('@', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  flex: 5,
                  child: _Dropdown<String>(
                    value: _selectedDomain,
                    hintText: '선택',
                    items: _domainOptions,
                    labelBuilder: (v) => v,
                    onChanged: (v) => setState(() => _selectedDomain = v),
                  ),
                ),
              ],
            ),
            if (_selectedDomain == '직접 입력') ...[
              const SizedBox(height: 8),
              _TextInput(controller: _customDomainController, hint: '도메인을 입력하세요 (예: mydomain.com)'),
            ],
            const SizedBox(height: 16),
            _FieldLabel('휴대폰 번호'),
            const SizedBox(height: 6),
            _TextInput(controller: _phoneController, hint: '010-0000-0000'),
            const SizedBox(height: 16),
            _FieldLabel('비밀번호'),
            const SizedBox(height: 6),
            _TextInput(controller: _passwordController, hint: '8~16자, 영문·숫자·특수문자 포함', obscure: true),
            const SizedBox(height: 6),
            if (_passwordController.text.isNotEmpty)
              Row(
                children: [
                  Icon(
                    _passwordValid ? Icons.check_circle : Icons.info_outline,
                    size: 14,
                    color: _passwordValid ? Colors.green.shade600 : Colors.orange.shade700,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _passwordValid ? '사용 가능한 비밀번호예요' : '8~16자, 영문·숫자·특수문자를 모두 포함해야 해요',
                    style: TextStyle(
                      fontSize: 12,
                      color: _passwordValid ? Colors.green.shade600 : Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            _FieldLabel('비밀번호 재입력'),
            const SizedBox(height: 6),
            _TextInput(controller: _passwordConfirmController, hint: '비밀번호를 다시 입력하세요', obscure: true),
            const SizedBox(height: 6),
            if (_passwordConfirmController.text.isNotEmpty)
              Row(
                children: [
                  Icon(
                    _passwordConfirmMatches ? Icons.check_circle : Icons.cancel,
                    size: 14,
                    color: _passwordConfirmMatches ? Colors.green.shade600 : Colors.red.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _passwordConfirmMatches ? '비밀번호가 일치해요' : '비밀번호가 일치하지 않아요',
                    style: TextStyle(
                      fontSize: 12,
                      color: _passwordConfirmMatches ? Colors.green.shade600 : Colors.red.shade600,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            _FieldLabel('소속 병원'),
            const SizedBox(height: 6),
            _Dropdown<String>(
              value: _hospital,
              hintText: '병원을 선택하세요.',
              items: const ['OO대학병원'],
              labelBuilder: (v) => v,
              onChanged: (v) => setState(() => _hospital = v),
            ),
            if (_role != null) ...[
              const SizedBox(height: 16),
              _FieldLabel(_role == UserRole.doctor ? '진료과' : '부서'),
              const SizedBox(height: 6),
              if (_role == UserRole.doctor)
                _Dropdown<String>(
                  value: _doctorDept,
                  hintText: '진료과를 선택하세요.',
                  items: const ['호흡기내과'],
                  labelBuilder: (v) => v,
                  onChanged: (v) => setState(() => _doctorDept = v),
                )
              else
                _Dropdown<String>(
                  value: _nurseDept,
                  hintText: '부서를 선택하세요.',
                  items: const ['호흡기내과 병동'],
                  labelBuilder: (v) => v,
                  onChanged: (v) => setState(() => _nurseDept = v),
                ),
            ],
            if (_role == UserRole.doctor) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              _FieldLabel('의사면허번호'),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _TextInput(
                      controller: _licenseController,
                      hint: '123456',
                      onChanged: (_) {
                        if (_licenseStatus != _LicenseStatus.none) {
                          setState(() => _licenseStatus = _LicenseStatus.none);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _licenseStatus == _LicenseStatus.loading ? null : _verifyLicense,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.seed,
                        side: BorderSide(color: AppTheme.seed),
                      ),
                      child: _licenseStatus == _LicenseStatus.loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('인증하기'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_licenseStatus == _LicenseStatus.loading)
                Text('확인 중입니다', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              if (_licenseStatus == _LicenseStatus.success)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 16, color: Colors.green.shade700),
                      const SizedBox(width: 6),
                      Text(
                        '면허번호가 확인되었습니다',
                        style: TextStyle(fontSize: 12, color: Colors.green.shade700, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              if (_licenseStatus == _LicenseStatus.failed)
                Text(
                  '입력하신 면허번호를 확인할 수 없습니다, 다시 확인해주세요',
                  style: TextStyle(fontSize: 12, color: Colors.red.shade600),
                ),
            ],
            const SizedBox(height: 20),
            if (_errorMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                ),
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.seed,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _submit,
                child: const Text('가입 완료'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: TextStyle(fontSize: 13, color: Colors.grey.shade800, fontWeight: FontWeight.w600));
  }
}

class _TextInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final ValueChanged<String>? onChanged;

  const _TextInput({
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  final T? value;
  final String hintText;
  final List<T> items;
  final String Function(T) labelBuilder;
  final ValueChanged<T?> onChanged;

  const _Dropdown({
    required this.value,
    required this.hintText,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownMenu<T>(
      initialSelection: value,
      hintText: hintText,
      expandedInsets: EdgeInsets.zero,
      textStyle: const TextStyle(fontSize: 14),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      ),
      dropdownMenuEntries: items
          .map((item) => DropdownMenuEntry(value: item, label: labelBuilder(item)))
          .toList(),
      onSelected: onChanged,
    );
  }
}