import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

enum _LoginMode { login, register, otp }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  _LoginMode _mode = _LoginMode.login;

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _error;

  // OTP
  final List<TextEditingController> _otpCtrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocuses = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _usernameCtrl.dispose();
    for (final c in _otpCtrls) {
      c.dispose();
    }
    for (final f in _otpFocuses) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final username = _usernameCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'กรุณากรอกอีเมลและรหัสผ่าน');
      return;
    }

    if (_mode == _LoginMode.register) {
      if (username.isEmpty || username.length < 3) {
        setState(() => _error = 'Username ต้องมีอย่างน้อย 3 ตัวอักษร');
        return;
      }
      if (password != _confirmPasswordCtrl.text) {
        setState(() => _error = 'รหัสผ่านไม่ตรงกัน กรุณาตรวจสอบอีกครั้ง');
        return;
      }
      if (password.length < 6) {
        setState(() => _error = 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร');
        return;
      }
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final auth = context.read<AuthProvider>();

    if (_mode == _LoginMode.login) {
      final err = await auth.signInWithEmail(email, password);
      if (mounted) {
        setState(() {
          _loading = false;
          _error = err;
        });
      }
    } else {
      final err = await auth.signUpWithEmail(email, password, username);
      if (mounted) {
        if (err != null) {
          setState(() {
            _loading = false;
            _error = err;
          });
        } else {
          // Switch to OTP screen
          setState(() {
            _loading = false;
            _mode = _LoginMode.otp;
            for (final c in _otpCtrls) {
              c.clear();
            }
          });
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) _otpFocuses[0].requestFocus();
          });
        }
      }
    }
  }

  Future<void> _verifyOtp([String? code]) async {
    final token = code ?? _otpCtrls.map((c) => c.text).join();
    if (token.length < 6) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final auth = context.read<AuthProvider>();
    final err = await auth.verifyOTP(_emailCtrl.text.trim(), token);

    if (mounted) {
      if (err != null) {
        setState(() {
          _loading = false;
          _error = err;
          for (final c in _otpCtrls) {
            c.clear();
          }
        });
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) _otpFocuses[0].requestFocus();
        });
      } else {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = context.read<AuthProvider>();
    final err = await auth.signInWithGoogle();
    if (mounted) {
      setState(() {
        _loading = false;
        _error = err;
      });
    }
  }

  void _onOtpChanged(int index, String value) {
    final digit = value.replaceAll(RegExp(r'\D'), '');
    if (digit.isEmpty) {
      _otpCtrls[index].clear();
      return;
    }
    _otpCtrls[index].text = digit[digit.length - 1];
    _otpCtrls[index].selection = TextSelection.fromPosition(
        TextPosition(offset: _otpCtrls[index].text.length));

    if (index < 5) {
      _otpFocuses[index + 1].requestFocus();
    } else {
      // Auto-submit when last digit filled
      final code = _otpCtrls.map((c) => c.text).join();
      if (code.length == 6) _verifyOtp(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF8F9FC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              // Back button (OTP only)
              if (_mode == _LoginMode.otp)
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _mode = _LoginMode.register;
                      _error = null;
                    }),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 14,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'กลับ',
                          style: GoogleFonts.notoSansThai(
                            fontSize: 14,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (_mode == _LoginMode.otp) const SizedBox(height: 16),

              // Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color:
                        isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Column(
                  children: [
                    // Logo
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Text('🧾', style: TextStyle(fontSize: 24)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Kidtang!',
                      style: GoogleFonts.notoSansThai(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _mode == _LoginMode.login
                          ? 'เข้าสู่ระบบ'
                          : _mode == _LoginMode.register
                              ? 'สมัครสมาชิก'
                              : 'ยืนยันอีเมล',
                      style: GoogleFonts.notoSansThai(
                        fontSize: 14,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── OTP Screen ──────────────────────────
                    if (_mode == _LoginMode.otp) ...[
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.mail_outline_rounded,
                          size: 28,
                          color: Color(0xFF4366F4),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'ตรวจสอบอีเมลของคุณ',
                        style: GoogleFonts.notoSansThai(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'เราส่งรหัส 6 หลักไปที่',
                        style: GoogleFonts.notoSansThai(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _emailCtrl.text.trim(),
                        style: GoogleFonts.notoSansThai(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 6-digit OTP boxes
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(6, (i) {
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4),
                            child: SizedBox(
                              width: 44,
                              height: 52,
                              child: TextField(
                                controller: _otpCtrls[i],
                                focusNode: _otpFocuses[i],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                maxLength: 1,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                style: GoogleFonts.notoSansThai(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight,
                                ),
                                decoration: InputDecoration(
                                  counterText: '',
                                  contentPadding: EdgeInsets.zero,
                                  filled: true,
                                  fillColor: _otpCtrls[i].text.isNotEmpty
                                      ? const Color(0xFFEFF6FF)
                                      : (isDark
                                          ? AppColors.surfaceDark
                                          : const Color(0xFFF9FAFB)),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: _otpCtrls[i].text.isNotEmpty
                                          ? AppColors.primary
                                          : (isDark
                                              ? AppColors.borderDark
                                              : AppColors.borderLight),
                                      width: 2,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: isDark
                                          ? AppColors.borderDark
                                          : AppColors.borderLight,
                                      width: 2,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.primary,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                onChanged: (v) => _onOtpChanged(i, v),
                                onTap: () {
                                  _otpCtrls[i].selection =
                                      TextSelection.fromPosition(
                                    TextPosition(
                                        offset: _otpCtrls[i].text.length),
                                  );
                                },
                              ),
                            ),
                          );
                        }),
                      ),

                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        _ErrorBox(error: _error!),
                      ],

                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _loading ||
                                  _otpCtrls
                                          .map((c) => c.text)
                                          .join()
                                          .length <
                                      6
                              ? null
                              : _verifyOtp,
                          child: _loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'ยืนยันรหัส',
                                  style: GoogleFonts.notoSansThai(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'ไม่ได้รับรหัส? ',
                            style: GoogleFonts.notoSansThai(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                          GestureDetector(
                            onTap: _loading
                                ? null
                                : () => context
                                    .read<AuthProvider>()
                                    .signUpWithEmail(
                                      _emailCtrl.text.trim(),
                                      _passwordCtrl.text,
                                      _usernameCtrl.text.trim(),
                                    ),
                            child: Text(
                              'ส่งใหม่',
                              style: GoogleFonts.notoSansThai(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // ── Login / Register Screen ──────────

                      // Google sign-in button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: _loading ? null : _signInWithGoogle,
                          icon: const Text('G',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4285F4))),
                          label: Text(
                            _mode == _LoginMode.login
                                ? 'เข้าสู่ระบบด้วย Google'
                                : 'สมัครสมาชิกด้วย Google',
                            style: GoogleFonts.notoSansThai(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.borderLight,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Divider
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.borderLight,
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'หรือ',
                              style: GoogleFonts.notoSansThai(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.textTertiaryDark
                                    : AppColors.textTertiaryLight,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.borderLight,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Username (register only)
                      if (_mode == _LoginMode.register) ...[
                        _FieldLabel(label: 'Username', isDark: isDark),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _usernameCtrl,
                          autocorrect: false,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[a-z0-9_]')),
                          ],
                          decoration: const InputDecoration(
                            hintText: 'เช่น john_doe (a-z, 0-9, _)',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ใช้ตัวอักษรภาษาอังกฤษ ตัวเลข หรือ _ (3-30 ตัว)',
                          style: GoogleFonts.notoSansThai(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Email
                      _FieldLabel(label: 'อีเมล', isDark: isDark),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        decoration: const InputDecoration(
                          hintText: 'email@example.com',
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Password
                      _FieldLabel(label: 'รหัสผ่าน', isDark: isDark),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _passwordCtrl,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: 'รหัสผ่าน (อย่างน้อย 6 ตัว)',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 18,
                              color: isDark
                                  ? AppColors.textTertiaryDark
                                  : AppColors.textTertiaryLight,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        onSubmitted: _mode == _LoginMode.login
                            ? (_) => _submit()
                            : null,
                      ),

                      // Confirm password (register only)
                      if (_mode == _LoginMode.register) ...[
                        const SizedBox(height: 12),
                        _FieldLabel(label: 'ยืนยันรหัสผ่าน', isDark: isDark),
                        const SizedBox(height: 6),
                        ValueListenableBuilder(
                          valueListenable: _confirmPasswordCtrl,
                          builder: (_, __, ___) {
                            final mismatch =
                                _confirmPasswordCtrl.text.isNotEmpty &&
                                    _confirmPasswordCtrl.text !=
                                        _passwordCtrl.text;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  controller: _confirmPasswordCtrl,
                                  obscureText: _obscureConfirm,
                                  decoration: InputDecoration(
                                    hintText: 'กรอกรหัสผ่านอีกครั้ง',
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: mismatch
                                            ? AppColors.red
                                            : (isDark
                                                ? AppColors.borderDark
                                                : AppColors.borderLight),
                                      ),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirm
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        size: 18,
                                        color: isDark
                                            ? AppColors.textTertiaryDark
                                            : AppColors.textTertiaryLight,
                                      ),
                                      onPressed: () => setState(() =>
                                          _obscureConfirm = !_obscureConfirm),
                                    ),
                                  ),
                                  onSubmitted: (_) => _submit(),
                                ),
                                if (mismatch) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'รหัสผ่านไม่ตรงกัน',
                                    style: GoogleFonts.notoSansThai(
                                      fontSize: 11,
                                      color: AppColors.red,
                                    ),
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                      ],

                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        _ErrorBox(error: _error!),
                      ],

                      const SizedBox(height: 20),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          child: _loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _loading
                                      ? 'กำลังดำเนินการ...'
                                      : _mode == _LoginMode.login
                                          ? 'เข้าสู่ระบบ'
                                          : 'สมัครสมาชิก',
                                  style: GoogleFonts.notoSansThai(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Toggle mode
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _mode == _LoginMode.login
                                ? 'ยังไม่มีบัญชี? '
                                : 'มีบัญชีแล้ว? ',
                            style: GoogleFonts.notoSansThai(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() {
                              _mode = _mode == _LoginMode.login
                                  ? _LoginMode.register
                                  : _LoginMode.login;
                              _error = null;
                            }),
                            child: Text(
                              _mode == _LoginMode.login
                                  ? 'สมัครสมาชิก'
                                  : 'เข้าสู่ระบบ',
                              style: GoogleFonts.notoSansThai(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  final bool isDark;
  const _FieldLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: GoogleFonts.notoSansThai(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String error;
  const _ErrorBox({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.red.withOpacity(0.25)),
      ),
      child: Text(
        error,
        style: GoogleFonts.notoSansThai(
          fontSize: 13,
          color: AppColors.red,
        ),
      ),
    );
  }
}
