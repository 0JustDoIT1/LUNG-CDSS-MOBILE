import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/auth_api.dart';
import '../../../core/auth/session_controller.dart';
import '../../../core/constants/user_role.dart';
import '../../../core/theme/app_theme.dart';

/// 회원가입 화면 — 실제 API(POST /api/auth/staff/signup/) 연동됨.
/// - 역할 선택: 의사 → 공통정보+면허번호 인라인 인증 / 간호사 → 공통정보만
/// - 병원은 GET /api/auth/hospital/에서 자동으로 가져옴 (지금은 1곳뿐)
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

  String? _doctorDept;
  String? _nurseDept;

  Hospital? _hospital;
  bool _hospitalLoading = true;

  _LicenseStatus _licenseStatus = _LicenseStatus.none;
  String? _errorMessage;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() => setState(() {}));
    _passwordConfirmController.addListener(() => setState(() {}));
    _loadHospital();
  }

  Future<void> _loadHospital() async {
    try {
      final hospital = await fetchHospital();
      if (!mounted) return;
      setState(() {
        _hospital = hospital;
        _hospitalLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _hospitalLoading = false;
        _errorMessage = e.message;
      });
    }
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

    // TODO: 건강보험심사평가원 실제 검증 API 연동 전 임시 형식체크(6자리 숫자).
    // 서버도 license_number는 "형식체크만, 실제 발급기관 검증 미연동" 상태.
    await Future.delayed(const Duration(milliseconds: 500));
    final isValid = RegExp(r'^\d{6}$').hasMatch(_licenseController.text.trim());

    if (!mounted) return;
    setState(() => _licenseStatus = isValid ? _LicenseStatus.success : _LicenseStatus.failed);
  }

  Future<void> _submit() async {
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
    if (!_passwordValid) {
      setState(() => _errorMessage = '비밀번호는 8~16자, 영문·숫자·특수문자를 모두 포함해야 합니다');
      return;
    }
    if (!_passwordConfirmMatches) {
      setState(() => _errorMessage = '비밀번호가 일치하지 않습니다');
      return;
    }
    if (_hospital == null) {
      setState(() => _errorMessage = '병원 정보를 불러오지 못했어요. 다시 시도해주세요');
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

    setState(() => _isSubmitting = true);

    try {
      final result = await staffSignup(
        role: _role == UserRole.doctor ? 'doctor' : 'nurse',
        name: _nameController.text.trim(),
        email: _fullEmail,
        phoneNumber: _phoneController.text.trim(),
        password: _passwordController.text,
        passwordConfirm: _passwordConfirmController.text,
        hospitalId: _hospital!.id,
        department: _role == UserRole.doctor ? _doctorDept! : _nurseDept!,
        licenseNumber: _role == UserRole.doctor ? _licenseController.text.trim() : null,
      );

      if (!mounted) return;
      context.read<SessionController>().applyLoginResult(result);
      // 성공 시 SessionController가 notifyListeners() → go_router가 자동으로
      // /doctor 또는 /nurse로 이동시켜줌.
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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
              iconBuilder: (r) =>
                  r == UserRole.doctor ? Icons.medical_services_outlined : Icons.favorite_outline,
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: _hospitalLoading
                  ? Row(
                      children: [
                        const SizedBox(
                          width: 14, height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 8),
                        Text('불러오는 중...', style: TextStyle(color: Colors.grey.shade500)),
                      ],
                    )
                  : Text(_hospital?.name ?? '병원 정보를 불러오지 못했어요'),
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
                              width: 16, height: 16,
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
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('가입 완료'),
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
  final IconData Function(T)? iconBuilder;
  final ValueChanged<T?> onChanged;

  const _Dropdown({
    required this.value,
    required this.hintText,
    required this.items,
    required this.labelBuilder,
    this.iconBuilder,
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
          .map((item) => DropdownMenuEntry(
                value: item,
                label: labelBuilder(item),
                leadingIcon: iconBuilder == null
                    ? null
                    : Icon(iconBuilder!(item), size: 20, color: AppTheme.seed),
                labelWidget: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Text(labelBuilder(item)),
                ),
              ))
          .toList(),
      onSelected: onChanged,
    );
  }
}