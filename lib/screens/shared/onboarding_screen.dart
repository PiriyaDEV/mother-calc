import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:kidtang_flutter/providers/auth_provider.dart';
import 'package:kidtang_flutter/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _displayNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _promptpayCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _loading = false;
  String? _error;
  String? _usernameError;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _usernameCtrl.dispose();
    _promptpayCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final err = await context.read<AuthProvider>().completeOnboarding(
          displayName: _displayNameCtrl.text.trim(),
          username: _usernameCtrl.text.trim(),
          promptpay: _promptpayCtrl.text.trim(),
        );
    if (mounted) {
      final isUsernameTaken = err == 'ชื่อผู้ใช้นี้ถูกใช้แล้ว';
      setState(() {
        _loading = false;
        _usernameError = isUsernameTaken ? err : null;
        _error = isUsernameTaken ? null : err;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark ? AppGradients.backgroundDark : AppGradients.backgroundLight,
        ),
        child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ยินดีต้อนรับ 👋',
                  style: GoogleFonts.notoSansThai(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ตั้งค่าโปรไฟล์ก่อนเริ่มใช้งาน',
                  style: GoogleFonts.notoSansThai(
                    fontSize: 15,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 40),

                _label(isDark, 'ชื่อที่แสดง'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _displayNameCtrl,
                  textInputAction: TextInputAction.next,
                  style: GoogleFonts.notoSansThai(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                  decoration: _inputDecoration(isDark, 'เช่น สมชาย ใจดี'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'กรุณาใส่ชื่อที่แสดง' : null,
                ),
                const SizedBox(height: 20),

                _label(isDark, 'ชื่อผู้ใช้ (@username)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _usernameCtrl,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  style: GoogleFonts.notoSansThai(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                  decoration: _inputDecoration(isDark, 'เช่น somchai99')
                      .copyWith(errorText: _usernameError),
                  onChanged: (_) {
                    if (_usernameError != null) {
                      setState(() => _usernameError = null);
                    }
                  },
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'กรุณาใส่ชื่อผู้ใช้';
                    if (!RegExp(r'^[a-zA-Z0-9_]{3,30}$').hasMatch(v.trim())) {
                      return 'ใช้ได้แค่ a-z, 0-9, _ และ 3-30 ตัวอักษร';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                _label(isDark, 'เบอร์พร้อมเพย์'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _promptpayCtrl,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  maxLength: 10,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: GoogleFonts.notoSansThai(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                  decoration: _inputDecoration(isDark, 'เช่น 0812345678'),
                  validator: (v) {
                    final digits = v?.trim() ?? '';
                    if (digits.isEmpty) return 'กรุณาใส่เบอร์พร้อมเพย์';
                    if (digits.length != 10) return 'เบอร์พร้อมเพย์ต้องมี 10 หลัก';
                    return null;
                  },
                ),

                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _error!,
                      style: GoogleFonts.notoSansThai(
                        fontSize: 13,
                        color: AppColors.red,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'เริ่มใช้งาน',
                            style: GoogleFonts.notoSansThai(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }

  Widget _label(bool isDark, String text) => Text(
        text,
        style: GoogleFonts.notoSansThai(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
      );

  InputDecoration _inputDecoration(bool isDark, String hint) => InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.notoSansThai(
          color:
              isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
        ),
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.red, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );
}
